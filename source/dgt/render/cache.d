/// Rendering cache module
module dgt.render.cache;

import dgt.render : dgtRenderLog;
import dgt.render.framegraph : CacheCookie;

import gfx.core.rc : Disposable;

class RenderCache : Disposable
{
    import gfx.core.rc : IAtomicRefCounted;

    override void dispose() {
        import gfx.core.rc : releaseAA;
        releaseAA(_cache);
    }

    /// Add a resource identified by cookie in the cache
    void cache(in CacheCookie cookie, IAtomicRefCounted resource) {
        auto rcp = cookie in _cache;
        if (rcp && (*rcp) is resource) {
            dgtRenderLog.warning("RenderCache: Resource already cached.");
        }
        else if (rcp && (*rcp) !is resource) {
            dgtRenderLog.warning("RenderCache : Overriding a resource.");
            rcp.release();
            resource.retain();
            (*rcp) = resource;
        }
        else {
            _cache[cookie] = resource;
        }
    }

    /// Retrieve the resource identified by cookie.
    IAtomicRefCounted resource(in CacheCookie cookie) {
        auto rcp = cookie in _cache;
        if (rcp) return *rcp;
        else return null;
    }

    /// Release a resource from the cache.
    void prune(in CacheCookie cookie) {
        auto rcp = cookie in _cache;
        if (rcp) {
            rcp.release();
            _cache.remove(cookie);
        }
    }

    private IAtomicRefCounted[CacheCookie] _cache;
}
