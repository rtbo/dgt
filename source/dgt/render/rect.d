/// Rect rendering module.
/// Renders rounded rectangle with:
///  - stroke color
///  - fill (color, linear gradiant or image)
///  - rounded corners
///
/// Corners are rounded using signed distance field. Technique is explained here:
/// https://mortoray.com/2015/06/05/quickly-drawing-a-rounded-rectangle-with-a-gl-shader/
module dgt.render.rect;

import dgt.render : dgtRenderTag;
import dgt.render.framegraph : FGRectNode;
import dgt.render.renderer : FGNodeRenderer;
import gfx.core.rc : Disposable;
import gfx.math : FMat4, FVec2, FVec3, FVec4;

class RectRenderer : FGNodeRenderer
{
    import dgt.render.framegraph : FGNode, FGType;
    import dgt.render.renderer : RenderContext;
    import dgt.render.services : RenderServices;
    import gfx.core.rc : Rc;
    import gfx.core.typecons : Interval;
    import gfx.decl.engine : DeclarativeEngine;
    import gfx.graal.cmd : CommandBuffer;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : DescriptorPool, Pipeline;
    import gfx.math : FMat4;
    import gfx.memalloc : Allocator, BufferAlloc;

    RectColRenderer rectCol;
    RectImgRenderer rectImg;

    Rc!RenderServices services;

    Rc!BufferAlloc indexBuf;

    this()
    {
        rectCol = new RectColRenderer;
        rectImg = new RectImgRenderer;
    }

    override void dispose()
    {
        import gfx.core.rc : disposeObj;

        disposeObj(rectCol);
        disposeObj(rectImg);
        indexBuf.unload();
        services.unload();
    }

    override FGType type() const
    {
        import dgt.render.framegraph : FGRenderType, FGTypeCat;

        return FGType(FGTypeCat.render, FGRenderType.rect);
    }

    override void prepare(RenderServices services, DeclarativeEngine declEng, CommandBuffer cmd)
    {
        import gfx.core.typecons : interval;
        import gfx.graal.buffer : BufferUsage;
        import gfx.memalloc : AllocOptions, MemoryUsage;
        import std.array : join;
        import std.range : only;

        this.services = services;

        declEng.addView!"rectcol.vert.spv"();
        declEng.addView!"rectcol.frag.spv"();
        declEng.addView!"rectimg.vert.spv"();
        declEng.addView!"rectimg.frag.spv"();
        declEng.declareStruct!RectColVertex();
        declEng.declareStruct!RectImgVertex();

        const sdl = only(
            import("rectcol_pipeline.sdl"), import("rectimg_pipeline.sdl"),
        ).join("\n");

        declEng.parseSDLSource(sdl);

        const sharpInds = sharpIndices();
        const roundedInds = roundedIndices();
        const inds = sharpInds ~ roundedInds;
        const sharpIndsInterval = interval(0, sharpInds.length);
        const roundedIndsInterval = interval(sharpInds.length, inds.length);
        indexBuf = services.allocator.allocateBuffer(
            BufferUsage.index, inds.length*ushort.sizeof, AllocOptions.forUsage(
                MemoryUsage.gpuOnly
            )
        );
        services.stageDataToBuffer(cmd, indexBuf, 0, cast(const(void)[])inds);

        rectCol.prepare(services, declEng, IndexBuffer(indexBuf.buffer, sharpIndsInterval, roundedIndsInterval));
        rectImg.prepare(services, declEng, IndexBuffer(indexBuf.buffer, sharpIndsInterval, roundedIndsInterval));
    }

    override void prerender(immutable(FGNode) node)
    {
        import dgt.core.paint : PaintType;
        import dgt.render.defs : MVP;

        immutable rn = cast(immutable(FGRectNode))node;
        const pt = rn.paint.type;

        assert(pt == PaintType.color || pt == PaintType.linearGradient ||
            pt == PaintType.image, "not all paints supported yet");

        if (pt == PaintType.color || pt == PaintType.linearGradient) {
            rectCol.prerender(rn);
        }
        else if (pt == PaintType.image) {
            rectImg.prerender(rn);
        }
    }

    override void prerenderEnd(CommandBuffer cmd)
    {
        rectCol.prerenderEnd();
        rectImg.prerenderEnd(cmd);
    }

    override void render(immutable(FGNode) node, RenderContext ctx, in FMat4 model, CommandBuffer cmd)
    {
        import dgt.core.paint : PaintType;

        immutable rn = cast(immutable(FGRectNode))node;
        const pt = rn.paint.type;

        if (pt == PaintType.color || pt == PaintType.linearGradient) {
            rectCol.render(rn, ctx, model, cmd);
        }
        else if (pt == PaintType.image) {
            rectImg.render(rn, ctx, model, cmd);
        }

    }

