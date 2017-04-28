module dgt.platform.xcb;

version(linux):

import dgt.platform.xcb.keyboard;
import dgt.platform.xcb.screen;
import dgt.platform.xcb.window;
import dgt.platform.xcb.context;
import dgt.platform;
import dgt.window;
import dgt.context;
import dgt.screen;
import dgt.geometry;
import dgt.enums;
import dgt.event;
import dgt.image;
import key = dgt.keys;

import xcb.xcb;
import xcb.xkb;
import xcb.dri2;
import xcb.dri3;
import X11.Xlib;
import X11.Xlib_xcb;
import derelict.opengl3.gl3;

import std.exception : enforce;
import std.string : toStringz;
import std.typecons : scoped;
import std.experimental.logger;
import core.stdc.stdlib : free;
import std.stdio;

alias Window = dgt.window.Window;
alias Screen = dgt.screen.Screen;

package
{
    __gshared Display* g_display;
    __gshared xcb_connection_t* g_connection;
}

/// List of X atoms that are fetched automatically
enum Atom
{
    UTF8_STRING,

    WM_PROTOCOLS,
    WM_DELETE_WINDOW,
    WM_TRANSIENT_FOR,
    WM_CHANGE_STATE,
    WM_STATE,
    _NET_WM_STATE,
    _NET_WM_STATE_MODAL,
    _NET_WM_STATE_STICKY,
    _NET_WM_STATE_MAXIMIZED_VERT,
    _NET_WM_STATE_MAXIMIZED_HORZ,
    _NET_WM_STATE_SHADED,
    _NET_WM_STATE_SKIP_TASKBAR,
    _NET_WM_STATE_SKIP_PAGER,
    _NET_WM_STATE_HIDDEN,
    _NET_WM_STATE_FULLSCREEN,
    _NET_WM_STATE_ABOVE,
    _NET_WM_STATE_BELOW,
    _NET_WM_STATE_DEMANDS_ATTENTION,
    _NET_WM_STATE_FOCUSED,
    _NET_WM_NAME,
}

/// get the response_type field masked for
@property ubyte xcbEventType(EvT)(EvT* e)
{
    return (e.response_type & ~0x80);
}

/// Platform for XCB windowing system
class XcbPlatform : Platform
{
    private
    {
        xcb_atom_t[Atom] _atoms;
        XcbKeyboard _kbd;
        uint _xkbFirstEv;
        uint _dri2FirstEv = uint.max;
        uint _dri3FirstEv = uint.max;
        int _defaultScreen;
        Screen[] _screens;
        XcbScreen[] _xcbScreens;
        XcbWindow[xcb_window_t] _windows;
        int _xcbFd;
        int _vsyncReadFd;
        int _vsyncWriteFd;
    }

    /// Builds an XcbPlatform
    this()
    {}

    override void initialize()
    {
        g_display = XOpenDisplay(null);
        enforce(g_display, "can't open X display");
        scope (failure)
            XCloseDisplay(g_display);

        g_connection = XGetXCBConnection(g_display);
        enforce(g_connection, "could not connect to X server");

        // setting event queue owner to XCB actually provoke bug.
        // see http://lists.freedesktop.org/archives/xcb/2015-November/010567.html
        XSetEventQueueOwner(g_display, XCBOwnsEventQueue);

        initializeAtoms();
        initializeScreens();
        _kbd = new XcbKeyboard(g_connection, _xkbFirstEv);
        initializeDRI();
        initializeVG();

        _xcbFd = xcb_get_file_descriptor(g_connection);

        import core.sys.posix.unistd : pipe;
        int[2] pipeFds;
        enforce(pipe(pipeFds) ==0, "could not create pipe");
        _vsyncReadFd = pipeFds[0];
        _vsyncWriteFd = pipeFds[1];

        //import core.sys.posix.fcntl : fcntl, F_GETFL, F_SETFL, O_NONBLOCK;
        //immutable flags = fcntl(_vsyncReadFd, F_GETFL, 0);
        //fcntl(_vsyncReadFd, F_SETFL, flags | O_NONBLOCK);
    }

    override void dispose()
    {
        XCloseDisplay(g_display);
        g_display = null;
        g_connection = null;
    }

    override @property string name() const
    {
        return "xcb";
    }

    override GlContext createGlContext(
                GlAttribs attribs, PlatformWindow window,
                GlContext sharedCtx, Screen screen)
    {
        return createXcbGlContext(attribs, window, sharedCtx, screen);
    }

