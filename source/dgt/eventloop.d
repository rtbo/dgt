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
            //  - collect and process input events
            //  - if requested:
            //      - update
            //      - layout
            //      - collect rendering
            //  - if need rendering or need animation tick:
            //      - rendering (possibly only to swap buffers)
            //  - wait (for input, animation tick, or timer)

            immutable waitCode = Application.platform.waitFor(Wait.all);
            Application.instance.platform.collectEvents(
                (Event ev) {
                    auto wEv = cast(WindowEvent)ev;
                    if (wEv) wEv.window.handleEvent(wEv);
                }
            );

            if (!_exitFlag && _windows.length && (waitCode & Wait.vsync))
            {
                RenderThread.instance.frame(_windows[0].collectFrame());
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

    package void registerWindow(Window w)
    {
        import std.algorithm : canFind;
        assert(!_windows.canFind(w), "tentative to register registered window");
        logf(`register window: 0x%08x "%s"`, cast(void*)w, w.title);
        _windows ~= w;
    }

    package void unregisterWindow(Window w)
    {
        import std.algorithm : canFind, remove, SwapStrategy;
        assert(_windows.canFind(w), "tentative to unregister unregistered window");
        _windows = _windows.remove!(win => win is w, SwapStrategy.unstable)();
        logf(`unregister window: 0x%08x "%s"`, cast(void*)w, w.title);

        // do not exit for a dummy window (they can be created and closed before event loop starts)
        if (w.flags & WindowFlags.dummy) return;

        if (!_windows.length && !_exitFlag)
        {
            logf("last window exit!");
            exit(0);
        }
    }

    private bool _exitFlag;
    private int _exitCode;
    private Window[] _windows;
}
