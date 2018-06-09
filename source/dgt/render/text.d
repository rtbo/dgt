module dgt.render.text;

import dgt.render.renderer : FGNodeRenderer;
import gfx.core.rc : AtomicRefCounted, Disposable;


final class TextRenderer : FGNodeRenderer
{
    import dgt.render.atlas :       GlyphAtlas;
    import dgt.render.framegraph :  FGNode, FGType;
    import dgt.render.renderer :    RenderContext;
    import dgt.render.services :    RenderServices;
    import dgt.text.layout :        TextShape;
    import gfx.core.rc :            Rc;
    import gfx.decl.engine :        DeclarativeEngine;
    import gfx.graal.buffer :       Buffer;
    import gfx.graal.cmd :          CommandBuffer;
    import gfx.graal.device :       Device;
    import gfx.graal.image :        ImageView, Sampler;
    import gfx.graal.pipeline :     DescriptorPool, DescriptorSet,
                                    DescriptorSetLayout, Pipeline, PipelineLayout;
    import gfx.math :               FMat4, FVec4;
    import gfx.memalloc :           Allocator, BufferAlloc;


    private Rc!Device device;
    private Rc!Allocator allocator;
    private Rc!RenderServices services;

    private Rc!DescriptorSetLayout unifDsl;
    private Rc!DescriptorSetLayout imgDsl;
    private Rc!DescriptorPool dsPool;
    // index zero is uniform, follows one ds per atlas
    private DescriptorSet[] dss;

    private Rc!PipelineLayout layout;
    private Rc!Pipeline pipeline;

    private Rc!Sampler sampler;
    private Rc!BufferAlloc uniformBuf;
    private Rc!BufferAlloc indexBuf;
    private Rc!BufferAlloc vertexBuf;
    private AtlasTexture[] atlases;

    private BoundResources boundRes;
    private GlyphRun[size_t] glyphRuns;

    private size_t nodeCount;
    private size_t glyphCount;
    private size_t mvpLen;
    private size_t colLen;

    private static struct MVP {
        FMat4 model;
        FMat4 viewProj;
    }
    private static struct Col {
        FVec4 color;
        FVec4 pad;
    }
    private static struct BoundResources
    {
        Buffer uniform;
        ImageView view;
    }

    this()
    {
    }

    override void dispose()
    {
        import std.algorithm : each;
        uniformBuf.unload();
        vertexBuf.unload();
        indexBuf.unload();
        sampler.unload();
        atlases.each!(a => a.release());
        atlases = null;
        unifDsl.unload();
        imgDsl.unload();
        dsPool.unload();
        services.unload();
        allocator.unload();
        layout.unload();
        pipeline.unload();
        device.unload();
    }

    override FGType type() const
    {
        import dgt.render.framegraph : FGRenderType, FGTypeCat;

        return FGType(FGTypeCat.render, FGRenderType.text);
    }

    override void prepare(RenderServices services, DeclarativeEngine declEng, CommandBuffer cmd)
    {
        import gfx.graal.buffer : BufferUsage;
        import gfx.graal.image : SamplerInfo;
        import gfx.memalloc : AllocOptions, MemoryUsage;

        this.device = services.device;
        this.allocator = services.allocator;
        this.services = services;

        declEng.addView!"text.vert.spv"();
        declEng.addView!"text.frag.spv"();
        declEng.parseSDLView!"text_pipeline.sdl"();

        auto store = declEng.store;

        this.pipeline = store.expect!Pipeline("text_pl");
        this.layout = store.expect!PipelineLayout("text_layout");
        this.unifDsl = store.expect!DescriptorSetLayout("text_dsl_unif");
        this.imgDsl = store.expect!DescriptorSetLayout("text_dsl_img");
        this.sampler = device.createSampler(SamplerInfo.nearest);

        this.indexBuf = allocator.allocateBuffer(
            BufferUsage.index, 6*ushort.sizeof,
            AllocOptions.forUsage(MemoryUsage.gpuOnly)
        );
        const ushort[6] indices = [ 0, 1, 2, 0, 2, 3 ];
        this.services.stageDataToBuffer(cmd, this.indexBuf, 0, cast(const(void)[])indices[]);
    }

    override void prerender(immutable(FGNode) node)
    {
        import dgt.render.framegraph : FGTextNode;
        import dgt.render.defs : P2T2Vertex;

        immutable tn = cast(immutable(FGTextNode))node;

        foreach (s; tn.shapes) {
            feedGlyphRun(s);
            glyphCount += s.glyphs.length;
        }

        nodeCount++;
    }

