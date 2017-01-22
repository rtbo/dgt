module dgt.platform.win32.window;

version(Windows):

import dgt.platform.win32;
import dgt.platform;
import dgt.window;
import dgt.geometry;
import dgt.event;
import dgt.vg;
import dgt.enums;
import key = dgt.keys;

import std.utf : toUTF16z;
import std.typecons : scoped;
import std.experimental.logger;
import core.sys.windows.windows;

/// Win32 window implementation
class Win32Window : PlatformWindow
{
    private Window _win;
    private HWND _hWnd;
    private IRect _rect;
    private WindowState _state;
    private bool _shownOnce;
    private bool _mouseOut;
    private IPoint _mousePos;
    private MouseState _mouseState;

    this(Window w)
    {
        _win = w;
    }

    override bool created() const
    {
        return _hWnd !is null;
    }

    override void create(WindowState state)
    {
        import std.conv : to;

        wstring clsName = Win32Platform.instance.registerWindowClass(_win);
		HINSTANCE hInstance = GetModuleHandle(null);

		auto g = _win.geometry;
		immutable useG = (g.area != 0);

		_hWnd = CreateWindowEx(
					WS_EX_CLIENTEDGE,
					clsName.toUTF16z,
					"".toUTF16z,
					WS_OVERLAPPEDWINDOW,
					useG ? g.point.x : CW_USEDEFAULT,
					useG ? g.point.y : CW_USEDEFAULT,
					useG ? g.width : CW_USEDEFAULT,
					useG ? g.height : CW_USEDEFAULT,
					null, null, hInstance, null);

		if (_hWnd is null) {
			throw new Exception("Win32 window could not be created from class "~clsName.to!string);
		}

        _state = WindowState.hidden;

		Win32Platform.instance.registerWindow(_hWnd, this);
    }

    override void close()
    {
		DestroyWindow(_hWnd);
		Win32Platform.instance.unregisterWindow(_hWnd);
    }

    override @property string title() const
    {
        import std.conv : to;

        wchar[512] buf;
        auto len = GetWindowText(cast(HWND)_hWnd, buf.ptr, 512);
        return buf[0 .. len].to!string;
    }

    override @property void title(string title)
    {
        SetWindowText(_hWnd, title.toUTF16z);
    }

    override @property WindowState state() const
    {
        return _state;
    }

    override @property void state(WindowState state)
    {
        final switch(state)
        {
        case WindowState.normal:
            ShowWindow(_hWnd, _shownOnce ? SW_SHOW : SW_SHOWDEFAULT);
            break;
        case WindowState.minimized:
            ShowWindow(_hWnd, SW_SHOWMINIMIZED);
            break;
        case WindowState.maximized:
            ShowWindow(_hWnd, SW_SHOWMAXIMIZED);
            break;
        case WindowState.hidden:
            ShowWindow(_hWnd, SW_HIDE);
            break;
        case WindowState.fullscreen:
            assert(false, "unimplemented");
        }
        _shownOnce = true;
    }

    override @property IRect geometry() const
    {
        return _rect;
    }

    override @property void geometry(IRect rect)
    {
		RECT r = rectToWin32(rect);
		AdjustWindowRectEx(&r, style, false, exStyle);

		MoveWindow(_hWnd, r.left, r.top, r.right-r.left, r.bottom-r.top, true);
    }

    override @property VgSurface surface()
    {
        return null;
    }

