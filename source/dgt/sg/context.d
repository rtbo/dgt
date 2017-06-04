module dgt.sg.context;

import dgt.math.mat;
import gfx.foundation.rc;
import gfx.pipeline;

final class SGContext : Disposable
{
    override void dispose()
    {
        disposeGarbage();
        _renderTarget.unload();
    }

    /// The view - projection transform matrix
    @property FMat4 viewProj()
    {
        return _viewProj;
    }
    /// ditto
    @property void viewProj(in FMat4 proj)
    {
        _viewProj = proj;
    }

    /// The current render target
    @property RenderTargetView!Rgba8 renderTarget()
    {
        return _renderTarget;
    }
    /// ditto
    @property void renderTarget(RenderTargetView!Rgba8 rtv)
    {
        _renderTarget = rtv;
    }

    /// Collect some resource to be disposed.
    /// Resource will be retained and finally disposed when a context is current
    void collectGarbage(Disposable res)
    {
        _garbageD ~= res;
    }

    /// ditto
    void collectGarbage(RefCounted res)
    {
        res.retain();
        _garbageRC ~= res;
    }

    /// Called when the context is current
    void disposeGarbage()
    {
        import std.algorithm : each;
        _garbageD.each!(g => g.dispose());
        _garbageRC.each!(g => g.release());
        _garbageD = null;
        _garbageRC = null;
    }

    FMat4 _viewProj;
    Rc!(RenderTargetView!Rgba8) _renderTarget;
    Disposable[] _garbageD;
    RefCounted[] _garbageRC;
}