    override void prerenderEnd(CommandBuffer cmd)
    {
        import dgt.render.defs : P2T2Vertex;
        import gfx.graal.buffer : BufferUsage;
        import gfx.memalloc : AllocOptions, MemoryUsage;
        import std.algorithm : each;

        const vertexSize = glyphCount * 4 * P2T2Vertex.sizeof;

        if (!vertexBuf || vertexBuf.size != vertexSize) {
            if (vertexBuf) services.gc(vertexBuf);
            vertexBuf = allocator.allocateBuffer(
                BufferUsage.vertex, vertexSize,
                AllocOptions.forUsage(MemoryUsage.cpuToGpu)
            );
        }


        bool updateUnifDesc;
        bool updateAtlasDescs;

        mvpLen = nodeCount * MVP.sizeof;
        colLen = nodeCount * Col.sizeof;

        const uniformSize = mvpLen + colLen;

        if (!uniformBuf || uniformBuf.size != uniformSize) {
            if (uniformBuf) services.gc(uniformBuf);
            uniformBuf = allocator.allocateBuffer(
                BufferUsage.uniform, uniformSize,
                AllocOptions.forUsage(MemoryUsage.cpuToGpu)
            );
            updateUnifDesc = true;
        }

        if (dss.length != atlases.length+1) {
            allocDescriptorSets();
        }

        atlases.each!((ref AtlasTexture atlas) {
            if (atlas.realize(services, cmd)) {
                updateAtlasDescs = true;
            }
        });

        updateDescriptorSets(updateUnifDesc, updateAtlasDescs);

        uniformBuf.retainMap();
        vertexBuf.retainMap();

        glyphCount = 0;
        nodeCount = 0;
    }

    private void allocDescriptorSets()
    {
        import gfx.graal.pipeline : DescriptorPoolSize, DescriptorType;
        import std.array : array;
        import std.range : chain, only, repeat;

        if (dsPool) {
            // previously recorded commands may still use it
            services.gc(dsPool.obj);
            dsPool.unload();
            dss = null;
        }

        // we have 2 sets to bind:
        // - uniform set: always the same with one buffer with 2 dynamic offsets
        // - image set: one per atlas

        const numAtlases = cast(uint)atlases.length;

        DescriptorPoolSize[2] dsPoolSizes = [
            DescriptorPoolSize(DescriptorType.uniformBufferDynamic, 2),
            DescriptorPoolSize(DescriptorType.combinedImageSampler, numAtlases)
        ];

        this.dsPool = device.createDescriptorPool( numAtlases+1, dsPoolSizes[] );

        auto dsls = only(unifDsl.obj).chain(repeat(imgDsl.obj, numAtlases)).array();

        this.dss = this.dsPool.allocate(dsls);
    }

    private void updateDescriptorSets(in bool updateUnif, in bool updateAtlas)
    {
        import gfx.graal.image : ImageLayout;
        import gfx.graal.pipeline : BufferRange, CombinedImageSampler,
                                    CombinedImageSamplerDescWrites,
                                    UniformBufferDynamicDescWrites,
                                    WriteDescriptorSet;

        WriteDescriptorSet[] writes;

        if (updateUnif)
        {
            writes = [
                WriteDescriptorSet(dss[0], 0, 0, new UniformBufferDynamicDescWrites([
                    BufferRange(uniformBuf.buffer, 0, MVP.sizeof),
                ])),
                WriteDescriptorSet(dss[0], 1, 0, new UniformBufferDynamicDescWrites([
                    BufferRange(uniformBuf.buffer, MVP.sizeof * nodeCount, Col.sizeof),
                ])),
            ];
        }
        if (updateAtlas)
        {
            assert(dss.length == atlases.length+1);

            writes.reserve(atlases.length);

            foreach (i; 0 .. atlases.length) {
                writes ~= WriteDescriptorSet(dss[i+1], 0, 0, new CombinedImageSamplerDescWrites([
                    CombinedImageSampler(sampler, atlases[i].view, ImageLayout.shaderReadOnlyOptimal)
                ]));
            }
        }

        if (writes.length)
            device.updateDescriptorSets(writes, []);
    }

