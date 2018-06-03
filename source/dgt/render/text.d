module dgt.render.text;

import dgt.render.renderer : FGNodeRenderer;
import gfx.core.rc : AtomicRefCounted, Disposable;


final class TextRenderer : FGNodeRenderer
{
    import dgt.render.atlas : GlyphAtlas;
    import dgt.render.framegraph : FGNode, FGType;
    import dgt.render.renderer : PrepareContext, PrerenderContext, RenderContext;
    import dgt.render.services : RenderServices;
    import dgt.text.layout : TextShape;
    import gfx.core.rc : Rc;
    import gfx.decl.store : DeclarativeStore;
    import gfx.graal.cmd : CommandBuffer;
    import gfx.graal.device : Device;
    import gfx.graal.image : Sampler;
    import gfx.graal.pipeline : DescriptorPool, DescriptorSet,
                                DescriptorSetLayout, Pipeline, PipelineLayout;
    import gfx.math : FMat4, FVec4;
    import gfx.memalloc : Allocator, BufferAlloc;

    private Rc!Device device;
    private Rc!Allocator allocator;
    private Rc!Pipeline pipeline;
    private Rc!PipelineLayout layout;
    private Rc!DescriptorSetLayout dsl;
    private Rc!Sampler sampler;
    private Rc!BufferAlloc uniformBuf;
    private Rc!BufferAlloc indexBuf;
    private Rc!BufferAlloc vertexBuf;
    private DescriptorSet ds;
    private AtlasTexture[] atlases;
    private GlyphRun[size_t] glyphRuns;
    private RenderServices services;

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
        dsl.unload();
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

    override void prepare(Device device, DeclarativeStore store,
                          Allocator allocator, RenderServices services,
                          PrepareContext ctx)
    {
        import gfx.graal.buffer : BufferUsage;
        import gfx.graal.image : SamplerInfo;
        import gfx.graal.pipeline : DescriptorType;
        import gfx.memalloc : AllocOptions, MemoryUsage;

        this.device = device;
        this.allocator = allocator;
        this.services = services;
        this.pipeline = store.expect!Pipeline("text_pl");
        this.layout = store.expect!PipelineLayout("text_layout");
        this.dsl = store.expect!DescriptorSetLayout("text_dsl");
        this.sampler = device.createSampler(SamplerInfo.nearest);

        this.indexBuf = allocator.allocateBuffer(
            BufferUsage.index, 6*ushort.sizeof,
            AllocOptions.forUsage(MemoryUsage.cpuToGpu)
        );
        {
            auto map = indexBuf.map();
            auto view = map.view!(ushort[])();
            view[] = [ 0, 1, 2, 0, 2, 3 ];
        }

        ctx.setCount += 1;
        ctx.descriptorCounts[DescriptorType.uniformBufferDynamic] += 2;
        ctx.descriptorCounts[DescriptorType.combinedImageSampler] += 1;
    }

    override void initDescriptors(DescriptorPool pool)
    {
        ds = pool.allocate([dsl.obj])[0];
    }

    override void prerender(immutable(FGNode) node, PrerenderContext context)
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

    override void prerenderEnd(PrerenderContext ctx, CommandBuffer cmd)
    {
        import dgt.render.defs : P2T2Vertex;
        import gfx.graal.buffer : BufferUsage;
        import gfx.graal.image : ImageLayout;
        import gfx.graal.pipeline : BufferRange, CombinedImageSampler,
                                    CombinedImageSamplerDescWrites,
                                    UniformBufferDynamicDescWrites,
                                    WriteDescriptorSet;
        import gfx.memalloc : AllocOptions, MemoryUsage;
        import std.algorithm : each;

        atlases.each!((ref AtlasTexture atlas) {
            atlas.realize(device, allocator, services, cmd);
        });

        mvpLen = nodeCount * MVP.sizeof;
        colLen = nodeCount * Col.sizeof;

        const uniformSize = mvpLen + colLen;
        const vertexSize = glyphCount * 4 * P2T2Vertex.sizeof;

        bool writeDesc;

        if (!uniformBuf || uniformBuf.size != uniformSize) {
            if (uniformBuf) {
                services.gc(uniformBuf);
            }
            uniformBuf = allocator.allocateBuffer(
                BufferUsage.uniform, uniformSize,
                AllocOptions.forUsage(MemoryUsage.cpuToGpu)
            );
            writeDesc = true;
        }
        if (!vertexBuf || vertexBuf.size != vertexSize) {
            if (vertexBuf) {
                services.gc(vertexBuf);
            }
            vertexBuf = allocator.allocateBuffer(
                BufferUsage.vertex, vertexSize,
                AllocOptions.forUsage(MemoryUsage.cpuToGpu)
            );
            writeDesc = true;
        }

        if (writeDesc) {
            // TODO handle more atlases, requires one descriptor set per atlas
            assert(atlases.length == 1);
            auto writes = [
                WriteDescriptorSet(ds, 0, 0, new UniformBufferDynamicDescWrites([
                    BufferRange(uniformBuf.buffer, 0, MVP.sizeof),
                ])),
                WriteDescriptorSet(ds, 1, 0, new UniformBufferDynamicDescWrites([
                    BufferRange(uniformBuf.buffer, MVP.sizeof * nodeCount, Col.sizeof),
                ])),
                WriteDescriptorSet(ds, 2, 0, new CombinedImageSamplerDescWrites([
                    CombinedImageSampler(sampler, atlases[0].view, ImageLayout.shaderReadOnlyOptimal)
                ]))
            ];
            device.updateDescriptorSets(writes, []);
        }

        uniformBuf.retainMap();
        vertexBuf.retainMap();

        glyphCount = 0;
        nodeCount = 0;
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
            PipelineBindPoint.graphics, layout, 0, [ ds ], [
                nodeCount * MVP.sizeof, nodeCount * Col.sizeof
            ]
        );
        cmd.bindIndexBuffer(indexBuf.buffer, 0, IndexType.u16);

