module dgt.render.rect2;

import dgt.render.renderer2 : FGNodeRenderer;
import gfx.core.rc : Disposable;
import gfx.math.vec : FVec2, FVec3;

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

class RectRenderer : FGNodeRenderer
{
    import dgt.render.framegraph : FGNode, FGRectNode, FGType;
    import dgt.render.renderer2 : PrepareContext, PrerenderContext, RenderContext;
    import gfx.decl.store : DeclarativeStore;
    import gfx.graal.cmd : CommandBuffer;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : DescriptorPool, Pipeline;
    import gfx.math : FMat4;
    import gfx.memalloc : Allocator;

    RectColRenderer rectCol;
    RectImgRenderer rectImg;

    this()
    {}

    override void dispose()
    {
        import gfx.core.rc : disposeObj;

        disposeObj(rectCol);
        disposeObj(rectImg);
    }

    override FGType type() const
    {
        import dgt.render.framegraph : FGRenderType, FGTypeCat;

        return FGType(FGTypeCat.render, FGRenderType.rect);
    }

    override void prepare(Device device, DeclarativeStore store, Allocator allocator, PrepareContext ctx)
    {}

    override void initDescriptors(DescriptorPool pool)
    {}

    override void prerender(immutable(FGNode) node, PrerenderContext ctx)
    {}

    override void prerenderEnd(PrerenderContext ctx, CommandBuffer cmd)
    {}

    override void render(immutable(FGNode) node, RenderContext ctx, in FMat4 model, CommandBuffer cmd)
    {}

    override void postrender()
    {}
}

private:

class RectRendererBase : Disposable
{
    import dgt.render.framegraph : FGRectNode;
    import dgt.render.renderer2 : RenderContext;
    import gfx.core.rc : Rc;
    import gfx.decl.store : DeclarativeStore;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : Pipeline;
    import gfx.math.mat : FMat4;
    import gfx.memalloc : Allocator;

    Rc!Device device;
    Rc!Pipeline pipeline;
    Rc!Allocator allocator;
    string prefix;

    this(Device device, DeclarativeStore store, Allocator allocator, string prefix)
    {
        this.device = device;
        this.allocator = allocator;
        this.prefix = prefix;
        this.pipeline = store.expect!Pipeline(prefix~"_pl");
    }

    override void dispose()
    {
        allocator.unload();
        pipeline.unload();
        device.unload();
    }
}


class RectColRenderer : RectRendererBase
{
    import gfx.decl.store : DeclarativeStore;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : Pipeline;

    this(Device device, DeclarativeStore store, Allocator allocator)
    {
        super(device, store, allocator, "rectcol");
    }
}

class RectImgRenderer : RectRendererBase
{
    import gfx.decl.store : DeclarativeStore;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : Pipeline;

    this(Device device, DeclarativeStore store, Allocator allocator)
    {
        super(device, store, allocator, "rectimg");
    }
}