    override @property inout(Screen) defaultScreen() inout
    {
        return _screens[_defaultScreen];
    }

    override @property inout(Screen)[] screens() inout
    {
        return _screens;
    }

    override PlatformWindow createWindow(Window window)
    {
        return new XcbWindow(window, this);
    }

    override void collectEvents(void delegate(Event) collector)
    {
        while(true) {
            xcb_generic_event_t* e = xcb_poll_for_event(g_connection);
            if (!e) break;
            scope(exit) free(e);
            handleEvent(e, collector);
        }
        xcb_flush(g_connection);
    }

    override void processEvents()
    {
        xcb_generic_event_t* e = xcb_wait_for_event(g_connection);
        scope(exit) {
            free(e);
            xcb_flush(g_connection);
        }
        handleEvent(e, (Event ev) {
            auto wEv = cast(WindowEvent)ev;
            if (wEv) {
                wEv.window.handleEvent(wEv);
            }
        });
    }

    override Wait waitFor(Wait flags)
    {
        import core.sys.posix.poll : poll, pollfd, POLLIN;

        pollfd[2] fds;
        fds[0].fd = (flags & Wait.input) ? _xcbFd : -1;
        fds[0].events = POLLIN;
        fds[1].fd = (flags & Wait.vsync) ? _vsyncReadFd : -1;
        fds[1].events = POLLIN;

        int rc = poll(fds.ptr, 2, -1);
        if (rc == -1) {
            import core.stdc.errno : errno, EINVAL, EFAULT, EINTR, ENOMEM;
            string msg;
            switch(errno) {
            case EINVAL:
                msg = "EINVAL";
                break;
            case EFAULT:
                msg = "EFAULT";
                break;
            case EINTR:
                msg = "EINTR";
                break;
            case ENOMEM:
                msg = "ENOMEM";
                break;
            default:
                msg = "(unknown)";
                break;
            }
            throw new Exception("poll error: "~msg);
        }

        Wait res = Wait.none;
        if (fds[0].revents & POLLIN) {
            res |= Wait.input;
        }
        if (fds[1].revents & POLLIN) {
            res |= Wait.vsync;
            import core.sys.posix.unistd : read;
            ubyte[8] buf;
            read(_vsyncReadFd, cast(void*)buf.ptr, 8);
        }
        return res;
    }

    override void vsync()
    {
        import core.sys.posix.unistd : write;
        ubyte[4] buf;
        write(_vsyncWriteFd, cast(const(void*))buf.ptr, 4);
    }

    private void handleEvent(xcb_generic_event_t* e, void delegate(Event) collector)
    {
        immutable xcbType = xcbEventType(e);

        switch (xcbType)
        {
        case XCB_KEY_PRESS:
        case XCB_KEY_RELEASE:
            processKeyEvent(cast(xcb_key_press_event_t*)e, collector);
            break;
        case XCB_BUTTON_PRESS:
        case XCB_BUTTON_RELEASE:
            processWindowEvent!(xcb_button_press_event_t, "processButtonEvent")(e, collector);
            break;
        case XCB_MOTION_NOTIFY:
            processWindowEvent!(xcb_motion_notify_event_t, "processMotionEvent")(e, collector);
            break;
        case XCB_ENTER_NOTIFY:
        case XCB_LEAVE_NOTIFY:
            processWindowEvent!(xcb_enter_notify_event_t, "processEnterLeaveEvent")(e, collector);
            break;
        case XCB_UNMAP_NOTIFY:
            processWindowEvent!(xcb_unmap_notify_event_t, "processUnmapEvent")(e, collector);
            break;
        case XCB_MAP_NOTIFY:
            processWindowEvent!(xcb_map_notify_event_t, "processMapEvent")(e, collector);
            break;
        case XCB_CONFIGURE_NOTIFY:
            processWindowEvent!(xcb_configure_notify_event_t, "processConfigureEvent")(e, collector);
            break;
        case XCB_PROPERTY_NOTIFY:
            processWindowEvent!(xcb_property_notify_event_t, "processPropertyEvent", "window")(e, collector);
            break;
        case XCB_CLIENT_MESSAGE:
            processClientEvent(cast(xcb_client_message_event_t*)e, collector);
            break;
        case XCB_EXPOSE:
            processWindowEvent!(xcb_expose_event_t, "processExposeEvent", "window")(e, collector);
            break;
        default:
            if (xcbType == _xkbFirstEv)
            {
                auto genKbd = cast(XkbGenericEvent*)e;
                if (genKbd.common.deviceID == _kbd.device)
                {
                    switch (genKbd.common.xkbType)
                    {
                    case XCB_XKB_STATE_NOTIFY:
                        _kbd.updateState(&genKbd.state);
                        break;
                    default:
                        break;
                    }
                }
            }
            if (xcbType == _dri2FirstEv || xcbType == _dri2FirstEv + 1)
            {
                // these are libGL DRI2 event that need special handling
                // see https://bugs.freedesktop.org/show_bug.cgi?id=35945#c4
                // and mailing thread starting here:
                // http://lists.freedesktop.org/archives/xcb/2015-November/010556.html
                WireToEventProc proc = XESetWireToEvent(g_display, xcbType, null);
                if (proc)
                {
                    XESetWireToEvent(g_display, xcbType, proc);
                    e.sequence = cast(ushort)XLastKnownRequestProcessed(g_display);
                    XEvent dummy;
                    proc(g_display, &dummy, cast(xEvent*)e);
                }
            }
            break;
        }

    }

