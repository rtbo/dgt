module dgt.eventloop;

import dgt.application;
import dgt.event;
import dgt.render;
import dgt.window;
import dgt.platform;

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

            if (!_exitFlag) {
                if (_windows.length && RenderThread.hadVSync) {
                    if (!_windows[0].dirtyRegion.empty) {
                        RenderThread.instance.frame(_windows[0].collectFrame());
                    }
                }
                Application.platform.waitFor(Wait.all);
            }

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

    private void compressEvent(Event ev)
    {
        auto wEv = cast(WindowEvent)ev;
        if (wEv) {
            assert(hasWindow(wEv.window));
            version(Windows) {
                // windows has modal resize and move envents
                if (wEv.type == EventType.resize || wEv.type == EventType.move) {
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