    override void postrender()
    {
        rectCol.postrender();
        rectImg.postrender();
    }
}

private:

struct IndexBuffer
{
    import gfx.core.typecons : Interval;
    import gfx.graal.buffer : Buffer;

    Buffer buf;
    Interval!size_t sharp;
    Interval!size_t rounded;
}

struct RectColVertex
{
    FVec3 position;
    FVec3 edge;

    this(in FVec2 pos, in FVec3 edge)
    {
        import gfx.math : fvec;

        this.position = fvec(pos, 0);
        this.edge = edge.array;
    }

    @property FVec2 vpos() const {
        return position.xy;
    }
    @property float gpos() {
        return position.z;
    }
    @property void gpos(in float gpos) {
        position.z = gpos;
    }
}

struct RectImgVertex
{
    FVec2 position;
    FVec2 texCoord;
    FVec3 edge;

    this(in FVec2 position, in FVec3 edge)
    {
        this.position = position;
        this.edge = edge;
    }
}

struct MVP {
    FMat4 model;
    FMat4 viewProj;
}

enum maxColStops = 8;

struct ColStop
{
    FVec4 color;
    float position;
    float[3] padding;
}

struct ColRectLocals
{
    FVec4 strokeCol;
    float strokeWidth;
    int numStops;
    int[2] padding;
    // each rect uniform section will be allocated the maxColStops stops
    // because descriptor range cannot be bigger than actual buffer size
    // this consumes a lot of memory (up to 224 bytes wasted per rect)
    // a better solution is to be found
    ColStop[maxColStops] stops;
}

struct ImgRectLocals
{
    FVec4 strokeCol;
    float strokeWidth;
    int[3] padding;
}

static assert(ColStop.sizeof == 8*float.sizeof);
static assert(ColRectLocals.sizeof == 8*float.sizeof + maxColStops*ColStop.sizeof);
static assert(ImgRectLocals.sizeof == 8*float.sizeof);

class RectRendererBase : Disposable
{
    import dgt.render.framegraph : FGRectNode;
    import dgt.render.renderer : RenderContext;
    import dgt.render.services : RenderServices;
    import gfx.core.rc : Rc;
    import gfx.decl.engine : DeclarativeEngine;
    import gfx.graal.buffer : Buffer;
    import gfx.graal.device : Device;
    import gfx.math.mat : FMat4;
    import gfx.memalloc : Allocator;

    Rc!Device device;
    Rc!Allocator allocator;
    Rc!RenderServices services;
    IndexBuffer indexBuf;

    void prepare (RenderServices services, DeclarativeEngine declEng, IndexBuffer indexBuf)
    {
        import gfx.core.rc : retainObj;

        this.services = services;
        this.device = services.device;
        this.allocator = services.allocator;
        this.indexBuf = indexBuf;
        retainObj(this.indexBuf.buf);
    }

    override void dispose()
    {
        import gfx.core.rc : releaseObj;

        releaseObj(this.indexBuf.buf);
        services.unload();
        allocator.unload();
        device.unload();
    }
}


final class RectColRenderer : RectRendererBase
{
    import dgt.render.framegraph : FGRectNode;
    import dgt.render.services : CircularDescriptorPool, CircularDescriptorSet, RenderServices;
    import gfx.core.rc : Rc;
    import gfx.decl.engine : DeclarativeEngine;
    import gfx.graal.buffer : Buffer;
    import gfx.graal.cmd : CommandBuffer;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : DescriptorPool, DescriptorSet, DescriptorSetLayout, Pipeline, PipelineLayout;
    import gfx.memalloc : BufferAlloc;

    Rc!BufferAlloc uniformBuf;
    Rc!BufferAlloc vertexBuf;

    Rc!DescriptorSetLayout dsl;
    Rc!CircularDescriptorPool dsPool;
    CircularDescriptorSet ds;

    Rc!PipelineLayout layout;
    Rc!Pipeline pipeline;

    size_t mvpLen;
    size_t mvpCursor;
    size_t colStopsCursor;
    size_t vertexCursor;

    override void dispose()
    {
        uniformBuf.unload();
        vertexBuf.unload();
        dsl.unload();
        dsPool.unload();
        layout.unload();
        pipeline.unload();
        super.dispose();
    }

    override void prepare (RenderServices services, DeclarativeEngine declEng, IndexBuffer indexBuf)
    {
        import gfx.graal.pipeline : DescriptorPoolSize, DescriptorType;

        super.prepare(services, declEng, indexBuf);

        this.dsl = declEng.store.expect!DescriptorSetLayout("rectcol_dsl");
        layout = declEng.store.expect!PipelineLayout("rectcol_layout");
        pipeline = declEng.store.expect!Pipeline("rectcol_pl");

        DescriptorPoolSize[1] dps = [ DescriptorPoolSize(DescriptorType.uniformBufferDynamic, 2) ];
        DescriptorSetLayout[1] dsl = [ this.dsl.obj ];

        dsPool = new CircularDescriptorPool(device, 1, dps[]);
        ds = dsPool.allocate(dsl[])[0];
    }

