module dgt.platform.win32.window;

version(Windows):

import dgt.gfx.geometry;
import dgt.input.keys;
import dgt.input.mouse;
import dgt.platform;
import dgt.platform.event;
import dgt.platform.win32;
import dgt.window;
import gfx.core.rc;

import core.sys.windows.windows;
import std.exception : enforce;
import std.utf : toUTF16z;

/// Win32 window implementation
class Win32Window : PlatformWindow
{
    private Window _win;
    private HWND _hWnd;
    private IRect _rect;
    private WindowState _state;
    private bool _shownOnce;
    private bool _paintEvPackage;
    private bool _sentFstResize;
    private bool _sentFstShow;
    private bool _mouseOut;
    private IPoint _mousePos;
    private MouseState _mouseState;

    this(Window w)
    {
        _win = w;
    }

    override inout(Window) window() inout
    {
        return _win;
    }

    override bool created() const
    {
        return _hWnd !is null;
    }

    override void create()
    {
        import std.conv : to;

        wstring clsName = Win32Platform.instance.registerWindowClass(_win);
		HINSTANCE hInstance = GetModuleHandle(null);

		auto g = _win.rect;
		immutable useG = (g.area != 0);

		_hWnd = CreateWindowEx(
					WS_EX_CLIENTEDGE,
					clsName.toUTF16z,
					_win.title.toUTF16z,
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

    override @property size_t nativeHandle() const
    {
        return cast(size_t)_hWnd;
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

    override void setTitle(in string title)
    {
        SetWindowText(_hWnd, title.toUTF16z);
    }

    override @property WindowState state() const
    {
        return _state;
    }

    override void setState(in WindowState state)
    {
        if (_win.flags & WindowFlags.dummy) return;

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

    override @property IRect rect() const
    {
        return _rect;
    }

    override void setRect(in IRect rect)
    {
		RECT r = rectToWin32(rect);
		AdjustWindowRectEx(&r, style, false, exStyle);

		MoveWindow(_hWnd, r.left, r.top, r.right-r.left, r.bottom-r.top, true);
    }

    package
    {

        @property HWND handle()
        {
            return _hWnd;
        }

        bool handleClose(void delegate(PlEvent) collector)
        {
            auto ev = new PlCloseRequestEvent(_win);
            collector(ev);
            return true;
        }

		bool handlePaint(UINT msg, WPARAM /+wParam+/, LPARAM /+lParam+/, void delegate(PlEvent) collector)
		{
            if (!_paintEvPackage) {
                handlePaintEvPackage(collector);
            }
			if (!GetUpdateRect(_hWnd, null, false)) return false;
            if (msg == WM_ERASEBKGND) return true;
            if (this.rect.area == 0) return true;

            immutable r = IRect(0, 0, this.rect.size);

			auto ev = new PlExposeEvent(_win, r);
			collector(ev);

            immutable wr = rectToWin32(r);
            ValidateRect(_hWnd, &wr);

			return true;
		}

        bool handleMove(UINT /+msg+/, WPARAM /+wParam+/, LPARAM /+lParam+/, void delegate(PlEvent) collector)
        {
            if (!IsIconic(_hWnd)) // do not fire when minimized
            {
                handleGeometryChange(collector);
            }
            return true;
        }

        bool handleResize(UINT /+msg+/, WPARAM wParam, LPARAM /+lParam+/, void delegate(PlEvent) collector)
        {
            switch (wParam)
            {
                case SIZE_MAXSHOW:
                case SIZE_MAXHIDE:
                    return false;
                case SIZE_MINIMIZED:
                    handleWindowStateChange(WindowState.minimized, collector);
                    return true;
                case SIZE_MAXIMIZED:
                    handleWindowStateChange(WindowState.maximized, collector);
                    handleGeometryChange(collector);
                    return true;
                case SIZE_RESTORED:
                    handleWindowStateChange(WindowState.normal, collector);
                    handleGeometryChange(collector);
                    return true;
                default:
                    return false;
            }
        }

        void handleGeometryChange(void delegate(PlEvent) collector)
        {
            immutable oldG = rect;
            immutable g = sysRect;

            _rect = g;

            if (g.size != oldG.size) {
                auto ev = new PlResizeEvent(_win, g.size);
                collector(ev);
                _sentFstResize = true;
            }
            if (g.point != oldG.point) {
                auto ev = new PlMoveEvent(_win, g.point);
                collector(ev);
            }

            InvalidateRect(_hWnd, null, true);
        }

        bool handleShow(UINT msg, WPARAM wParam, LPARAM lParam, void delegate(PlEvent) collector)
        {
            if (lParam) return false; // only handle calls subsequent to ShowWindow

            if (wParam) {
                auto ev = new PlShowEvent(_win);
                collector(ev);
                _sentFstShow = true;
            }
            else {
                auto ev = new PlHideEvent(_win);
                collector(ev);
            }
            return true;
        }


        bool handleMouse(UINT msg, WPARAM wParam, LPARAM lParam, void delegate(PlEvent) collector)
        {
            PlEventType t;
            auto pos = IPoint(GET_X_LPARAM(lParam),
                              GET_Y_LPARAM(lParam));
            auto but = MouseButton.none;
            immutable mods = keyMods();

            switch (msg)
            {
            case WM_LBUTTONDOWN:
                but = MouseButton.left;
                t = PlEventType.mouseDown;
                _mouseState |= MouseState.left;
                break;
            case WM_MBUTTONDOWN:
                but = MouseButton.middle;
                t = PlEventType.mouseDown;
                _mouseState |= MouseState.middle;
                break;
            case WM_RBUTTONDOWN:
                but = MouseButton.right;
                t = PlEventType.mouseDown;
                _mouseState |= MouseState.right;
                break;
            case WM_LBUTTONUP:
                but = MouseButton.left;
                t = PlEventType.mouseUp;
                _mouseState &= ~MouseState.left;
                break;
            case WM_MBUTTONUP:
                but = MouseButton.middle;
                t = PlEventType.mouseUp;
                _mouseState &= ~MouseState.middle;
                break;
            case WM_RBUTTONUP:
                but = MouseButton.right;
                t = PlEventType.mouseUp;
                _mouseState &= ~MouseState.right;
                break;
            case WM_MOUSEMOVE: {
                if (_mouseOut)
                {
                    _mouseOut = false;

                    // mouse was out: deliver enter event
                    auto ev = new PlMouseEvent(
                        PlEventType.mouseEnter, _win, pos, MouseButton.none,
                        _mouseState, mods
                    );
                    collector(ev);

                    // and register for leave event
                    TRACKMOUSEEVENT tm;
                    tm.cbSize = TRACKMOUSEEVENT.sizeof;
                    tm.dwFlags = TME_LEAVE;
                    tm.hwndTrack = _hWnd;
                    tm.dwHoverTime = 0;
                    TrackMouseEvent(&tm);
                }
                t = PlEventType.mouseMove;
                _mousePos = pos;
                break;
            }
            case WM_MOUSELEAVE: {
                _mouseOut = true;
                pos = _mousePos;
                t = PlEventType.mouseLeave;
                break;
            }
            default:
                break;
            }
            {
                auto ev = new PlMouseEvent(
                    t, _win, pos, but, _mouseState, mods
                );
                collector(ev);
            }
            return true;
        }

        bool handleKey(UINT msg, WPARAM wParam, LPARAM lParam, void delegate(PlEvent) collector)
        {
            import dgt.platform.win32.keymap : getKeysym, getKeycode;
            import std.conv : to;

            assert(msg != WM_CHAR,
                   "Char msg must be intercepted before delivery!");
            assert(msg == WM_KEYDOWN || msg == WM_KEYUP,
                   "current code assumes either keydown or keyup");
            if (wParam < 0 || wParam >= 256) {
                dgtW32Log.warningf("key %s received a virtual key out of byte boundary: %s",
                         msg == WM_KEYDOWN?"down":"up", wParam);
                return false;
            }

            immutable sym = getKeysym(wParam);
            immutable scancode = cast(ubyte)((lParam & scanCodeMask) >> 16);
            immutable code = getKeycode(scancode);

            if (msg == WM_KEYDOWN)
            {
                immutable text = peekCharMsg();
                immutable repeat = ((lParam & previousStateMask) != 0);
                immutable repeatCount = lParam & repeatCountMask;

                auto ev = new PlKeyEvent(
                    PlEventType.keyDown, _win, sym, code, keyMods,
                    text.to!string, scancode, cast(uint)wParam, repeat, repeatCount
                );
                collector(ev);
            }
            else
            {
                auto ev = new PlKeyEvent(
                    PlEventType.keyUp, _win, sym, code, keyMods,
                    "", scancode, cast(uint)wParam
                );
                collector(ev);
            }

            return true;
        }


        void handleWindowStateChange(WindowState ws, void delegate(PlEvent) collector)
        {
            auto ev = new PlStateChangeEvent(_win, ws);
            collector(ev);
        }
    }

    private
    {
        enum uint previousStateMask = 0x40000000;
        enum uint repeatCountMask = 0x0000ffff;
        enum uint scanCodeMask = 0x00ff0000;

        @property int style() const
        {
            return cast(int)GetWindowLongPtr(cast(HWND)_hWnd, GWL_STYLE);
        }

        @property void style(in int s)
        {
            SetWindowLongPtr(_hWnd, GWL_STYLE, s);
        }

        @property int exStyle() const
        {
            return cast(int)GetWindowLongPtr(cast(HWND)_hWnd, GWL_EXSTYLE);
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

        @property IRect sysRect()
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
                import std.exception : assumeUnique;
                return assumeUnique(str);
            }
            return "";
        }

        void handlePaintEvPackage(void delegate(PlEvent) collector)
        {
            immutable state = sysState;
            immutable rect = sysRect;

            immutable stateCond = state != WindowState.hidden && state != WindowState.minimized;
            immutable rectCond = rect.area != 0;

            if (!_sentFstShow && stateCond) {
                auto ev = new PlShowEvent(_win);
                collector(ev);
            }
            if (!_sentFstResize && rectCond) {
                handleGeometryChange(collector);
            }

            if (stateCond && rectCond) _paintEvPackage = true;
        }
    }
}


IRect rectFromWin32(in RECT r) pure
{
    return IRect(r.left, r.top, r.right-r.left, r.bottom-r.top);
}

RECT rectToWin32(in IRect r) pure
{
    return RECT(r.point.x, r.point.y, r.point.x+r.width, r.point.y+r.height);
}

int GET_X_LPARAM(LPARAM lp) pure
{
    return cast(int)(lp & 0x0000ffff);
}

int GET_Y_LPARAM(LPARAM lp) pure
{
    return cast(int)((lp & 0xffff0000) >> 16);
}

@property KeyMods keyMods()
{
    KeyMods mods = KeyMods.none;

    if (GetKeyState(VK_LSHIFT) & 0x8000) mods |= KeyMods.leftShift;
    if (GetKeyState(VK_LCONTROL) & 0x8000) mods |= KeyMods.leftCtrl;
    if (GetKeyState(VK_LMENU) & 0x8000) mods |= KeyMods.leftAlt;
    if (GetKeyState(VK_LWIN) & 0x8000) mods |= KeyMods.leftSuper;

    if (GetKeyState(VK_RSHIFT) & 0x8000) mods |= KeyMods.rightShift;
    if (GetKeyState(VK_RCONTROL) & 0x8000) mods |= KeyMods.rightCtrl;
    if (GetKeyState(VK_RMENU) & 0x8000) mods |= KeyMods.rightAlt;
    if (GetKeyState(VK_RWIN) & 0x8000) mods |= KeyMods.rightSuper;

    return mods;
}
