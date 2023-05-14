module dgt.render.image;

import dgt.render.renderer : FGNodeRenderer;

class ImageRenderer : FGNodeRenderer
{
    import dgt.render.atlasfeed : AtlasFeed;
    import dgt.render.framegraph : CacheCookie, FGImageNode, FGNode, FGType, FGVgNode;
    import dgt.render.renderer : RenderContext;
    import dgt.render.services : RenderServices;
    import gfx.core.rc : Rc;
    import gfx.decl.engine : DeclarativeEngine;
    import gfx.graal.cmd : CommandBuffer;
    import gfx.math : FMat4;
    import gfx.memalloc : Allocator;

    Rc!AtlasFeed atlasFeed;
    Rc!RenderServices services;
    Rc!Allocator allocator;

    this(AtlasFeed atlasFeed)
    {
        this.atlasFeed = atlasFeed;
    }

    override void dispose()
    {
        atlasFeed.unload();
        services.unload();
        allocator.unload();
    }

    override FGType[] types() const
    {
        return [ FGImageNode.fgType, FGVgNode.fgType ];
    }

    override void prepare(RenderServices services, DeclarativeEngine declEng, CommandBuffer cmd)
    {
        this.services = services;
        this.allocator = services.allocator;
    }

    override void prerender(immutable(FGNode) node)
    {

    }

    override void prerenderEnd(CommandBuffer cmd)
    {
    }

    override void render(immutable(FGNode) node, RenderContext ctx, in FMat4 model,
            CommandBuffer cmd)
    {
    }

    override void postrender()
    {
    }
}
