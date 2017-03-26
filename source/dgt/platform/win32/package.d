module dgt.platform.win32;

version(Windows):

import dgt.platform.win32.window;
import dgt.platform.win32.screen;
import dgt.platform;
import dgt.screen;
import dgt.window;

import std.experimental.logger;
import core.sys.windows.windows;

private __gshared Win32Platform _w32Inst;

/// Win32 platform implementation
class Win32Platform : Platform
{
    private wstring[] _registeredClasses;
    private Win32Window[HWND] _windows;

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
    }

    override void dispose()
    {
        _w32Inst = null;
    }

    override @property string name() const
    {
        return "win32";
    }

    override @property PlatformCapsFlags caps() const
    {
        PlatformCapsFlags res = PlatformCaps.none;
        return res;
    }

    override @property inout(Screen) defaultScreen() inout
    {
        return null;
    }

    override @property inout(Screen)[] screens() inout
    {
        return [];
    }

    override PlatformWindow createWindow(Window window)
    {
        return new Win32Window(window);
    }

    override void processNextEvent()
    {
		MSG msg;
		if (GetMessage(&msg, null, 0, 0) > 0)
        {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
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
		wc.style         = 0;
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


	private Win32Window findWithHWnd(HWND hWnd)
	{
		Win32Window *w = (hWnd in _windows);
		return w ? *w : null;
	}


    private LRESULT wndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam, out LRESULT res)
	{
		res = 0;

		Win32Window wnd = findWithHWnd(hWnd);
		if (!wnd) {
			return false;
		}

		switch(msg)
		{
			case WM_CLOSE:
				return wnd.handleClose();
			case WM_PAINT:
            case WM_ERASEBKGND:
				return wnd.handlePaint(msg, wParam, lParam);
			case WM_SIZE:
			    return wnd.handleResize(msg, wParam, lParam);
			case WM_MOVE:
			    return wnd.handleMove(msg, wParam, lParam);
			case WM_SHOWWINDOW:
			    return wnd.handleShow(msg, wParam, lParam);
            case WM_LBUTTONDOWN:
            case WM_LBUTTONUP:
            case WM_MBUTTONDOWN:
            case WM_MBUTTONUP:
            case WM_RBUTTONDOWN:
            case WM_RBUTTONUP:
            case WM_MOUSEMOVE:
            case WM_MOUSELEAVE:
                return wnd.handleMouse(msg, wParam, lParam);
            case WM_KEYDOWN:
            case WM_KEYUP:
            case WM_CHAR:
                return wnd.handleKey(msg, wParam, lParam);
			default:
				return false;
		}
    }

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
