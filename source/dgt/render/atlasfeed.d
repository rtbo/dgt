module dgt.render.atlasfeed;

import dgt.render : dgtRenderLog;
import gfx.core.rc : AtomicRefCounted;

class AtlasFeed : AtomicRefCounted
{
    import dgt.gfx.image : Image, RImage;
    import dgt.render.atlas;
    import dgt.render.framegraph;
    import gfx.math : FVec2;

    private Atlas[] _atlases;
    private AtlasNode[CacheCookie] _atlasNodes;

    this()
    {}

    override void dispose()
    {
        import gfx.core.rc : releaseArr;

        releaseArr(_atlases);
        _atlasNodes.clear();
    }

    /// Feed one of the atlases with an image in the node.
    /// The feeding can succeed only the node has an image to be uploaded and
    /// if it has a valid cacheCookie.
    /// Returns: Whether an atlas could be fed, or was fed in the past with data
    /// that still applies.
    bool cacheFeed (immutable(FGRenderNode) node)
    {
        RImage img;
        FVec2 orig;
        bool hasLazy;

        const cookie = checkNode(node, img, orig, hasLazy);

        if (!img && !hasLazy) return false;

        if (!cookie) {
            dgtRenderLog.warning("Node has image but no cache cookie");
            return false;
        }

        if (auto anp = cookie in _atlasNodes) return true;

        if (hasLazy) {
            img = lazyImage(node, orig);
        }

        assert(img);
        auto an = feedImpl(img);

        an.orig = orig;
        _atlasNodes[cookie] = an;

        return true;
    }

    /// Retrieve an atlas node from the given render node.
    /// If an atlas node could previously be cached in one of the atlases,
    /// the cached node is retrieved (look-up is done by the node's cache cookie).
    /// Otherwise, an atlas is fed on the fly and a AtlasNode is retrieved.
    AtlasNode feed (immutable (FGRenderNode) node)
    {
        RImage img;
        FVec2 orig;
        bool hasLazy;

        const cookie = checkNode(node, img, orig, hasLazy);

        if (!img && !hasLazy) {
            dgtRenderLog.warning("AtlasFeed.retrieve called with node without image");
            return null;
        }

        if (auto anp = cookie in _atlasNodes) return *anp;

        if (hasLazy) {
            img = lazyImage(node, orig);
        }

        assert(img);
        auto an = feedImpl(img);

        an.orig = orig;
        if (cookie) _atlasNodes[cookie] = an;

        return an;
    }

    private CacheCookie checkNode(immutable(FGRenderNode) node, out RImage img, out FVec2 orig, out bool hasLazy)
    {
        import dgt.gfx.paint : ImagePaint, PaintType;
        import gfx.core.util : unsafeCast;
        import gfx.math : fvec;

        CacheCookie cookie;

        switch (node.renderType) {
        case FGRenderType.rect:
            immutable rn = unsafeCast!(immutable(FGRectNode))(node);
            if (rn.paint.type == PaintType.image) {
                img = unsafeCast!(immutable(ImagePaint))(rn.paint).image;
                orig = fvec(0, 0);
                cookie = rn.cookie;
            }
            break;
        case FGRenderType.image:
            immutable imgN = unsafeCast!(immutable(FGImageNode))(node);
            img = imgN.image;
            orig = imgN.orig;
            cookie = imgN.cookie;
            break;
        case FGRenderType.vg:
            immutable vgn = unsafeCast!(immutable(FGVgNode))(node);
            hasLazy = true;
            cookie = vgn.cookie;
            break;
        default:
            break;
        }

        return cookie;
    }

    private immutable(Image) lazyImage(immutable(FGRenderNode) node, out FVec2 orig)
    {
        import dgt.vg.cmdbuf : execute;
        import gfx.core.util : unsafeCast;

        assert(node.renderType == FGRenderType.vg);
        immutable vgn = unsafeCast!(immutable(FGVgNode))(node);
        const anchored = execute(vgn.cmdBuf);
        orig = anchored.orig;
        return anchored.image;
    }

    /// Feed and retrieve an AtlasNode for img, and cache it with cookie.
    AtlasNode feed (immutable(Image) img, CacheCookie cookie = nullCookie)
    {
        if (cookie) {
            if (auto anp = cookie in _atlasNodes) return *anp;
            auto an = feedImpl(img);
            _atlasNodes[cookie] = an;
            return an;
        }
        else {
            return feedImpl(img);
        }
    }

    /// Feed and retrieve an AtlasNode for img, and cache it with cookie.
    AtlasNode retrieve (CacheCookie cookie)
    {
        if (auto anp = cookie in _atlasNodes) return *anp;
        return null;
    }

    private AtlasNode feedImpl (immutable(Image) img)
    {
        import dgt.gfx.paint : ImagePaint, PaintType;
        import gfx.math : FVec2, fvec;
        import std.algorithm : filter;

        AtlasNode node;
        foreach (a; _atlases.filter!(a => a.format == img.format)) {
            // TODO: the same image can be referenced under several cookies
            // ==> try to find it in the atlas before packing
            node = a.pack(img);
            if (node) break;
        }
        if (!node) {
            // could not pack (includes no atlas with right format in the list)
            import dgt.gfx.geometry : ISize;
            import dgt.render.binpack : maxRectsBinPackFactory, MaxRectsBinPack;
            import gfx.core.rc : retainObj;
            import std.exception : enforce;

            enum startSize = 128;
            enum maxSize = 4096;
            auto atlas = new Atlas(
                maxRectsBinPackFactory(MaxRectsBinPack.Heuristic.bestShortSideFit, false),
                _atlases.length,
                AtlasSizeRange(startSize, maxSize, sz => ISize(sz.width*2, sz.height*2) ),
                img.format, 1
            );
            _atlases ~= retainObj(atlas);
            node = enforce(atlas.pack(img),
                "could not pack an image into a new atlas.");

        }
        return node;
    }
}