    void prerender(immutable(FGRectNode) rn)
    {
        import dgt.core.paint : LinearGradientPaint, PaintType;

        const pt = rn.paint.type;

        mvpCursor += MVP.sizeof;

        colStopsCursor += ColRectLocals.sizeof;
        // if (pt == PaintType.color) {
        //     colStopsCursor += ColStop.sizeof;
        // }
        // else if (pt == PaintType.linearGradient) {
        //     immutable lgp = cast(immutable(LinearGradientPaint))rn.paint;
        //     colStopsCursor += lgp.stops.length * ColStop.sizeof;
        // }

        vertexCursor += rn.radius > 0f ?
                40 * RectColVertex.sizeof :
                16 * RectColVertex.sizeof;
    }

    void prerenderEnd()
    {
        import dgt.render.services : mustReallocBuffer;
        import gfx.graal.buffer : BufferUsage;
        import gfx.memalloc : AllocFlags, AllocOptions, MemoryUsage;

        bool updateUnifDesc;

        const unifSize = mvpCursor + colStopsCursor;

        uniformBuf = services.reallocIfNeeded(
            uniformBuf, unifSize,
            sz => services.allocator.allocateBuffer(BufferUsage.uniform, sz, AllocOptions.forUsage(
                MemoryUsage.cpuToGpu
            )),
            updateUnifDesc
        );


        bool _;
        vertexBuf = services.reallocIfNeeded(
            vertexBuf, vertexCursor,
            sz => services.allocator.allocateBuffer(
                BufferUsage.vertex, vertexCursor, AllocOptions.forUsage(
                    MemoryUsage.cpuToGpu
                )
            ),
            _
        );

        if (updateUnifDesc) {
            updateDescriptorSet();
        }

        if (uniformBuf) uniformBuf.retainMap();
        if (vertexBuf) vertexBuf.retainMap();

        mvpLen = mvpCursor;
        mvpCursor = 0;
        colStopsCursor = 0;
        vertexCursor = 0;
    }

    void updateDescriptorSet()
    {
        import gfx.graal.pipeline : BufferRange,
                                    UniformBufferDynamicDescWrites,
                                    WriteDescriptorSet;

        this.ds.prepareUpdate();
        auto ds = this.ds.get;

        WriteDescriptorSet[2] wds;
        wds[0] = WriteDescriptorSet(ds, 0, 0, new UniformBufferDynamicDescWrites(
            [ BufferRange(uniformBuf.buffer, 0, MVP.sizeof) ]
        ));
        wds[1] = WriteDescriptorSet(ds, 1, 0, new UniformBufferDynamicDescWrites(
            [ BufferRange(uniformBuf.buffer, mvpCursor, ColRectLocals.sizeof) ]
        ));
        device.updateDescriptorSets(wds[], []);
    }

