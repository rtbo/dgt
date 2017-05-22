module dgt.platform.win32;

version(Windows):

import dgt.context;
import dgt.geometry;
import dgt.platform;
import dgt.platform.event;
import dgt.platform.win32.context;
import dgt.platform.win32.window;
import dgt.screen;
import dgt.window;

import std.experimental.logger;
import core.sys.windows.winuser;
import core.sys.windows.windows;

private __gshared Win32Platform _w32Inst;

/// Win32 platform implementation
class Win32Platform : Platform
{
    private wstring[] _registeredClasses;
    private Win32Window[HWND] _windows;
    private Screen[] _screens;

    private void delegate(PlEvent) _collector;

    /// Instance access
    static Win32Platform instance()
    {
        assert(_w32Inst !is null);
        return _w32Inst;
    }

    this()
    {
        assert(_w32Inst is null);
        _w32Inst = this;
        _collector = &internalCollect;
        fetchScreens();
    }

    override void initialize()
    {
        initWin32Gl();
    }

    override void dispose()
    {
        _w32Inst = null;
    }

    override @property string name() const
    {
        return "win32";
    }

    override GlContext createGlContext(
                GlAttribs attribs, PlatformWindow window,
                GlContext sharedCtx, Screen screen)
    {
        return createWin32GlContext(attribs, window, sharedCtx, screen);
    }

    override @property inout(Screen) defaultScreen() inout
    {
        return _screens[0];
    }

    override @property inout(Screen)[] screens() inout
    {
        return _screens;
    }

    override PlatformWindow createWindow(Window window)
    {
        return new Win32Window(window);
    }


    override void collectEvents(void delegate(PlEvent) collector)
    {
        _collector = collector;
        scope(exit) _collector = &internalCollect;

        MSG msg;
        while(PeekMessage(&msg, null, 0, 0, PM_REMOVE) > 0) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    override void processEvents()
    {
        _collector = (PlEvent ev) {
            auto wEv = cast(WindowEvent)ev;
            if (wEv) {
                wEv.window.handleEvent(wEv);
            }
        };
        scope(exit) _collector = &internalCollect;

        MSG msg;
        if (GetMessage(&msg, null, 0, 0) > 0)
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    private enum WM_VSYNC = WM_USER+1;

    override Wait waitFor(Wait flags)
    {
        Wait check() {
            Wait res = Wait.none;
            MSG msg;
            if (PeekMessage(&msg, null, 0, 0, PM_NOREMOVE)) {
                if (msg.message == WM_VSYNC) {
                    res |= Wait.vsync;
                }
                else {
                    res |= Wait.input;
                }
            }
            return res;
        }

        Wait wait = check();
        if (wait != Wait.none) return wait;

        immutable code = MsgWaitForMultipleObjects(0, null, FALSE, INFINITE, QS_ALLINPUT);

        return check();
    }

    override void vsync()
    {
        PostMessage(null, WM_VSYNC, 0, 0);
    }

    wstring windowClassName(Window w)
    {
        return "DgtWin32WindowClass"w;
    }


    public wstring registerWindowClass(Window w)
    {
        import std.algorithm : canFind;
        import std.conv : to;
        import std.utf : toUTF16z;

        wstring clsName = windowClassName(w);
        if (_registeredClasses.canFind(clsName)) return clsName;

        HINSTANCE hInstance = GetModuleHandle(null);

        WNDCLASSEX wc;
        wc.cbSize        = WNDCLASSEX.sizeof;
        wc.style         = CS_OWNDC;
        wc.lpfnWndProc   = &win32WndProc;
        wc.cbClsExtra    = 0;
        wc.cbWndExtra    = 0;
        wc.hInstance     = hInstance;
        wc.hIcon         = LoadIcon(null, IDI_APPLICATION);
        wc.hCursor       = LoadCursor(null, IDC_ARROW);
        wc.hbrBackground = null;
        wc.lpszMenuName  = null;
        wc.lpszClassName = clsName.toUTF16z;
        wc.hIconSm       = LoadIcon(null, IDI_APPLICATION);

        if(!RegisterClassEx(&wc))
        {
            throw new Exception("could not register win32 class " ~ clsName.to!string);
        }

        _registeredClasses ~= clsName;
        return clsName;
    }


    void registerWindow(HWND hWnd, Win32Window w)
    {
        _windows[hWnd] = w;
    }

    void unregisterWindow(HWND hWnd)
    {
        _windows.remove(hWnd);
    }

    private void fetchScreens()
    {
        _screens = [];
        auto dc = GetDC(null);
        EnumDisplayMonitors(dc, null, &win32MonitorEnumProc, 0);
        ReleaseDC(null, dc);
    }

    private Win32Window findWithHWnd(HWND hWnd)
    {
        Win32Window *w = (hWnd in _windows);
        return w ? *w : null;
    }


    private LRESULT wndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam, out LRESULT res)
    {
        assert(_collector);
        res = 0;

        Win32Window wnd = findWithHWnd(hWnd);
        if (!wnd) {
            return false;
        }

        switch(msg)
        {
            case WM_CLOSE:
                return wnd.handleClose(_collector);
            case WM_PAINT:
            case WM_ERASEBKGND:
                return wnd.handlePaint(msg, wParam, lParam, _collector);
            case WM_SIZE:
                return wnd.handleResize(msg, wParam, lParam, _collector);
            case WM_MOVE:
                return wnd.handleMove(msg, wParam, lParam, _collector);
            case WM_SHOWWINDOW:
                return wnd.handleShow(msg, wParam, lParam, _collector);
            case WM_LBUTTONDOWN:
            case WM_LBUTTONUP:
            case WM_MBUTTONDOWN:
            case WM_MBUTTONUP:
            case WM_RBUTTONDOWN:
            case WM_RBUTTONUP:
            case WM_MOUSEMOVE:
            case WM_MOUSELEAVE:
                return wnd.handleMouse(msg, wParam, lParam, _collector);
            case WM_KEYDOWN:
            case WM_KEYUP:
            case WM_CHAR:
                return wnd.handleKey(msg, wParam, lParam, _collector);
            default:
                return false;
        }
    }

    private void internalCollect(PlEvent ev)
    {
        // TODO: impl an temp event buf
    }
}

class Win32Screen : Screen
{
    int _num;
    IRect _rect;
    double _dpi;

    this(int num, IRect rect, double dpi)
    {
        _num = num; _rect = rect; _dpi = dpi;
    }

    @property int num() const { return _num; }
    @property IRect rect() const { return _rect; }
    @property double dpi() const { return _dpi; }
}

extern(Windows) nothrow
private LRESULT win32WndProc (HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    import std.exception : collectExceptionMsg;
    LRESULT res;
    try
    {
        if (!_w32Inst.wndProc(hwnd, msg, wParam, lParam, res))
        {
            res = DefWindowProc(hwnd, msg, wParam, lParam);
        }
    }
    catch(Exception ex)
    {
        try { errorf("Win32 Proc exception: %s", ex.msg); }
        catch(Exception) {}
    }
    return res;
}

extern(Windows) nothrow
private BOOL win32MonitorEnumProc(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor, LPARAM dwData)
{
    try
    {
        auto num = _w32Inst._screens.length;
        auto rect = rectFromWin32(*lprcMonitor);
        auto dpi = GetDeviceCaps(hdcMonitor, LOGPIXELSX);
        _w32Inst._screens ~= new Win32Screen(cast(int)num, rect, cast(double)dpi);
    }
    catch(Exception ex)
    {
        try { errorf("Win32 Monitor Proc exception: %s", ex.msg); }
        catch(Exception) {}
    }
    return TRUE;
}