    package
    {

        @property bool hasDRI2() const
        {
            return _dri2FirstEv != uint.max;
        }

        @property bool hasDRI3() const
        {
            return _dri3FirstEv != uint.max;
        }

        @property inout(XcbScreen) defaultXcbScreen() inout
        {
            return _xcbScreens[_defaultScreen];
        }

        @property inout(XcbScreen)[] xcbScreens() inout
        {
            return _xcbScreens;
        }

        xcb_format_t* formatForDepth(ubyte depth)
        {
            auto iter = xcb_setup_pixmap_formats_iterator(
                xcb_get_setup(g_connection)
            );
            while(iter.rem)
            {
                auto format = iter.data;
                if (format.depth == depth)
                {
                    return format;
                }
                xcb_format_next(&iter);
            }
            return null;
        }

        inout(XcbWindow) xcbWindow(xcb_window_t xcbWin) inout
        {
            inout(XcbWindow)* w = xcbWin in _windows;
            if (!w)
                return null;
            return *w;
        }

        inout(Window) window(xcb_window_t xcbWin) inout
        {
            inout(XcbWindow) xcbW = xcbWindow(xcbWin);
            if (!xcbW)
                return null;
            return xcbW.window;
        }

        void registerWindow(XcbWindow w)
        {
            _windows[w.xcbWin] = w;
        }

        xcb_atom_t atom(Atom atom) const
        {
            auto at = (atom in _atoms);
            if (at)
                return *at;
            return XCB_ATOM_NONE;
        }
    }

