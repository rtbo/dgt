module dgt.sg.renderer;

import dgt.context;
import dgt.sg.rendernode;

import std.concurrency;

Tid startRenderThread(shared(GlContext) context)
{
    return spawn(&renderLoop, context);
}


private:


void renderLoop(shared(GlContext) context)
{

}


class Renderer
{
    shared(GlContext) _context;
    size_t _currentHandle;

    this(shared(GlContext) context)
    {
        _context = context;
    }

    bool beginFrame(size_t nativeHandle)
    {
        assert(!_currentHandle);
        _currentHandle = nativeHandle;
        return _context.makeCurrent(nativeHandle);
    }

    void endFrame(size_t nativeHandle)
    {
        assert(nativeHandle == _currentHandle);
        _context.doneCurrent();
        _context.swapBuffers(nativeHandle);
        _currentHandle = 0;
    }

    void renderNode(immutable(RenderNode) root)
    {

    }
}
