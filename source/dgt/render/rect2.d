module dgt.render.rect2;

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

class RectRenderer : Disposable
{
    import dgt.render.framegraph : FGRectNode;
    import dgt.render.renderer2 : RenderContext;
    import gfx.decl.store : DeclarativeStore;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : Pipeline;
    import gfx.math.mat : FMat4;
    import gfx.memalloc : Allocator;

    RectColRenderer rectCol;
    RectImgRenderer rectImg;

    this(Device device, DeclarativeStore store, Allocator allocator)
    {
        rectCol = new RectColRenderer(device, store, allocator);
        rectImg = new RectImgRenderer(device, store, allocator);
    }

    override void dispose()
    {
        import gfx.core.rc : disposeObj;

        disposeObj(rectCol);
        disposeObj(rectImg);
    }

    void render(immutable(FGRectNode) node, RenderContext ctx, in FMat4 model)
    {

    }
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

