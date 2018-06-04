module dgt.render.rect;

import dgt.render.renderer : FGNodeRenderer;
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
    import dgt.render.renderer : RenderContext;
    import dgt.render.services : RenderServices;
    import gfx.decl.engine : DeclarativeEngine;
    import gfx.graal.cmd : CommandBuffer;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : DescriptorPool, Pipeline;
    import gfx.math : FMat4;
    import gfx.memalloc : Allocator;

    RectColRenderer rectCol;
    RectImgRenderer rectImg;

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
    }

    override FGType type() const
    {
        import dgt.render.framegraph : FGRenderType, FGTypeCat;

        return FGType(FGTypeCat.render, FGRenderType.rect);
    }

    override void prepare(RenderServices services, DeclarativeEngine declEng)
    {
        import std.array : join;
        import std.range : only;

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
    }

    override void prerender(immutable(FGNode) node)
    {}

    override void prerenderEnd(CommandBuffer cmd)
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
    import dgt.render.services : RenderServices;
    import gfx.decl.engine : DeclarativeEngine;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : Pipeline;

    void prepare (RenderServices services, DeclarativeEngine declEng)
    {
        super.prepare(services, declEng, "rectcol");
    }
}

final class RectImgRenderer : RectRendererBase
{
    import dgt.render.services : RenderServices;
    import gfx.decl.store : DeclarativeStore;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : Pipeline;

    void prepare (RenderServices services, DeclarativeEngine declEng)
    {
        super.prepare(services, declEng, "rectimg");
    }
}

