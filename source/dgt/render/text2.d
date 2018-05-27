module dgt.render.text2;

import gfx.core.rc : Disposable;

class TextRenderer : Disposable
{
    import dgt.render.framegraph : FGTextNode;
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

    this(Device device, DeclarativeStore store, Allocator allocator)
    {
        this.device = device;
        this.pipeline = store.expect!Pipeline("text_pl");
        this.allocator = allocator;
    }

    override void dispose()
    {
        allocator.unload();
        pipeline.unload();
        device.unload();
    }

    void render(immutable(FGTextNode) node, RenderContext ctx, in FMat4 model)
    {

    }
}