    void render(immutable(FGRectNode) node, RenderContext ctx, in FMat4 model, CommandBuffer cmd)
    {
        import dgt.core.paint : ColorPaint, LinearGradientPaint, PaintType;
        import dgt.render.framegraph : RectBorder;
        import gfx.core.typecons : ifSome, ifNone;
        import gfx.graal.buffer : IndexType;
        import gfx.graal.cmd : PipelineBindPoint, VertexBinding;
        import gfx.math : fvec, transpose;
        import std.algorithm : map;
        import std.array : array;
        import std.range : take;

        const pt = node.paint.type;

        ColRectLocals crl = void;
        node.border
            .ifSome!((RectBorder b) {
                crl.strokeCol = b.color;
                crl.strokeWidth = b.width;
            })
            .ifNone!({
                crl.strokeCol = fvec(0, 0, 0, 0);
                crl.strokeWidth = 0;
            });

        if (!node.paint) {
            crl.numStops = 1;
            crl.stops[0] = ColStop(fvec(0, 0, 0, 0), 0f);
        }
        else {
            switch (node.paint.type) {
            case PaintType.color:
                immutable cp = cast(immutable(ColorPaint))node.paint;
                crl.numStops = 1;
                crl.stops[0] = ColStop(cp.color.asVec, 0f);
                break;
            case PaintType.linearGradient:
                import std.algorithm : min;
                enum maxStops = 8;
                immutable lgp = cast(immutable(LinearGradientPaint))node.paint;
                crl.numStops = min(lgp.stops.length, maxStops);
                crl.stops[0 .. crl.numStops] = lgp.stops
                            .take(maxStops)
                            .map!(s => ColStop(s.color.asVec, s.position))
                            .array;
                break;
            default:
                assert(false);
            }
        }

        {
            auto unifMap = uniformBuf.map();
            {
                auto view = unifMap.view!(MVP[])(mvpCursor, 1);
                view[0] = MVP(
                    transpose(model), transpose(ctx.viewProj)
                );
            }
            {
                auto view = unifMap.view!(ColRectLocals[])(mvpLen+colStopsCursor, 1);
                view[0] = crl;
            }
        }

        size_t numVerts;
        {
            auto vertMap = vertexBuf.map();
            auto verts = vertMap.view!(RectColVertex[])(vertexCursor);

            numVerts = buildVertices(node, verts[]);
            setGPos(node, verts[0 .. numVerts]);
        }

        cmd.bindPipeline(pipeline.obj);

        DescriptorSet[1] ds = [ this.ds.get ];
        size_t[2] dynOffsets = [ mvpCursor, colStopsCursor ];
        VertexBinding[1] vb = [ VertexBinding(vertexBuf.buffer, vertexCursor) ];
        const indInterval = node.radius > 0 ? indexBuf.rounded : indexBuf.sharp;

        cmd.bindDescriptorSets(PipelineBindPoint.graphics, layout.obj, 0, ds[], dynOffsets[]);
        cmd.bindVertexBuffers(0, vb[]);
        cmd.bindIndexBuffer(indexBuf.buf, indInterval.start*ushort.sizeof, IndexType.u16);
        cmd.drawIndexed(cast(uint)indInterval.length, 1, 0, 0, 0);

        mvpCursor += MVP.sizeof;
        colStopsCursor += ColRectLocals.sizeof;
        vertexCursor += numVerts * RectColVertex.sizeof;
    }

    void postrender()
    {
        mvpCursor = 0;
        colStopsCursor = 0;
        vertexCursor = 0;
        if (uniformBuf) uniformBuf.releaseMap();
        if (vertexBuf) vertexBuf.releaseMap();
    }
}

final class RectImgRenderer : RectRendererBase
{
    import dgt.render.atlas : Atlas, AtlasNode;
    import dgt.render.framegraph : CacheCookie;
    import dgt.render.services : CircularDescriptorPool, CircularDescriptorSet, RenderServices;
    import gfx.core.rc : Rc;
    import gfx.decl.store : DeclarativeStore;
    import gfx.graal.cmd : CommandBuffer;
    import gfx.graal.device : Device;
    import gfx.graal.image : Sampler;
    import gfx.graal.pipeline : DescriptorSetLayout, Pipeline, PipelineLayout;
    import gfx.memalloc : BufferAlloc;

    Rc!BufferAlloc uniformBuf;
    Rc!BufferAlloc vertexBuf;

    Rc!DescriptorSetLayout dsl;
    Rc!CircularDescriptorPool dsPool;
    CircularDescriptorSet[] dss;

    Rc!Sampler sampler;
    Rc!PipelineLayout layout;
    Rc!Pipeline argbPremultPipeline;
    Rc!Pipeline argbPipeline;
    Rc!Pipeline xrgbPipeline;
    Atlas[] atlases;
    AtlasNode[CacheCookie] imgNodes;

    size_t mvpLen;
    size_t mvpCursor;
    size_t localsCursor;
    size_t vertexCursor;

    override void dispose()
    {
        import gfx.core.rc : releaseArr;

        uniformBuf.unload();
        vertexBuf.unload();
        sampler.unload();
        releaseArr(atlases);
        dsl.unload();
        dsPool.unload();
        layout.unload();
        argbPremultPipeline.unload();
        argbPipeline.unload();
        xrgbPipeline.unload();
        super.dispose();
    }

    override void prepare (RenderServices services, DeclarativeEngine declEng, IndexBuffer indexBuf)
    {
        import gfx.core.typecons : trans;
        import gfx.graal.image : SamplerInfo;
        import gfx.graal.pipeline : BlendFactor, BlendOp, BlendState, ColorBlendAttachment, PipelineInfo;

        super.prepare(services, declEng, indexBuf);

        this.dsl = declEng.store.expect!DescriptorSetLayout("rectimg_dsl");
        layout = declEng.store.expect!PipelineLayout("rectimg_layout");

        PipelineInfo[3] plInfos = void;
        plInfos[0] = declEng.store.expect!PipelineInfo("rectimg_plinfo_premult");
        plInfos[1] = plInfos[0];
        plInfos[1].blendInfo.attachments[0] = ColorBlendAttachment.blend(
            BlendState(trans(BlendFactor.srcAlpha, BlendFactor.oneMinusSrcAlpha), BlendOp.add)
        );
        plInfos[2] = plInfos[0];
        plInfos[2].blendInfo.attachments[0] = ColorBlendAttachment.solid();

        auto pipelines = device.createPipelines(plInfos[]);
        argbPremultPipeline = pipelines[0];
        argbPipeline = pipelines[1];
        xrgbPipeline = pipelines[2];

        sampler = device.createSampler(SamplerInfo.nearest);
    }