    override void render(immutable(FGNode) node, RenderContext ctx, in FMat4 model, CommandBuffer cmd)
    {
        import dgt.core.geometry : FRect, FSize;
        import dgt.render.defs : P2T2Vertex;
        import dgt.render.framegraph : FGTextNode;
        import gfx.graal.buffer : IndexType;
        import gfx.graal.cmd : PipelineBindPoint, VertexBinding;
        import gfx.math : fvec, FVec2, transpose;

        immutable tn = cast(immutable(FGTextNode))node;

        {
            auto unifMap = uniformBuf.map();
            {
                auto mvp = unifMap.view!(MVP[])(0, mvpLen/MVP.sizeof);
                mvp[nodeCount] = MVP(
                    transpose(model), transpose(ctx.viewProj)
                );
            }
            {
                auto col = unifMap.view!(Col[])(mvpLen);
                col[nodeCount] = Col(tn.color);
            }
        }

        cmd.bindPipeline(pipeline.obj);
        cmd.bindDescriptorSets(
            PipelineBindPoint.graphics, layout, 0, dss[0 .. 1], [
                nodeCount * MVP.sizeof, nodeCount * Col.sizeof
            ]
        );
        cmd.bindIndexBuffer(indexBuf.buffer, 0, IndexType.u16);

        size_t boundAtlas = size_t.max;

        auto vertMap = vertexBuf.map();
        auto verts = vertMap.view!(P2T2Vertex[])();

        const bearing = tn.bearing;

        foreach (shape; tn.shapes) {

            auto gr = glyphRuns[shape.id];

            foreach (p; gr.parts) {

                const textureSize = cast(FVec2)p.atlas.textureSize;
                const ind = p.atlasInd;

                if (ind != boundAtlas) {
                    cmd.bindDescriptorSets(
                        PipelineBindPoint.graphics, layout, 1, dss[ind+1 .. ind+2], null
                    );
                    boundAtlas = ind;
                }

                foreach (gl; p.glyphs) {

                    auto an = gl.node;

                    // texel space rect
                    const fSize = FSize(an.size.x, an.size.y);
                    const txRect = FRect(cast(FVec2)an.origin, fSize);

                    // normalized rect
                    immutable normRect = FRect(
                        txRect.topLeft / textureSize,
                        FSize(txRect.width / textureSize.x, txRect.height / textureSize.y)
                    );
                    immutable vertRect = FRect(
                        gl.position, txRect.size
                    );
                    verts[4*glyphCount .. 4*glyphCount+4] = [
                        P2T2Vertex(
                            fvec(vertRect.left+bearing.x, vertRect.top+bearing.y),
                            fvec(normRect.left, normRect.top)
                        ),
                        P2T2Vertex(
                            fvec(vertRect.left+bearing.x, vertRect.bottom+bearing.y),
                            fvec(normRect.left, normRect.bottom)
                        ),
                        P2T2Vertex(
                            fvec(vertRect.right+bearing.x, vertRect.bottom+bearing.y),
                            fvec(normRect.right, normRect.bottom)
                        ),
                        P2T2Vertex(
                            fvec(vertRect.right+bearing.x, vertRect.top+bearing.y),
                            fvec(normRect.right, normRect.top)
                        ),
                    ];

                    cmd.bindVertexBuffers(0, [ VertexBinding (
                        vertexBuf.buffer, 4*glyphCount*P2T2Vertex.sizeof
                    )]);
                    cmd.drawIndexed(6, 1, 0, 0, 0);

                    glyphCount++;
                }
            }
        }

        nodeCount++;
    }

    override void postrender()
    {
        glyphCount = 0;
        nodeCount = 0;
        uniformBuf.releaseMap();
        vertexBuf.releaseMap();
    }