    package
    {
        bool handleMove(UINT /+msg+/, WPARAM /+wParam+/, LPARAM /+lParam+/)
        {
            if (!IsIconic(_hWnd)) // do not fire when minimized
            {
                handleGeometryChange();
            }
            return true;
        }

        bool handleResize(UINT /+msg+/, WPARAM wParam, LPARAM /+lParam+/)
        {
            switch (wParam)
            {
                case SIZE_MAXSHOW:
                case SIZE_MAXHIDE:
                    return false;
                case SIZE_MINIMIZED:
                    handleWindowStateChange(WindowState.minimized);
                    return true;
                case SIZE_MAXIMIZED:
                    handleWindowStateChange(WindowState.maximized);
                    handleGeometryChange();
                    return true;
                case SIZE_RESTORED:
                    handleWindowStateChange(WindowState.normal);
                    handleGeometryChange();
                    return true;
                default:
                    return false;
            }
        }

        void handleGeometryChange()
        {
            immutable oldG = geometry;
            immutable g = sysGeometry;

            _rect = g;

            if (g.size != oldG.size) {
                auto ev = scoped!WindowResizeEvent(_win, g.size);
                _win.handleEvent(ev);
            }
            if (g.point != oldG.point) {
                auto ev = scoped!WindowMoveEvent(_win, g.point);
                _win.handleEvent(ev);
            }

            InvalidateRect(_hWnd, null, true);
        }

        bool handleShow(UINT msg, WPARAM wParam, LPARAM lParam)
        {
            if (lParam) return false; // only handle calls subsequent to ShowWindow

            if (wParam) {
                auto ev = scoped!WindowShowEvent(_win);
                _win.handleEvent(ev);
            }
            else {
                auto ev = scoped!WindowHideEvent(_win);
                _win.handleEvent(ev);
            }
            return true;
        }


        bool handleMouse(UINT msg, WPARAM wParam, LPARAM lParam)
        {
            EventType t;
            auto pos = IPoint(GET_X_LPARAM(lParam),
                              GET_Y_LPARAM(lParam));
            auto but = MouseButton.none;
            immutable mods = keyMods();

            switch (msg)
            {
            case WM_LBUTTONDOWN:
                but = MouseButton.left;
                t = EventType.windowMouseDown;
                _mouseState |= MouseState.left;
                break;
            case WM_MBUTTONDOWN:
                but = MouseButton.middle;
                t = EventType.windowMouseDown;
                _mouseState |= MouseState.middle;
                break;
            case WM_RBUTTONDOWN:
                but = MouseButton.right;
                t = EventType.windowMouseDown;
                _mouseState |= MouseState.right;
                break;
            case WM_LBUTTONUP:
                but = MouseButton.left;
                t = EventType.windowMouseUp;
                _mouseState &= ~MouseState.left;
                break;
            case WM_MBUTTONUP:
                but = MouseButton.middle;
                t = EventType.windowMouseUp;
                _mouseState &= ~MouseState.middle;
                break;
            case WM_RBUTTONUP:
                but = MouseButton.right;
                t = EventType.windowMouseUp;
                _mouseState &= ~MouseState.right;
                break;
            case WM_MOUSEMOVE: {
                if (_mouseOut)
                {
                    _mouseOut = false;

                    // mouse was out: deliver enter event
                    auto ev = scoped!WindowMouseEvent(
                        EventType.windowMouseEnter, _win, pos, MouseButton.none,
                        _mouseState, mods
                    );
                    _win.handleEvent(ev);

                    // and register for leave event
                    TRACKMOUSEEVENT tm;
                    tm.cbSize = TRACKMOUSEEVENT.sizeof;
                    tm.dwFlags = TME_LEAVE;
                    tm.hwndTrack = _hWnd;
                    tm.dwHoverTime = 0;
                    TrackMouseEvent(&tm);
                }
                t = EventType.windowMouseMove;
                _mousePos = pos;
                break;
            }
            case WM_MOUSELEAVE: {
                _mouseOut = true;
                pos = _mousePos;
                t = EventType.windowMouseLeave;
                break;
            }
            default:
                break;
            }
            {
                auto ev = scoped!WindowMouseEvent(
                    t, _win, pos, but, _mouseState, mods
                );
                _win.handleEvent(ev);
            }
            return true;
        }

        bool handleKey(UINT msg, WPARAM wParam, LPARAM lParam)
        {
            assert(msg != WM_CHAR,
                   "Char msg must be intercepted before delivery!");
            assert(msg == WM_KEYDOWN || msg == WM_KEYUP,
                   "current code assumes either keydown or keyup");
            if (wParam < 0 || wParam >= 256) {
                warningf("key %s received a virtual key out of byte boundary: %s",
                         msg == WM_KEYDOWN?"down":"up", wParam);
                return false;
            }

            return true;
        }


        void handleWindowStateChange(WindowState ws)
        {
            auto ev = scoped!WindowStateChangeEvent(_win, ws);
            _win.handleEvent(ev);
        }


    }