    void prerender(immutable(FGRectNode) rn)
    {
        mvpCursor += MVP.sizeof;
        localsCursor += ImgRectLocals.sizeof;

        vertexCursor += rn.radius > 0f ?
                40 * RectImgVertex.sizeof :
                16 * RectImgVertex.sizeof;

        feedAtlas(rn);
    }

    void prerenderEnd(CommandBuffer cmd)
    {
        import dgt.render.services : mustReallocBuffer;
        import gfx.graal.buffer : BufferUsage;
        import gfx.memalloc : AllocFlags, AllocOptions, MemoryUsage;
        import std.algorithm : each;

        bool updateUnifDesc;
        bool updateAtlasDesc;

        const unifSize = mvpCursor + localsCursor;

        uniformBuf = services.reallocIfNeeded(
            uniformBuf, unifSize,
            sz => services.allocator.allocateBuffer(BufferUsage.uniform, sz, AllocOptions.forUsage(
                MemoryUsage.cpuToGpu
            )),
            updateUnifDesc
        );


        bool _;
        vertexBuf = services.reallocIfNeeded(
            vertexBuf, vertexCursor,
            sz => services.allocator.allocateBuffer(
                BufferUsage.vertex, vertexCursor, AllocOptions.forUsage(
                    MemoryUsage.cpuToGpu
                )
            ),
            _
        );

        if (atlases.length != dss.length) {
            allocateDescriptorPool();
            updateUnifDesc = true;
            updateAtlasDesc = true;
        }

        atlases.each!((Atlas atlas) {
            if (atlas.realize(services, cmd)) {
                updateAtlasDesc = true;
            }
        });

        updateDescriptorSets(updateUnifDesc, updateAtlasDesc);

        if (uniformBuf) uniformBuf.retainMap();
        if (vertexBuf) vertexBuf.retainMap();

        mvpLen = mvpCursor;
        mvpCursor = 0;
        localsCursor = 0;
        vertexCursor = 0;
    }

    void allocateDescriptorPool()
    {
        import gfx.graal.pipeline : DescriptorPoolSize, DescriptorType;
        if (dsPool) {
            services.gc(dsPool.obj);
            dsPool.unload();
        }

        const numAtlases = cast(uint)atlases.length;

        DescriptorPoolSize[2] dps = [
            DescriptorPoolSize(DescriptorType.uniformBufferDynamic, 2*numAtlases),
            DescriptorPoolSize(DescriptorType.combinedImageSampler, 1*numAtlases),
        ];
        DescriptorSetLayout[1] dsl = [ this.dsl.obj ];

        dsPool = new CircularDescriptorPool(device, 1, dps[]);
        dss = dsPool.allocate(dsl[]);
    }

    void updateDescriptorSets(in bool updateUnif, in bool updateAtlas)
    {
        import gfx.graal.image : ImageLayout;
        import gfx.graal.pipeline : BufferRange, CombinedImageSampler,
                                    CombinedImageSamplerDescWrites,
                                    UniformBufferDynamicDescWrites,
                                    WriteDescriptorSet;

        assert(dss.length == atlases.length);

        WriteDescriptorSet[] writes;

        size_t reserve;
        if (updateUnif) reserve += 2*dss.length;
        if (updateAtlas) reserve += dss.length;

        writes.reserve(reserve);

        if (updateUnif)
        {
            foreach (ref ds; dss) {
                ds.prepareUpdate();
                writes ~= [
                    WriteDescriptorSet(ds.get, 0, 0, new UniformBufferDynamicDescWrites([
                        BufferRange(uniformBuf.buffer, 0, MVP.sizeof),
                    ])),
                    WriteDescriptorSet(ds.get, 1, 0, new UniformBufferDynamicDescWrites([
                        BufferRange(uniformBuf.buffer, mvpLen, ImgRectLocals.sizeof),
                    ])),
                ];
            }
        }
        if (updateAtlas)
        {
            foreach (i, ref ds; dss) {
                if (!updateUnif) ds.prepareUpdate();
                writes ~= WriteDescriptorSet(ds.get, 2, 0, new CombinedImageSamplerDescWrites([
                    CombinedImageSampler(sampler, atlases[i].imgView, ImageLayout.shaderReadOnlyOptimal)
                ]));
            }
        }

        if (writes.length)
            device.updateDescriptorSets(writes, []);
    }