    private void feedGlyphRun(in TextShape shape)
    {
        import dgt.core.sync : synchronize;
        import dgt.font.library : FontLibrary;
        import dgt.font.typeface : Glyph, ScalingContext, Typeface;
        import dgt.render.atlas : AtlasNode;
        import dgt.text.shaping : GlyphInfo;
        import gfx.core.rc : rc;
        import gfx.math : fvec, ivec;

        if (shape.id in glyphRuns) return;

        GlyphRun.Part[] parts;
        auto advance = fvec(0, 0);

        auto tf = FontLibrary.get.getById(shape.fontId);
        assert(tf);
        tf.synchronize!((Typeface tf) {
            ScalingContext sc = tf.getScalingContext(shape.size).rc;
            foreach (const GlyphInfo gi; shape.glyphs) {
                import std.algorithm : find;
                import std.exception : enforce;
                Glyph glyph = sc.renderGlyph(gi.index);
                if (!glyph) continue;
                if (glyph.isWhitespace) {
                    advance += gi.advance;
                    continue;
                }

                const metrics = glyph.metrics;
                const position = gi.offset + advance +
                        fvec(metrics.horBearing.x, -metrics.horBearing.y);

                advance += gi.advance;

                AtlasNode node = cast(AtlasNode)glyph.rendererData;

                if (!node) {
                    // this glyph is not yet in an atlas, let's pack it
                    const size = glyph.img.size.asVec;
                    auto atlasF = atlases.find!(a => a.atlas.couldPack(size));
                    if (atlasF.length) {
                        node = atlasF[0].atlas.pack(size, glyph);
                    }
                    if (!node) {
                        // could not find an atlas with room left, or did not create atlas at all yet
                        auto atlas = new GlyphAtlas(ivec(128, 128), ivec(512, 512), 1);
                        atlases ~= AtlasTexture(atlas);
                        node = enforce(atlas.pack(size, glyph),
                                "could not pack a glyph into a new atlas. What size is this glyph??");
                    }
                    glyph.rendererData = node;
                }

                auto atlas = node.atlas;

                auto grg = GRGlyph(position, node);

                if (!parts.length || parts[$-1].atlas !is atlas) {
                    size_t ind = size_t.max;
                    foreach (i, at; atlases) {
                        if (at.atlas is atlas) {
                            ind = i;
                            break;
                        }
                    }
                    assert(ind != size_t.max);
                    parts ~= GlyphRun.Part(ind, atlas, [ grg ]);
                }
                else {
                    parts[$-1].glyphs ~= grg;
                }

            }
        });

        if (parts.length) {
            auto run = new GlyphRun;
            run.parts = parts;
            glyphRuns[shape.id] = run;
        }
    }

}


private:

struct GRGlyph
{
    import dgt.render.atlas : AtlasNode;
    import gfx.math : FVec2;

    FVec2 position;
    AtlasNode node;
}


// TODO: make this a struct
class GlyphRun
{
    import dgt.render.atlas : AtlasNode, GlyphAtlas;

    // most runs will have a single part, but if there are a lot of glyphs with
    // big size, it can happen that we come to an atlas boundary and then the
    // end of the run arrives on a second atlas
    struct Part {
        size_t atlasInd;
        GlyphAtlas atlas;
        GRGlyph[] glyphs;  // ordered array - each node map to a glyph
    }

    Part[] parts;
}

struct AtlasTexture
{
    import dgt.render.atlas : GlyphAtlas;
    import dgt.render.services : RenderServices;
    import gfx.graal.cmd : CommandBuffer;
    import gfx.graal.device : Device;
    import gfx.graal.image : Image, ImageView;
    import gfx.memalloc : ImageAlloc, Allocator;

    GlyphAtlas atlas;
    ImageAlloc imgAlloc;
    ImageView view;

    void release()
    {
        import gfx.core.rc : releaseObj;

        releaseObj(this.imgAlloc);
        releaseObj(this.view);
    }

    /// Returns: whether the image was renewed or not
    bool realize(RenderServices services, CommandBuffer cmd)
    {
        // rebuild and upload texture
        import dgt.render.services : setImageLayout;
        import gfx.core.rc :         rc, retainObj;
        import gfx.graal.cmd :       BufferImageCopy;
        import gfx.graal.format :    Format;
        import gfx.graal.image :     ImageAspect, ImageInfo, ImageLayout,
                                     ImageTiling, ImageSubresourceRange,
                                     ImageType, ImageUsage, Swizzle;
        import gfx.graal.memory :    MemoryRequirements, MemProps;
        import gfx.memalloc :        AllocFlags, AllocOptions, MemoryUsage;
        import std.format :          format;
        import std.exception :       enforce;

        if (atlas.realize()) {

            release();

            const sz = atlas.image.size;

            auto imgAlloc = services.allocator.allocateImage
            (
                ImageInfo.d2(sz.width, sz.height)
                    .withFormat(Format.r8_uNorm)
                    .withUsage(ImageUsage.sampled | ImageUsage.transferDst)
                    .withTiling(ImageTiling.optimal),

                AllocOptions.forUsage(MemoryUsage.gpuOnly)
                    .withFlags(AllocFlags.dedicated)
            );

            services.stageDataToImage(
                cmd, imgAlloc.image, ImageAspect.color, ImageLayout.undefined, atlas.image.data
            );

            this.imgAlloc = retainObj(imgAlloc);
            this.view = retainObj(imgAlloc.image.createView(
                ImageType.d2, ImageSubresourceRange(ImageAspect.color),
                Swizzle.identity
            ));

            return true;
        }
        else {
            return false;
        }
    }
}