    private
    {
        void initializeAtoms()
        {
            import std.traits : EnumMembers;
            import std.conv : to;

            xcb_intern_atom_cookie_t[] cookies;

            foreach (immutable atom; EnumMembers!Atom) // static foreach
            {
                auto name = atom.to!string;
                cookies ~= xcb_intern_atom(g_connection, 1,
                        cast(ushort)name.length, toStringz(name));
            }

            foreach (i, immutable atom; EnumMembers!Atom) // static foreach
            {
                immutable name = atom.to!string;
                xcb_generic_error_t* err;
                auto reply = xcb_intern_atom_reply(g_connection, cookies[i], &err);
                if (err)
                {
                    throw new Exception("failed initializing atom " ~ name ~ ": ",
                            (*err).to!string);
                }
                if (reply.atom == XCB_ATOM_NONE)
                {
                    throw new Exception("could not retrieve atom " ~ name);
                }
                _atoms[atom] = reply.atom;
                free(reply);
            }
        }

        void initializeScreens()
        {
            import std.algorithm : map;
            import std.array : array;

            _defaultScreen = XDefaultScreen(g_display);
            _xcbScreens = fetchScreens();
            _screens = _xcbScreens.map!(s => cast(Screen)s).array();
            enforce(_defaultScreen < _screens.length);
        }

        XcbScreen[] fetchScreens()
        {
            XcbScreen[] screens;
            xcb_screen_iterator_t iter;
            int num = 0;
            for (iter = xcb_setup_roots_iterator(xcb_get_setup(g_connection)); iter.rem;
                    xcb_screen_next(&iter))
            {
                screens ~= new XcbScreen(num++, iter.data);
            }
            return screens;
        }

        void initializeDRI()
        {
            {
                xcb_prefetch_extension_data(g_connection, &xcb_dri2_id);

                const reply = xcb_get_extension_data(g_connection, &xcb_dri2_id);
                if (reply && reply.present)
                    _dri2FirstEv = reply.first_event;
            }
            {
                xcb_prefetch_extension_data(g_connection, &xcb_dri3_id);

                const reply = xcb_get_extension_data(g_connection, &xcb_dri3_id);
                if (reply && reply.present)
                    _dri3FirstEv = reply.first_event;
            }
        }

        void initializeVG()
        {
            import xcb.shm : xcb_shm_id;
            {
                xcb_prefetch_extension_data(g_connection, &xcb_shm_id);

                const reply = xcb_get_extension_data(g_connection, &xcb_shm_id);
                enforce(reply && reply.present, "XCB-SHM extension is not found");
            }
        }

        void processWindowEvent(SpecializedEvent, string processingMethod, string seField = "event")(
                xcb_generic_event_t* xcbEv, void delegate(Event) collector)
        {
            auto se = cast(SpecializedEvent*)xcbEv;
            auto xcbWin = xcbWindow(mixin("se." ~ seField));
            mixin("xcbWin." ~ processingMethod ~ "(se, collector);");
        }

        void processKeyEvent(xcb_key_press_event_t* xcbEv, void delegate(Event) collector)
        {
            auto xcbWin = xcbWindow(xcbEv.event);
            _kbd.processEvent(xcbEv, xcbWin.window, collector);
        }

        void processClientEvent(xcb_client_message_event_t* xcbEv, void delegate(Event) collector)
        {
            if (xcbEv.data.data32[0] == atom(Atom.WM_DELETE_WINDOW))
            {
                auto w = window(xcbEv.window);
                collector(new CloseEvent(w));
            }
        }
    }
}

key.Mods dgtKeyMods(in ushort xcbState) pure @nogc @safe nothrow
{
    key.Mods km;
    if (xcbState & XCB_MOD_MASK_SHIFT)
        km |= key.Mods.shift;
    if (xcbState & XCB_MOD_MASK_CONTROL)
        km |= key.Mods.ctrl;
    if (xcbState & XCB_MOD_MASK_1)
        km |= key.Mods.alt;
    if (xcbState & XCB_MOD_MASK_2)
        km |= key.Mods.super_;
    return km;
}

MouseState dgtMouseState(in ushort xcbState) pure @nogc @safe nothrow
{
    MouseState state;
    if (xcbState & XCB_BUTTON_MASK_1)
        state |= MouseState.left;
    if (xcbState & XCB_BUTTON_MASK_2)
        state |= MouseState.middle;
    if (xcbState & XCB_BUTTON_MASK_3)
        state |= MouseState.right;
    return state;
}

MouseButton dgtMouseButton(in xcb_button_t xcbBut) pure @nogc @safe nothrow
{
    switch (xcbBut)
    {
    case 1:
        return MouseButton.left;
    case 2:
        return MouseButton.middle;
    case 3:
        return MouseButton.right;
    default:
        return MouseButton.none;
    }
}

ImageFormat dgtImageFormat(in xcb_format_t* fmt)
{
    switch (fmt.bits_per_pixel)
    {
    case 1:
        return ImageFormat.a1;
    case 8:
        return ImageFormat.a8;
    case 32:
        if (fmt.depth == 24)
        {
            return ImageFormat.xrgb;
        }
        else if (fmt.depth == 32)
        {
            return ImageFormat.argbPremult;
        }
        break;
    default:
        break;
    }
    throw new Exception("DGT-XCB - Unsupported image format");
}

private
{

    union XkbGenericEvent
    {

        struct CommonFields
        {
            ubyte response_type;
            ubyte xkbType;
            ushort sequence;
            xcb_timestamp_t time;
            ubyte deviceID;
        }

        CommonFields common;
        xcb_xkb_new_keyboard_notify_event_t newKbd;
        xcb_xkb_map_notify_event_t map;
        xcb_xkb_state_notify_event_t state;
    }

    extern (C)
    {
        // necessary binding to xlib internals

        struct xEvent;

        alias WireToEventProc = Bool function(Display*, XEvent*, xEvent*);

        WireToEventProc XESetWireToEvent(Display* display, int event_number, WireToEventProc proc);

    }

}
