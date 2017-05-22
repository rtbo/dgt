module dgt.eventloop;

import dgt.application;
import dgt.platform;
import dgt.platform.event;
import dgt.render;
import dgt.window;

import std.experimental.logger;

/// An event loop
class EventLoop
{
    /// Enter event processing loop
    int loop()
    {
        while (!_exitFlag) {
            // for each frame
            //  - collect and process input events
            //  - if requested:
            //      - update
            //      - layout
            //      - collect rendering
            //  - if need rendering or need animation tick:
            //      - rendering (possibly only to swap buffers)
            //  - wait (for input, animation tick, or timer)

            Application.platform.collectEvents(&compressEvent);
            deliverEvents();
            if (_exitFlag) break;

            if (RenderThread.hadVSync) {
                import std.algorithm : filter, map;
                import std.array : array;
                immutable frames = _windows
                            .filter!(w => !w.dirtyRegion.empty)
                            .map!(w => w.collectFrame)
                            .array();
                if (frames.length) {
                    RenderThread.instance.frame(frames);
                }
            }
            Application.platform.waitFor(Wait.all);
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
        auto wEv = cast(WindowEvent)ev;
        if (wEv) {
            assert(hasWindow(wEv.window));
            version(Windows) {
                // windows has modal resize and move envents
                if (wEv.type == PlEventType.resize || wEv.type == PlEventType.move) {
                    wEv.window.handleEvent(wEv);
                    if (RenderThread.hadVSync)
                        RenderThread.instance.frame(wEv.window.collectFrame());
                }
                else {
                    wEv.window.compressEvent(wEv);
                }
            }
            else {
                wEv.window.compressEvent(wEv);
            }
        }
    }

    private void deliverEvents()
    {
        foreach (w; _windows) {
            w.deliverEvents();
        }
    }

    private bool _exitFlag;
    private int _exitCode;
    private Window[] _windows;
}
