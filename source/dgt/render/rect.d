module dgt.render.rect;

import dgt.render.renderer : FGNodeRenderer;
import gfx.core.rc : Disposable;
import gfx.math : FVec2, FVec3, FVec4;

class RectRenderer : FGNodeRenderer
{
    import dgt.render.framegraph : FGNode, FGRectNode, FGType;
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

    Rc!BufferAlloc mvpBuf;
    size_t mvpCursor;

    Rc!BufferAlloc indexBuf;
    Interval!size_t sharpIndsInterval;
    Interval!size_t roundedIndsInterval;

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
        mvpBuf.unload();
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

        rectCol.prepare(services, declEng);
        rectImg.prepare(services, declEng);

        const sharpInds = sharpIndices();
        const roundedInds = roundedIndices();
        const inds = sharpInds ~ roundedInds;
        sharpIndsInterval = interval(0, sharpInds.length);
        roundedIndsInterval = interval(sharpInds.length, inds.length);
        indexBuf = services.allocator.allocateBuffer(
            BufferUsage.index, inds.length*ushort.sizeof, AllocOptions.forUsage(
                MemoryUsage.gpuOnly
            )
        );
        services.stageDataToBuffer(cmd, indexBuf, 0, cast(const(void)[])inds);
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

        mvpCursor += MVP.sizeof;
    }

    override void prerenderEnd(CommandBuffer cmd)
    {
        import dgt.render.services : mustReallocBuffer;
        import gfx.graal.buffer : BufferUsage;
        import gfx.memalloc : AllocOptions, MemoryUsage;

        rectCol.prerenderEnd();
        // rectImg.prerenderEnd();

        if (mustReallocBuffer(mvpBuf, mvpCursor)) {
            if (mvpBuf) services.gc(mvpBuf.obj);
            mvpBuf = services.allocator.allocateBuffer(
                BufferUsage.uniform, mvpCursor, AllocOptions.forUsage(
                    MemoryUsage.cpuToGpu
                )
            );
        }

        mvpCursor = 0;
    }

    override void render(immutable(FGNode) node, RenderContext ctx, in FMat4 model, CommandBuffer cmd)
    {}

    override void postrender()
    {}
}

private:

struct RectColVertex
{
    FVec3 position;
    FVec3 edge;
}

struct RectImgVertex
{
    FVec3 position;
    FVec2 texCoord;
    FVec3 edge;
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
    // ColStop[numStops] array follows
}

static assert(ColStop.sizeof == 8*float.sizeof);
static assert(ColRectLocals.sizeof == 8*float.sizeof);

class RectRendererBase : Disposable
{
    import dgt.render.framegraph : FGRectNode;
    import dgt.render.renderer : RenderContext;
    import dgt.render.services : RenderServices;
    import gfx.core.rc : Rc;
    import gfx.decl.engine : DeclarativeEngine;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : Pipeline;
    import gfx.math.mat : FMat4;
    import gfx.memalloc : Allocator;

    Rc!Device device;
    Rc!Allocator allocator;
    Rc!RenderServices services;

    Rc!Pipeline pipeline;
    string prefix;

    void prepare (RenderServices services, DeclarativeEngine declEng, string prefix)
    {
        this.services = services;
        this.device = services.device;
        this.allocator = services.allocator;
        this.prefix = prefix;
        this.pipeline = declEng.store.expect!Pipeline(prefix~"_pl");
    }

    override void dispose()
    {
        services.unload();
        allocator.unload();
        pipeline.unload();
        device.unload();
    }
}


final class RectColRenderer : RectRendererBase
{
    import dgt.render.framegraph : FGRectNode;
    import dgt.render.services : RenderServices;
    import gfx.core.rc : Rc;
    import gfx.decl.engine : DeclarativeEngine;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : Pipeline;
    import gfx.memalloc : BufferAlloc;

    Rc!BufferAlloc fragLocalsBuf;
    Rc!BufferAlloc vertexBuf;

    size_t colStopsCursor;
    size_t vertexCursor;

    override void dispose()
    {
        fragLocalsBuf.unload();
        vertexBuf.unload();
        super.dispose();
    }

    void prepare (RenderServices services, DeclarativeEngine declEng)
    {
        super.prepare(services, declEng, "rectcol");
    }

    void prerender(immutable(FGRectNode) rn)
    {
        import dgt.core.paint : LinearGradientPaint, PaintType;

        const pt = rn.paint.type;

        colStopsCursor += ColRectLocals.sizeof;
        if (pt == PaintType.color) {
            colStopsCursor += ColStop.sizeof;
        }
        else if (pt == PaintType.linearGradient) {
            immutable lgp = cast(immutable(LinearGradientPaint))rn.paint;
            colStopsCursor += lgp.stops.length * ColStop.sizeof;
        }

        vertexCursor += rn.radius > 0f ?
                40 * RectColVertex.sizeof :
                16 * RectColVertex.sizeof;
    }

    void prerenderEnd()
    {
        import dgt.render.services : mustReallocBuffer;
        import gfx.graal.buffer : BufferUsage;
        import gfx.memalloc : AllocFlags, AllocOptions, MemoryUsage;

        if (mustReallocBuffer(fragLocalsBuf, colStopsCursor)) {
            if (fragLocalsBuf) services.gc(fragLocalsBuf.obj);
            fragLocalsBuf = services.allocator.allocateBuffer(
                BufferUsage.uniform, colStopsCursor, AllocOptions.forUsage(
                    MemoryUsage.cpuToGpu
                )
            );
        }

        if (mustReallocBuffer(vertexBuf, vertexCursor)) {
            if (vertexBuf) services.gc(vertexBuf.obj);
            vertexBuf = services.allocator.allocateBuffer(
                BufferUsage.vertex, vertexCursor, AllocOptions.forUsage(
                    MemoryUsage.cpuToGpu
                )
            );
        }

        colStopsCursor = 0;
        vertexCursor = 0;
    }
}

final class RectImgRenderer : RectRendererBase
{
    import dgt.render.services : RenderServices;
    import gfx.decl.store : DeclarativeStore;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : Pipeline;

    override void dispose()
    {
        super.dispose();
    }

    void prepare (RenderServices services, DeclarativeEngine declEng)
    {
        super.prepare(services, declEng, "rectimg");
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
