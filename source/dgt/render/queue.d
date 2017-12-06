module dgt.render.queue;

import dgt.context;
import dgt.render.framegraph;
import dgt.render.renderer;

import std.experimental.logger;
import std.concurrency;

/// Queue of framegraph frames that are submitted to a renderer.
/// The renderer lives in a different thread.
/// Public interface is not thread safe and should be called from the same thread
class RenderQueue
{
    /// Context is "moved" to the queue. It is undefined behavior to access
    /// other references to this context after this call.
    void start(GlContext context) {
        _tid = spawn(&renderLoop, cast(shared(GlContext))context, thisTid);
    }

    /// Stop the queue and discard all frames that are not rendered yet.
    void stop() {
        prioritySend(_tid, Exit());
        _numFrames = 0;
    }

    /// The frames are submitted by batch, 1 for each window that needs to be rendered.
    /// it is illegal to have 2 frames for the same window
    void postFrames(immutable(FGFrame)[] frames) {
        send(_tid, frames);
        _numFrames++;
    }

    void waitAtMostFrames(in size_t numFrames) {
        while (_numFrames > numFrames) {
            receiveOnly!DoneFrames();
            --_numFrames;
        }
    }

    private Tid _tid;
    private size_t _numFrames;
}

private:

import gfx.device;
import gfx.device.gl3 : createGlDevice;

/// posted by main loop
struct Exit {
    size_t windowHandle;
}

/// posted by the renderer after submission of each batch of frames
struct DoneFrames {}

void renderLoop(shared(GlContext) context, Tid caller) {
    auto rt = new RenderThread(cast(GlContext)context);
    bool exit = false;
    while(exit) {
        receive(
            (immutable(FGFrame)[] frames) {
                rt.frames(frames);
                send(caller, DoneFrames());
            },
            (Exit e) {
                exit = true;
            }
        );
    }
}

class RenderThread {
    GlContext _context;
    Device _device;
    Renderer _renderer;

    this(GlContext context) {
        _context = context;
    }

    void initialize() {
        _device = createGlDevice();
        _renderer = new Renderer(_device, RenderOptions(_context.attribs.samples));
    }

    void finalize(size_t windowHandle) {
        _context.makeCurrent(windowHandle);
        scope(exit) _context.doneCurrent();
    }

    void frames(immutable(FGFrame)[] frames) {
        foreach (i, f; frames) {
            if (!_context.makeCurrent(f.windowHandle)) {
                error("could not make rendering context current!");
                return;
            }
            scope(exit) _context.doneCurrent();

            _context.swapInterval = (i == frames.length-1) ? 1 : 0;

            if (!_device) initialize();
            assert(_device && _renderer);

            _renderer.renderFrame(f);

            _context.swapBuffers(f.windowHandle);
        }
    }
}