    void render(immutable(FGRectNode) node, RenderContext ctx, in FMat4 model, CommandBuffer cmd)
    {
        import dgt.core.image : ImageFormat;
        import dgt.render.framegraph : RectBorder;
        import gfx.core.typecons : ifNone, ifSome;
        import gfx.graal.buffer : IndexType;
        import gfx.graal.cmd : PipelineBindPoint, VertexBinding;
        import gfx.graal.pipeline : DescriptorSet;
        import gfx.math : fvec, transpose;

        auto atlasNode = imgNodes[node.cookie];
        auto atlas = atlasNode.atlas;

        ImgRectLocals irl = void;
        node.border
            .ifSome!((RectBorder b) {
                irl.strokeCol = b.color;
                irl.strokeWidth = b.width;
            })
            .ifNone!({
                irl.strokeCol = fvec(0, 0, 0, 0);
                irl.strokeWidth = 0;
            });

        {
            auto unifMap = uniformBuf.map();
            {
                auto view = unifMap.view!(MVP[])(mvpCursor, 1);
                view[0] = MVP(
                    transpose(model), transpose(ctx.viewProj)
                );
            }
            {
                auto view = unifMap.view!(ImgRectLocals[])(mvpLen+localsCursor, 1);
                view[0] = irl;
            }
        }

        size_t numVerts;
        {
            auto vertMap = vertexBuf.map();
            auto verts = vertMap.view!(RectImgVertex[])(vertexCursor);

            numVerts = buildVertices(node, verts[]);
            const info = CoordInfo(node.rect, atlasNode.rect, atlas.binSize);
            setTexCoords(info, verts[0 .. numVerts]);
        }

        Pipeline pl;
        switch (atlas.format) {
            case ImageFormat.xrgb:          pl = xrgbPipeline.obj; break;
            case ImageFormat.argb:          pl = argbPipeline.obj; break;
            case ImageFormat.argbPremult:   pl = argbPremultPipeline.obj; break;
            default: assert(false);
        }

        cmd.bindPipeline(pl);

        DescriptorSet[1] ds = [ this.dss[atlasNode.atlasInd].get ];
        size_t[2] dynOffsets = [ mvpCursor, localsCursor ];
        VertexBinding[1] vb = [ VertexBinding(vertexBuf.buffer, vertexCursor) ];
        const indInterval = node.radius > 0 ? indexBuf.rounded : indexBuf.sharp;

        cmd.bindDescriptorSets(PipelineBindPoint.graphics, layout.obj, 0, ds[], dynOffsets[]);
        cmd.bindVertexBuffers(0, vb[]);
        cmd.bindIndexBuffer(indexBuf.buf, indInterval.start*ushort.sizeof, IndexType.u16);
        cmd.drawIndexed(cast(uint)indInterval.length, 1, 0, 0, 0);

        mvpCursor += MVP.sizeof;
        localsCursor += ImgRectLocals.sizeof;
        vertexCursor += numVerts * RectImgVertex.sizeof;
    }

    void postrender()
    {
        mvpCursor = 0;
        localsCursor = 0;
        vertexCursor = 0;
        if (uniformBuf) uniformBuf.releaseMap();
        if (vertexBuf) vertexBuf.releaseMap();
    }

    void feedAtlas(immutable(FGRectNode) rn)
    {
        import dgt.core.paint : ImagePaint;
        import std.algorithm : filter;

        if (!(rn.cookie in imgNodes))
        {
            immutable paint = cast(immutable(ImagePaint))rn.paint;

            AtlasNode node;
            foreach (a; atlases.filter!(a => a.format == paint.image.format)) {
                node = a.pack(paint.image);
                if (node) break;
            }
            if (!node) {
                // could not pack (includes no atlas with right format in the list)
                import dgt.core.geometry : ISize;
                import dgt.core.image : ImageFormat;
                import dgt.render.atlas : Atlas, AtlasSizeRange;
                import dgt.render.binpack : maxRectsBinPackFactory, MaxRectsBinPack;
                import gfx.core.rc : retainObj;
                import std.exception : enforce;

                enum startSize = 128;
                enum maxSize = 4096;
                auto atlas = new Atlas(
                    maxRectsBinPackFactory(MaxRectsBinPack.Heuristic.bestShortSideFit, false),
                    atlases.length,
                    AtlasSizeRange(startSize, maxSize, sz => ISize(sz.width*2, sz.height*2) ),
                    paint.image.format, 1
                );
                atlases ~= retainObj(atlas);
                node = enforce(atlas.pack(paint.image),
                    "could not pack an image into a new atlas.");
                imgNodes[rn.cookie] = node;
            }
        }
    }
}

ushort[] sharpIndices() {
    return [
        0, 1, 2, 2, 1, 3,
        4, 5, 6, 6, 5, 7,
        8, 9, 10, 10, 9, 11,
        12, 13, 14, 14, 13, 15,
    ];
}

