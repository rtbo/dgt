module dgt.render.queue;

import dgt.context;
import dgt.render.framegraph;
import dgt.render.renderer;

import std.experimental.logger;
import std.concurrency;

/// Queue of framegraph frames that are submitted to a renderer.
/// The renderer lives in a different thread.
/// Public interface is not thread safe and is designed be called from the same thread.
class RenderQueue
{
    /// Get the singleton instance
    static RenderQueue instance()
    {
        return _instance;
    }

    package(dgt) this() {}
    package(dgt) static void initialize()
    {
        _instance = new RenderQueue;
    }


    /// Whether the render thread is running
    @property bool running() const { return _running; }

    /// Context is "moved" to the queue. It is undefined behavior to access
    /// other references to this context after this call.
    void start(GlContext context) {
        assert(!_running);
        _tid = spawn(&renderLoop, cast(shared(GlContext))context, thisTid);
        _running = true;
    }

    /// Stop the queue and discard all frames that are not rendered yet.
    void stop(size_t windowHandle) {
        assert(_running);
        prioritySend(_tid, Exit(windowHandle));
        receiveOnly!ExitCopy();
        _numFrames = 0;
        _running = false;
    }

    /// The frames are submitted by batch, 1 frame for each window that needs to be rendered.
    /// It is illegal to have 2 frames for the same window in the same batch.
    void postFrames(immutable(FGFrame)[] frames) {
        send(_tid, frames);
        _numFrames++;
    }

    /// Blocks calling thread until the number of frames in the render queue is at most numFrames.
    /// To be noted: a frame that has started to be processed but not finished is still reported in the queue.
    void waitAtMostFrames(in size_t numFrames) {
        while (_numFrames > numFrames) {
            receive((DoneFrames df) {
                --_numFrames;
            });
        }
    }

    /// The number of frames waiting to be processed.
    /// To be noted: a frame that has started to be processed but not finished is still reported in the queue.
    @property size_t numWaitingFrames() {
        import core.time : Duration;
        // draining the mail box
        while (receiveTimeout(Duration.min, (DoneFrames df) {
            --_numFrames;
        })) {}
        return _numFrames;
    }

    private Tid _tid;
    private size_t _numFrames;
    private bool _running;
    private static __gshared RenderQueue _instance;
}

private:

import gfx.device;
import gfx.device.gl3 : createGlDevice;

/// posted by main loop
struct Exit {
    size_t windowHandle;
}

/// posted by render loop
struct ExitCopy { }

/// posted by the render loop after processing of each batch of frames
struct DoneFrames {}

void renderLoop(shared(GlContext) context, Tid caller) {
    auto rt = new RenderThread(cast(GlContext)context);
    bool exit = false;
    while(!exit) {
        receive(
            (immutable(FGFrame)[] frames) {
                rt.frames(frames);
                send(caller, DoneFrames());
            },
            (Exit e) {
                exit = true;
                prioritySend(caller, ExitCopy());
            }
        );
    }
}

class RenderThread {
    GlContext _context;
    Renderer _renderer;

    this(GlContext context) {
        _context = context;
    }

    void finalize(size_t windowHandle) {
        assert(_renderer);
        _context.makeCurrent(windowHandle);
        scope(exit) _context.doneCurrent();
        _renderer.dispose();
        _renderer = null;
    }

    void frames(immutable(FGFrame)[] frames) {
        foreach (i, f; frames) {
            if (!_context.makeCurrent(f.windowHandle)) {
                error("could not make rendering context current!");
                return;
            }
            scope(exit) _context.doneCurrent();

            _context.swapInterval = ((i+1) == frames.length) ? 1 : 0;

            if (!_renderer) {
                _renderer = new Renderer(createGlDevice(), RenderOptions(_context.attribs.samples));
            }

            _renderer.renderFrame(f);

            _context.swapBuffers(f.windowHandle);
        }
    }
}
