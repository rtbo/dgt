/// Rendering cache module
module dgt.render.cache;

import dgt.core.rc : Disposable;
import dgt.render.framegraph : CacheCookie;

import std.experimental.logger;

class RenderCache : Disposable
{
    import dgt.core.rc : AtomicRefCounted;

    override void dispose() {
        import dgt.core.rc : releaseAA;
        releaseAA(_cache);
    }

    /// Add a resource identified by cookie in the cache
    void cache(in CacheCookie cookie, AtomicRefCounted resource) {
        auto rcp = cookie in _cache;
        if (rcp && (*rcp) is resource) {
            warning("RenderCache: Resource already cached.");
        }
        else if (rcp && (*rcp) !is resource) {
            warning("RenderCache : Overriding a resource.");
            rcp.release();
            resource.retain();
            (*rcp) = resource;
        }
        else {
            _cache[cookie] = resource;
        }
    }

    /// Retrieve the resource identified by cookie.
    AtomicRefCounted resource(in CacheCookie cookie) {
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

    private AtomicRefCounted[CacheCookie] _cache;
}