ushort[] roundedIndices() {
    ushort[] inds;
    inds.reserve(6*4 + 12*4);
    inds ~= [0, 1, 2, 0, 2, 3];
    inds ~= [4, 5, 6, 4, 6, 7];
    inds ~= [8, 9, 10, 8, 10, 11];
    inds ~= [12, 13, 14, 12, 14, 15];
    void addIndices(in ushort start) {
        inds ~= [
            cast(ushort)(start+0), cast(ushort)(start+1), cast(ushort)(start+4),
            cast(ushort)(start+0), cast(ushort)(start+4), cast(ushort)(start+2),
            cast(ushort)(start+4), cast(ushort)(start+1), cast(ushort)(start+5),
            cast(ushort)(start+5), cast(ushort)(start+1), cast(ushort)(start+3),
        ];
    }
    addIndices(16);
    addIndices(22);
    addIndices(28);
    addIndices(34);
    return inds;
}

size_t buildVertices(V)(immutable(FGRectNode) node, V[] verts)
{
    import dgt.core.geometry : FMargins, FPadding;
    import gfx.math : fvec;
    import std.algorithm : min;
    import gfx.core.log : warning;

    const r = node.rect;
    const radius = node.radius;
    const hm = min(r.width, r.height) / 2; // half min
    const hw = node.border.isSome ? node.border.get.width / 2 : 0;

    // inner rect
    const ir = r - FPadding(hm);
    // extent rect
    const er = r + FMargins(hw);

    if (radius > 0) {
        immutable rd = min(hm, radius);
        if (rd != radius) {
            warning(dgtRenderTag, "specified radius for rect is too big");
        }

        // top left corner
        immutable tlEdge = fvec(r.left+rd, r.top+rd, rd);
        verts[0] = V(fvec(er.left, er.top), tlEdge);
        verts[1] = V(fvec(r.left+rd, er.top), tlEdge);
        verts[2] = V(fvec(r.left+rd, r.top+rd), tlEdge);
        verts[3] = V(fvec(er.left, r.top+rd), tlEdge);
        // top right corner
        immutable trEdge = fvec(r.right-rd, r.top+rd, rd);
        verts[4] = V(fvec(r.right-rd, er.top), trEdge);
        verts[5] = V(fvec(er.right, er.top), trEdge);
        verts[6] = V(fvec(er.right, r.top+rd), trEdge);
        verts[7] = V(fvec(r.right-rd, r.top+rd), trEdge);
        // bottom right corner
        immutable brEdge = fvec(r.right-rd, r.bottom-rd, rd);
        verts[8] = V(fvec(r.right-rd, r.bottom-rd), brEdge);
        verts[9] = V(fvec(er.right, r.bottom-rd), brEdge);
        verts[10] = V(fvec(er.right, er.bottom), brEdge);
        verts[11] = V(fvec(r.right-rd, er.bottom), brEdge);
        // bottom left corner
        immutable blEdge = fvec(r.left+rd, r.bottom-rd, rd);
        verts[12] = V(fvec(er.left, r.bottom-rd), blEdge);
        verts[13] = V(fvec(r.left+rd, r.bottom-rd), blEdge);
        verts[14] = V(fvec(r.left+rd, er.bottom), blEdge);
        verts[15] = V(fvec(er.left, er.bottom), blEdge);

        // top side
        verts[16] = V(fvec(r.left+rd, er.top), fvec(r.left+rd, ir.top, hm));
        verts[17] = V(fvec(r.right-rd, er.top), fvec(r.right-rd, ir.top, hm));
        verts[18] = V(fvec(r.left+rd, r.top+rd), fvec(r.left+rd, ir.top, hm));
        verts[19] = V(fvec(r.right-rd, r.top+rd), fvec(r.right-rd, ir.top, hm));
        verts[20] = V(ir.topLeft, fvec(ir.topLeft, hm));
        verts[21] = V(ir.topRight, fvec(ir.topRight, hm));
        // right side
        verts[22] = V(fvec(er.right, r.top+rd), fvec(ir.right, r.top+rd, hm));
        verts[23] = V(fvec(er.right, r.bottom-rd), fvec(ir.right, r.bottom-rd, hm));
        verts[24] = V(fvec(r.right-rd, r.top+rd), fvec(ir.right, r.top+rd, hm));
        verts[25] = V(fvec(r.right-rd, r.bottom-rd), fvec(ir.right, r.bottom-rd, hm));
        verts[26] = V(ir.topRight, fvec(ir.topRight, hm));
        verts[27] = V(ir.bottomRight, fvec(ir.bottomRight, hm));
        // bottom side
        verts[28] = V(fvec(r.right-rd, er.bottom), fvec(r.right-rd, ir.bottom, hm));
        verts[29] = V(fvec(r.left+rd, er.bottom), fvec(r.left+rd, ir.bottom, hm));
        verts[30] = V(fvec(r.right-rd, r.bottom-rd), fvec(r.right-rd, ir.bottom, hm));
        verts[31] = V(fvec(r.left+rd, r.bottom-rd), fvec(r.left+rd, ir.bottom, hm));
        verts[32] = V(ir.bottomRight, fvec(ir.bottomRight, hm));
        verts[33] = V(ir.bottomLeft, fvec(ir.bottomLeft, hm));
        // left side
        verts[34] = V(fvec(er.left, r.bottom-rd), fvec(ir.left, r.bottom-rd, hm));
        verts[35] = V(fvec(er.left, r.top+rd), fvec(ir.left, r.top+rd, hm));
        verts[36] = V(fvec(r.left+rd, r.bottom-rd), fvec(ir.left, r.bottom-rd, hm));
        verts[37] = V(fvec(r.left+rd, r.top+rd), fvec(ir.left, r.top+rd, hm));
        verts[38] = V(ir.bottomLeft, fvec(ir.bottomLeft, hm));
        verts[39] = V(ir.topLeft, fvec(ir.topLeft, hm));

        return 40;
    }
    else {
        // top side
        verts[0] = V(er.topLeft, fvec(er.left, ir.top, hm));
        verts[1] = V(er.topRight, fvec(er.right, ir.top, hm));
        verts[2] = V(ir.topLeft, fvec(ir.topLeft, hm));
        verts[3] = V(ir.topRight, fvec(ir.topRight, hm));
        // right side
        verts[4] = V(er.topRight, fvec(ir.right, er.top, hm));
        verts[5] = V(er.bottomRight, fvec(ir.right, er.bottom, hm));
        verts[6] = V(ir.topRight, fvec(ir.topRight, hm));
        verts[7] = V(ir.bottomRight, fvec(ir.bottomRight, hm));
        // bottom side
        verts[8] = V(er.bottomRight, fvec(er.right, ir.bottom, hm));
        verts[9] = V(er.bottomLeft, fvec(er.left, ir.bottom, hm));
        verts[10] = V(ir.bottomRight, fvec(ir.bottomRight, hm));
        verts[11] = V(ir.bottomLeft, fvec(ir.bottomLeft, hm));
        // left side
        verts[12] = V(er.bottomLeft, fvec(ir.left, er.bottom, hm));
        verts[13] = V(er.topLeft, fvec(ir.left, er.top, hm));
        verts[14] = V(ir.bottomLeft, fvec(ir.bottomLeft, hm));
        verts[15] = V(ir.topLeft, fvec(ir.topLeft, hm));

        return 16;
    }
}