    private
    {
        enum uint previousStateMask = 0x40000000;
        enum uint repeatCountMask = 0x0000ffff;
        enum uint scanCodeMask = 0x00ff0000;

        @property int style() const
        {
            return GetWindowLongPtr(cast(HWND)_hWnd, GWL_STYLE);
        }

        @property void style(in int s)
        {
            SetWindowLongPtr(_hWnd, GWL_STYLE, s);
        }

        @property int exStyle() const
        {
            return GetWindowLongPtr(cast(HWND)_hWnd, GWL_EXSTYLE);
        }

        @property void exStyle(in int s)
        {
            SetWindowLongPtr(_hWnd, GWL_EXSTYLE, s);
        }

        @property WindowState sysState()
        {
            if (!IsWindowVisible(_hWnd))
            {
                return WindowState.hidden;
            }
            if (IsIconic(_hWnd))
            {
                return WindowState.minimized;
            }
            if (IsZoomed(_hWnd))
            {
                return WindowState.maximized;
            }

            return WindowState.normal;
        }

        @property IRect sysGeometry()
        {
            auto wr = RECT(0, 0, 0, 0);
            GetWindowRect(_hWnd, &wr);

            auto ar = RECT(0, 0, 0, 0);
            AdjustWindowRectEx(&ar, style, false, exStyle);

            wr.left -= ar.left;
            wr.top -= ar.top;
            wr.right -= ar.right;
            wr.bottom -= ar.bottom;

            return rectFromWin32(wr);
        }

        wstring peekCharMsg()
        {
            MSG msg;
            if (PeekMessage(&msg, _hWnd, WM_CHAR, WM_CHAR, PM_REMOVE))
            {
                immutable auto count = msg.lParam & repeatCountMask;
                auto str = new wchar[count];
                str[] = cast(wchar)msg.wParam;
                return str.idup;
            }
            return "";
        }

        static IRect rectFromWin32(in RECT r) pure
        {
            return IRect(r.left, r.top, r.right-r.left, r.bottom-r.top);
        }

        static RECT rectToWin32(in IRect r) pure
        {
            return RECT(r.point.x, r.point.y, r.point.x+r.width, r.point.y+r.height);
        }

        static int GET_X_LPARAM(LPARAM lp) pure
        {
            return cast(int)(lp & 0x0000ffff);
        }

        static int GET_Y_LPARAM(LPARAM lp) pure
        {
            return cast(int)((lp & 0xffff0000) >> 16);
        }

        static @property key.Mods keyMods()
        {
            key.Mods mods = key.Mods.none;

            if (GetKeyState(VK_LSHIFT) & 0x8000) mods |= key.Mods.leftShift;
            if (GetKeyState(VK_LCONTROL) & 0x8000) mods |= key.Mods.leftCtrl;
            if (GetKeyState(VK_LMENU) & 0x8000) mods |= key.Mods.leftAlt;
            if (GetKeyState(VK_LWIN) & 0x8000) mods |= key.Mods.leftSuper;

            if (GetKeyState(VK_RSHIFT) & 0x8000) mods |= key.Mods.rightShift;
            if (GetKeyState(VK_RCONTROL) & 0x8000) mods |= key.Mods.rightCtrl;
            if (GetKeyState(VK_RMENU) & 0x8000) mods |= key.Mods.rightAlt;
            if (GetKeyState(VK_RWIN) & 0x8000) mods |= key.Mods.rightSuper;

            return mods;
        }
    }
}