        auto vertMap = vertexBuf.map();
        auto verts = vertMap.view!(P2T2Vertex[])();

        const bearing = tn.bearing;

        foreach (shape; tn.shapes) {

            auto gr = glyphRuns[shape.id];

            foreach (p; gr.parts) {

                const textureSize = cast(FVec2)p.atlas.textureSize;

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
                    parts ~= GlyphRun.Part(atlas, [ grg ]);
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
        GlyphAtlas atlas;
        GRGlyph[] glyphs;  // ordered array - each node map to a glyph
    }

    Part[] parts;
}

struct AtlasTexture
{
    import dgt.render.atlas : GlyphAtlas;
    import dgt.render.services : RenderServices;
    import dgt.render.renderer : PrerenderContext;
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

    void realize(Device device, Allocator allocator, RenderServices services, CommandBuffer cmd)
    {
        // rebuild and upload texture
        import gfx.core.rc :        rc, retainObj;
        import gfx.core.typecons :  trans;
        import gfx.graal.cmd :      Access, BufferImageCopy, ImageMemoryBarrier,
                                    PipelineStage, queueFamilyIgnored;
        import gfx.graal.format :   Format;
        import gfx.graal.image :    ImageAspect, ImageInfo, ImageLayout,
                                    ImageSubresourceRange, ImageTiling,
                                    ImageType, ImageUsage, Swizzle;
        import gfx.graal.memory :   MemoryRequirements, MemProps;
        import gfx.memalloc :       AllocFlags, AllocOptions, MemoryUsage;
        import std.format :         format;
        import std.exception :      enforce;

        if (atlas.realize()) {

            release();

            const sz = atlas.image.size;

            auto imgAlloc = allocator.allocateImage
            (
                ImageInfo.d2(sz.width, sz.height)
                    .withFormat(Format.r8_uNorm)
                    .withUsage(ImageUsage.sampled | ImageUsage.transferDst)
                    .withTiling(ImageTiling.optimal),

                AllocOptions.forUsage(MemoryUsage.gpuOnly)
                    .withFlags(AllocFlags.dedicated)
            );
            cmd.pipelineBarrier(
                trans(PipelineStage.topOfPipe, PipelineStage.transfer), [], [
                    ImageMemoryBarrier(
                        trans(Access.none, Access.transferWrite),
                        trans(ImageLayout.undefined, ImageLayout.transferDstOptimal),
                        trans(queueFamilyIgnored, queueFamilyIgnored),
                        imgAlloc.image, ImageSubresourceRange(ImageAspect.color)
                    )
                ]
            );
            {
                import gfx.graal.buffer : BufferUsage;
                auto stagBuf = allocator.allocateBuffer(
                    BufferUsage.transferSrc, atlas.image.data.length,
                    AllocOptions.forUsage(MemoryUsage.cpuToGpu)
                ).rc;
                {
                    auto map = stagBuf.map();
                    auto view = map.view!(ubyte[])();
                    view[] = atlas.image.data;
                }
                BufferImageCopy region;
                region.extent = [sz.width, sz.height, 1];
                const regions = (&region)[0 .. 1];
                cmd.copyBufferToImage(
                    stagBuf.buffer, imgAlloc.image, ImageLayout.transferDstOptimal,
                    regions
                );
                services.gc(stagBuf.obj);
            }

            auto view = imgAlloc.image.createView(
                ImageType.d2, ImageSubresourceRange(ImageAspect.color),
                Swizzle.identity
            );

            this.imgAlloc = retainObj(imgAlloc);
            this.view = retainObj(view);
        }
    }
}