// set the gradient pos of the vertices
void setGPos(immutable(FGRectNode) node, RectColVertex[] verts)
{
    import dgt.core.paint : LinearGradientPaint;
    import gfx.math : dot, fvec;
    import std.algorithm : max;
    import std.math : cos, sin;

    immutable lgp = cast(immutable(LinearGradientPaint))node.paint;
    if (!lgp) return; // setGPos is also called for solid color rects

    // angle zero is defined to top (-Y)
    // angle 90deg is defined to right (+X)
    const r = node.rect;
    const angle = lgp.computeAngle(r.size);
    const c = r.center;
    const ca = cos(angle);
    const sa = sin(angle);

    // unit vec along gradient line
    immutable u = fvec(sa, -ca);

    // signed distance from center along the gradient line
    float orthoProjDist(in FVec2 p) {
        return dot(p-c, u);
    }

    const tl = orthoProjDist(r.topLeft);
    const tr = orthoProjDist(r.topRight);
    const br = orthoProjDist(r.bottomRight);
    const bl = orthoProjDist(r.bottomLeft);
    const fact = 0.5 / max(tl, tr, br, bl);

    foreach (ref v; verts) {
        v.gpos = fact * orthoProjDist(v.vpos) + 0.5f;
    }
}

struct CoordInfo
{
    import dgt.core.geometry : FRect, IRect, ISize;

    FRect viewRect;
    IRect imgRect;
    ISize atlasSize;
}

// set the tex coords of the vertices
void setTexCoords(const ref CoordInfo info, RectImgVertex[] verts)
{
    import gfx.math : fvec;

    const atlasSize = fvec(info.atlasSize.width, info.atlasSize.height);
    const imgOffset = fvec(info.imgRect.left, info.imgRect.top) / atlasSize;
    const imgSize = fvec(info.imgRect.width, info.imgRect.height) / atlasSize;
    const posOffset = info.viewRect.topLeft;
    const factor = imgSize / fvec(info.viewRect.width, info.viewRect.height);

    foreach (ref v; verts) {
        v.texCoord = (v.position - posOffset) * factor + imgOffset;
    }
}
