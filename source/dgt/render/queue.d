module dgt.render.queue;

import dgt.context;
import dgt.render.framegraph;
import dgt.render.renderer;

import gfx.core.log;
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

    /// Renderer is "moved" to the queue. It is undefined behavior to access
    /// other references to this context after this call.
    void start(Renderer renderer) {
        assert(!_running);
        _tid = spawn(&renderLoop, cast(shared(Renderer))renderer, thisTid);
        _running = true;
    }

    /// Stop the queue and discard all frames that are not rendered yet.
    void stop(size_t windowHandle) {
        assert(_running);
        prioritySend(_tid, Exit(windowHandle));
        while (_running) {
            receive(
                (DoneFrames df) { --_numFrames; },
                (ExitCopy ec) { _running = false; }
            );
        }
        _numFrames = 0;
    }

    /// The frames are submitted by batch, 1 frame for each window that needs to be rendered.
    /// It is illegal to have 2 frames for the same window in the same batch.
    void postFrames(immutable(FGFrame)[] frames) {
        assert(_running);
        send(_tid, frames);
        _numFrames++;
    }

    /// Blocks calling thread until the number of frames in the render queue is at most numFrames.
    /// To be noted: a frame that has started to be processed but not finished is still reported in the queue.
    void waitAtMostFrames(in size_t numFrames) {
        assert(_running);
        while (_numFrames > numFrames) {
            receive((DoneFrames df) {
                --_numFrames;
            });
        }
    }

    /// The number of frames waiting to be processed.
    /// To be noted: a frame that has started to be processed but not finished is still reported in the queue.
    @property size_t numWaitingFrames() {
        assert(_running);
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
    private __gshared RenderQueue _instance;
}

private:

/// posted by main loop
struct Exit {
    size_t windowHandle;
}

/// posted by render loop
struct ExitCopy {}

/// posted by the render loop after processing of each batch of frames
struct DoneFrames {}

void renderLoop(shared(Renderer) sharedRenderer, Tid caller)
{
    auto renderer = cast(Renderer)sharedRenderer;
    bool run = true;
    while(run) {
        bool doneFrame = false;
        try {
            receive(
                (immutable(FGFrame)[] frames) {
                    doneFrame = true;
                    renderer.render(frames);
                },
                (Exit e) {
                    run = false;
                    renderer.finalize(e.windowHandle);
                }
            );
        }
        catch (Exception ex) {
            import std.stdio : stderr;
            stderr.writefln("Exception in render thread: %s", ex.msg);
        }
        catch (Throwable th) {
            import core.stdc.stdlib : exit, EXIT_FAILURE;
            import std.stdio : stderr;
            // get a chance to print the error message before exiting the thread
            stderr.writefln("Unrecoverable error in render thread : %s", th.msg);
            exit(EXIT_FAILURE);
        }
        if (doneFrame) {
            send(caller, DoneFrames());
        }
    }
    prioritySend(caller, ExitCopy());
}
