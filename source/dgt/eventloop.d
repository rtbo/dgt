module dgt.eventloop;

import dgt.application;
import dgt.platform;
import dgt.platform.event;
import dgt.render.queue : RenderQueue;
import dgt.window;

import std.experimental.logger;

/// An event loop
class EventLoop
{
    /// Enter event processing loop
    int loop()
    {
        import dgt.platform : Wait;
        import std.algorithm : each, filter, map;
        import std.array : array;

        // initialize style and layout such as first event handlers has the
        // right state
        windows
            .filter!(w => w.ui && w.ui.needStylePass)
            .each!(w => w.ui.stylePass());
        windows
            .filter!(w => w.ui && w.ui.needLayoutPass)
            .each!(w => w.ui.layoutPass());

        while (true) {
            // the loop is as follow:
            //  - collect all events from platform
            //  - deliver events to ui(s)
            //  - style pass
            //  - layout pass
            //  - collect frame and send it to renderer
            //  - wait that at most one frame is in the render queue
            //  - wait that at least one event is in the event queue
            Application.platform.collectEvents(&compressEvent);
            deliverEvents();
            if (_exitFlag) {
                break;
            }
            windows
                .filter!(w => w.ui && w.ui.needStylePass)
                .each!(w => w.ui.stylePass());
            windows
                .filter!(w => w.ui && w.ui.needLayoutPass)
                .each!(w => w.ui.layoutPass());
            immutable frames = windows
                .filter!(w => w.ui && w.ui.needRenderPass)
                .map!(w => w.ui.frame(w.nativeHandle))
                .array;
            if (frames.length) {
                RenderQueue.instance.postFrames(frames);
                // actually wait if the frames from the previous loop are still
                // in process
                RenderQueue.instance.waitAtMostFrames(1);
            }
            Application.platform.wait(Wait.input | Wait.timer);
        }

        // Window.close removes itself from _windows, so we need to dup.
        auto ws = _windows.dup;
        foreach(w; ws) {
            w.close();
        }
        return _exitCode;
    }

    /// Register an exit code and exit at end of current event loop
    void exit(int code = 0)
    {
        _exitCode = code;
        _exitFlag = true;
    }

    /// The windows associated to this event loop.
    @property inout(Window)[] windows() inout
    {
        return _windows;
    }

    /// Whether the given window is registered with this event loop
    bool hasWindow(in Window w) const
    {
        import std.algorithm : canFind;
        return _windows.canFind(w);
    }

    package void registerWindow(Window w)
    {
        assert(!hasWindow(w), "tentative to register registered window");
        logf(`register window: 0x%08x "%s"`, cast(void*)w, w.title);
        _windows ~= w;

        onRegisterWindow(w);
    }

    package void unregisterWindow(Window w)
    {
        import std.algorithm : remove, SwapStrategy;
        assert(hasWindow(w), "tentative to unregister unregistered window");

        onUnregisterWindow(w);

        _windows = _windows.remove!(win => win is w, SwapStrategy.unstable)();
        logf(`unregister window: 0x%08x "%s"`, cast(void*)w, w.title);

        if (!_windows.length && !_exitFlag)
        {
            logf("last window exit!");
            exit(0);
        }
    }

    protected void onRegisterWindow(Window w) {}
    protected void onUnregisterWindow(Window w) {}

    private void compressEvent(PlEvent ev)
    {
        auto wEv = cast(PlWindowEvent)ev;
        if (wEv) {
            assert(hasWindow(wEv.window));
            version(Windows) {
                // windows has modal resize and move envents
                if (wEv.type == PlEventType.resize || wEv.type == PlEventType.move) {
                    wEv.window.handleEvent(wEv);
                    if (wEv.window.ui && RenderQueue.instance.numWaitingFrames <= 1) {
                        immutable frames = [
                            wEv.window.ui.frame(wEv.window.nativeHandle)
                        ];
                        RenderQueue.instance.postFrames(frames);
                    }
                }
                else {
                    wEv.window.compressEvent(wEv);
                }
            }
            else {
                wEv.window.compressEvent(wEv);
            }
        }
        else {
            if (ev.type == PlEventType.timer) {
                _timerEvents ~= cast(PlTimerEvent)ev;
            }
        }
    }

    private void deliverEvents()
    {
        import std.algorithm : each;
        windows.each!(w => w.deliverEvents());
        _timerEvents.each!(t => t.handle());
        _timerEvents = [];
    }

    private bool _exitFlag;
    private int _exitCode;
    private Window[] _windows;
    private PlTimerEvent[] _timerEvents;
}
