module dgt.eventloop;

import dgt.application;
import dgt.platform;
import dgt.platform.event;
import dgt.sg.renderer;
import dgt.window;

import std.experimental.logger;

/// An event loop
class EventLoop
{
    /// Enter event processing loop
    int loop()
    {
        while (!_exitFlag) {

            import std.algorithm : each, filter;
            import std.array : array;

            _windows.each!(w => w.styleAndLayout());

            auto dirtyWindows = _windows
                    .filter!(w => w.dirtyContent)
                    .array();
            if (dirtyWindows.length) {
                SGRenderer.instance.syncAndRender(dirtyWindows);
                dirtyWindows.each!(w => w.cleanContent());
            }

            Application.platform.waitFor(Wait.input);
            Application.platform.collectEvents(&compressEvent);
            deliverEvents();
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
                // windows has modal resize and move events
                if (wEv.type == PlEventType.resize || wEv.type == PlEventType.move) {
                    wEv.window.handleEvent(wEv);
                    wEv.window.styleAndLayout();
                    if (wEv.window.dirtyContent) {
                        SGRenderer.instance.syncAndRender([wEv.window]);
                        wEv.window.cleanContent();
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
