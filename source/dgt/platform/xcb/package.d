module dgt.platform.xcb;

import dgt.platform.xcb.keyboard;
import dgt.platform.xcb.context;
import dgt.platform;
import dgt.window;
import dgt.screen;
import dgt.geometry;

import xcb.xcb;
import xcb.xkb;
import xcb.xcb_icccm;
import xcb.dri2;
import X11.Xlib;
import X11.Xlib_xcb;
import xkbcommon.x11;
import derelict.opengl3.gl3;

import std.exception : enforce;
import std.string : toStringz;
import std.experimental.logger;
import core.stdc.stdlib : free;

alias Window = dgt.window.Window;
alias Screen = dgt.screen.Screen;

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


/// Platform for XCB windowing system
class XcbPlatform : Platform
{
    private
    {
        Display *dpy_;
        xcb_connection_t *connection_;
        xcb_atom_t[Atom] atoms_;
        XcbKeyboard kbd_;
        uint xkbFirstEv_;
        uint dri2FirstEv_ = uint.max;
        XcbScreen[] screens_;
        XcbWindow[xcb_window_t] windows_;
    }

    /// Builds and initialize XcbPlatform
    this()
    {
        dpy_ = XOpenDisplay(null);
        enforce(dpy_, "can't open X display");
        scope(failure) XCloseDisplay(dpy_);

        connection_ = XGetXCBConnection(dpy_);
        enforce(connection_, "could not connect to X server");

        // setting event queue owner to XCB actually provoke bug.
        // see http://lists.freedesktop.org/archives/xcb/2015-November/010567.html
        XSetEventQueueOwner(dpy_, XCBOwnsEventQueue);

        initializeAtoms();
        screens_ = fetchScreens();
        kbd_ = new XcbKeyboard(connection_, xkbFirstEv_);
        initializeGLX();
    }

    /// Platform implementation
    override void shutdown()
    {
        XCloseDisplay(dpy_);
        dpy_ = null;
        connection_ = null;
    }

    /// ditto
    @property string name() const { return "xcb"; }

    /// ditto
    @property inout(Screen)[] screens() inout
    {
        return cast(inout(Screen)[])screens_;
    }

    /// ditto
    PlatformWindow createWindow(Window window)
    {
        return new XcbWindow(window, this, connection_);
    }

    package
    {
        @property inout(Display)* display() inout
        {
            return dpy_;
        }

        @property inout(xcb_connection_t)* connection() inout
        {
            return connection_;
        }

        @property bool hasDRI2() const { return dri2FirstEv_ != uint.max; }

        @property inout(XcbScreen)[] xcbScreens() inout
        {
            return screens_;
        }

        void registerWindow(XcbWindow w)
        {
            windows_[w.xcbWin] = w;
        }
    }

    private
    {
        void initializeAtoms()
        {
            import std.traits : EnumMembers;
            import std.conv : to;

            xcb_intern_atom_cookie_t[] cookies;

            foreach(immutable atom; EnumMembers!Atom) // static foreach
            {
                auto name = atom.to!string;
                cookies ~= xcb_intern_atom(connection_, 1,
                        cast(ushort)name.length, toStringz(name));
            }

            foreach(i, immutable atom; EnumMembers!Atom) // static foreach
            {
                immutable name = atom.to!string;
                xcb_generic_error_t *err;
                auto reply = xcb_intern_atom_reply(connection_, cookies[i], &err);
                if (err) {
                    throw new Exception("failed initializing atom " ~ name ~
                            ": ", (*err).to!string);
                }
                if (reply.atom == XCB_ATOM_NONE) {
                    throw new Exception("could not retrieve atom " ~ name);
                }
                atoms_[atom] = reply.atom;
                free(reply);
            }
        }

        XcbScreen[] fetchScreens()
        {
            XcbScreen[] screens;
            xcb_screen_iterator_t iter;
            int num = 0;
            for(iter = xcb_setup_roots_iterator(xcb_get_setup(connection_));
                    iter.rem; xcb_screen_next(&iter)) {
                screens ~= new XcbScreen(num++, iter.data);
            }
            return screens;
        }

        void initializeGLX()
        {
            DerelictGL3.load();

            xcb_prefetch_extension_data(connection_, &xcb_dri2_id);

            const reply = xcb_get_extension_data(connection_, &xcb_dri2_id);
            if (reply && reply.present) dri2FirstEv_ = reply.first_event;
        }

        xcb_atom_t atom(Atom atom) const
        {
            auto at = (atom in atoms_);
            if (at) return *at;
            return XCB_ATOM_NONE;
        }
    }
}


/// Xcb implementation of Screen
class XcbScreen : Screen
{
    private int num_;
    private xcb_screen_t s_;

    this(int num, xcb_screen_t *s)
    {
        num_ = num;
        s_ = *s;
    }

    override @property int num() const { return num_; }

    override @property int width() const { return s_.width_in_pixels; }

    override @property int height() const { return s_.height_in_pixels; }

    override @property double dpi() const
    {
        return width / (s_.width_in_millimeters / 25.4);
    }

    @property xcb_window_t root() const { return s_.root; }
    @property ubyte rootDepth() const { return s_.root_depth; }
    @property xcb_visualid_t rootVisual() const { return s_.root_visual; }
    @property uint whitePixel() const { return s_.white_pixel; }
    @property uint blackPixel() const { return s_.black_pixel; }

}


/// Xcb implementation of PlatformWindow
class XcbWindow : PlatformWindow
{
    private
    {
        Window win_;
        XcbPlatform platform_;
        xcb_connection_t *connection_;
        xcb_window_t xcbWin_;
        bool created_ = false;
        WindowState lastKnownState_ = WindowState.hidden;
    }

    this(Window w, XcbPlatform platform, xcb_connection_t *connection)
    {
        win_ = w;
        platform_ = platform;
        connection_ = connection;
    }

    override bool created() const { return created_; }

    override void create(WindowState state)
    {
        const screen = platform_.xcbScreens[0];
        immutable screenNum = screen.num;
        immutable size = creationSize();
        immutable pos = creationPos(screen, size);

        auto visualInfo = getVisualInfoFromAttribs(
                platform_.display, screenNum, win_.attribs
        );
        if (!visualInfo) {
            throw new Exception("Clue-XCB: window could not get visual");
        }
        scope(exit) XFree(visualInfo);

        immutable cmap = xcb_generate_id(connection_);
        xcbWin_ = xcb_generate_id(connection_);

        xcb_create_colormap(connection_, XCB_COLORMAP_ALLOC_NONE,
                cmap, screen.root, visualInfo.visualid);

        immutable mask = XCB_CW_BACK_PIXEL | XCB_CW_COLORMAP;
        uint[] values = [ screen.whitePixel, cmap, 0 ];

        auto cook = xcb_create_window_checked (
                connection_, screen.rootDepth, xcbWin_,
                screen.root, cast(short)pos.x, cast(short)pos.y,
                cast(ushort)size.width, cast(ushort)size.height, 0,
                XCB_WINDOW_CLASS_INPUT_OUTPUT,
                screen.rootVisual, mask, &values[0]);

        auto err = xcb_request_check(connection_, cook);
        if (err) {
            import std.format : format;
            throw new Exception(format(
                "Clue-XCB: could not create window: %s", err.error_code));
        }

        prepareEvents();

        platform_.registerWindow(this);

        this.state = state; // actually show the window
        created_ = true;
    }

    override @property string title() const
    {
        auto conn = cast(xcb_connection_t*)connection_;
        auto c = xcb_get_property(conn, 0, xcbWin_, XCB_ATOM_WM_NAME,
            XCB_ATOM_STRING, 0, 1024);
        auto r = xcb_get_property_reply(conn, c, null);
        if (!r) return "";
        scope(exit) free(r);
        auto len = xcb_get_property_value_length(r);
        return cast(string)(xcb_get_property_value(r)[0 .. len].idup);
    }

    override @property void title(string title)
    {
         xcb_change_property(connection_,
                cast(ubyte)XCB_PROP_MODE_REPLACE, xcbWin_,
                cast(xcb_atom_t)XCB_ATOM_WM_NAME, cast(xcb_atom_t)XCB_ATOM_STRING,
                8, cast(uint)title.length, toStringz(title));
        xcb_change_property(connection_,
                cast(ubyte)XCB_PROP_MODE_REPLACE, xcbWin_,
                cast(xcb_atom_t)XCB_ATOM_WM_ICON_NAME, cast(xcb_atom_t)XCB_ATOM_STRING,
                8, cast(uint)title.length, toStringz(title));
    }

    override @property WindowState state() const
    {
        auto cookie = xcb_get_property_unchecked(
                conn, 0, xcbWin_, atom(Atom.WM_STATE),
                             XCB_ATOM_ANY, 0, 1024);

        auto reply = xcb_get_property_reply(conn, cookie, null);
        if (reply)
        {
            scope(exit) free(reply);
            if (reply.format == 32 && reply.type == atom(Atom.WM_STATE) &&
                    reply.length >= 1)
            {
                auto data = cast(uint*)xcb_get_property_value(reply);
                if (data[0] == XCB_ICCCM_WM_STATE_ICONIC)
                    return WindowState.minimized;
                else if (data[0] == XCB_ICCCM_WM_STATE_WITHDRAWN)
                    return WindowState.hidden;
            }
        }

        const states = netWmStates;

        if (states & NetWmStates.Fullscreen)
            return WindowState.fullscreen;

        if ((states & NetWmStates.Maximized) == NetWmStates.Maximized)
        {
            return WindowState.maximized;
        }

        return WindowState.normal;
    }

    override @property void state(WindowState ws)
    {
        if (lastKnownState_ == ws) return;

        const screen = platform_.xcbScreens[0];

        // removing attribute that makes other than normal

        switch (lastKnownState_)
        {
            case WindowState.maximized:
                changeNetWmState(false,
                    atom(Atom._NET_WM_STATE_MAXIMIZED_HORZ),
                    atom(Atom._NET_WM_STATE_MAXIMIZED_VERT));
                break;
            case WindowState.fullscreen:
                changeNetWmState(false,
                    atom(Atom._NET_WM_STATE_FULLSCREEN));
                break;
            case WindowState.minimized:
            case WindowState.hidden:
                xcb_map_window(connection_, xcbWin_);
                break;
            default:
                break;
        }

        // at this point the window is in normal mode

        switch (ws)
        {
            case WindowState.minimized:
                xcb_client_message_event_t ev;

                ev.response_type = XCB_CLIENT_MESSAGE;
                ev.format = 32;
                ev.window = xcbWin_;
                ev.type = atom(Atom.WM_CHANGE_STATE);
                ev.data.data32[0] = XCB_ICCCM_WM_STATE_ICONIC;
                xcb_send_event(connection_, 0, screen.root,
                    XCB_EVENT_MASK_STRUCTURE_NOTIFY |
                    XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT,
                    cast(const char*)&ev);
                break;
            case WindowState.maximized:
                changeNetWmState(true,
                    atom(Atom._NET_WM_STATE_MAXIMIZED_HORZ),
                    atom(Atom._NET_WM_STATE_MAXIMIZED_VERT));
                break;
            case WindowState.fullscreen:
                changeNetWmState(true,
                    atom(Atom._NET_WM_STATE_FULLSCREEN));
                break;
            case WindowState.hidden:
                xcb_unmap_window(connection_, xcbWin_);
                break;
            default:
                break;
        }

        xcb_flush(connection_);
    }

    override @property IRect geometry() const
    {
        assert(created);
        auto c = xcb_get_geometry(conn, xcbWin_);
        xcb_generic_error_t *err;
        auto r = xcb_get_geometry_reply(conn, c, &err);
        if (err)
        {
            warningf("DGT-xcb could not retrieve window geometry");
            free(err);
            return IRect(0, 0, 0, 0);
        }
        auto res = IRect(r.x, r.y, r.width, r.height);
        free(r);
        return res;
    }

    override @property void geometry(IRect pos)
    {
        uint[5] values = [
            pos.x, pos.y, pos.width, pos.height, 0
        ];
        auto cookie = xcb_configure_window_checked (conn, xcbWin,
            XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y |
            XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT,
            &values[0]
        );
        auto err = xcb_request_check(conn, cookie);
        if (err)
        {
            warningf("DGT-XCB: error resizing window");
            free(err);
        }
        xcb_flush(conn);
    }

    package
    {
        @property xcb_window_t xcbWin() const
        {
            return xcbWin_;
        }
    }

    private
    {

        // not very clean, but we need a non-const object to retrieve properties
        @property xcb_connection_t *conn() const
        {
            return cast(xcb_connection_t*)connection_;
        }
        @property xcb_connection_t *conn()
        {
            return connection_;
        }

        void prepareEvents()
        {
            // register regular events
            {
                uint[] values = [
                    XCB_EVENT_MASK_KEY_PRESS |
                    XCB_EVENT_MASK_KEY_RELEASE |
                    XCB_EVENT_MASK_BUTTON_PRESS |
                    XCB_EVENT_MASK_BUTTON_RELEASE |
                    XCB_EVENT_MASK_ENTER_WINDOW |
                    XCB_EVENT_MASK_LEAVE_WINDOW |
                    XCB_EVENT_MASK_POINTER_MOTION |
                    XCB_EVENT_MASK_BUTTON_MOTION |
                    XCB_EVENT_MASK_EXPOSURE |
                    XCB_EVENT_MASK_STRUCTURE_NOTIFY |
                    XCB_EVENT_MASK_PROPERTY_CHANGE,
                    0
                ];
                xcb_change_window_attributes(connection_, xcbWin_,
                        XCB_CW_EVENT_MASK, &values[0]);
            }
            // register window close event
            {
                xcb_atom_t[] values = [
                    atom(Atom.WM_DELETE_WINDOW), 0
                ];
                xcb_change_property(connection_, XCB_PROP_MODE_REPLACE, xcbWin_,
                        atom(Atom.WM_PROTOCOLS), XCB_ATOM_ATOM, 32, 1,
                        &values[0]);
            }
        }

        enum NetWmStates
        {
            None                = 0x0000,
            Modal               = 0x0001,
            Sticky              = 0x0002,
            MaximizedVert       = 0x0004,
            MaximizedHorz       = 0x0008,
            Maximized           = 0x000C,
            Shaded              = 0x0010,
            SkipTaskbar         = 0x0020,
            SkipPager           = 0x0040,
            Hidden              = 0x0080,
            Fullscreen          = 0x0100,
            Above               = 0x0200,
            Below               = 0x0400,
            DemandsAttention    = 0x0800,
            Focused             = 0x1000
        }



        @property NetWmStates netWmStates() const
        {
            auto c = cast(xcb_connection_t*)connection_;
            auto cookie = xcb_get_property_unchecked(
                    c, 0, xcbWin_, atom(Atom._NET_WM_STATE),
                                 XCB_ATOM_ATOM, 0, 1024);

            auto reply = xcb_get_property_reply(c, cookie, null);
            if (!reply) return NetWmStates.None;
            scope(exit) free(reply);

            if (reply && reply.format == 32 && reply.type == XCB_ATOM_ATOM) {
                NetWmStates states;
                auto stateAtoms = cast(xcb_atom_t*)xcb_get_property_value(reply);
                foreach(a; stateAtoms[0 .. reply.length]) {
                    if (a == atom(Atom._NET_WM_STATE_MODAL))
                        states |= NetWmStates.Modal;
                    else if (a == atom(Atom._NET_WM_STATE_STICKY))
                        states |= NetWmStates.Sticky;
                    else if (a == atom(Atom._NET_WM_STATE_MAXIMIZED_VERT))
                        states |= NetWmStates.MaximizedVert;
                    else if (a == atom(Atom._NET_WM_STATE_MAXIMIZED_HORZ))
                        states |= NetWmStates.MaximizedHorz;
                    else if (a == atom(Atom._NET_WM_STATE_SHADED))
                        states |= NetWmStates.Shaded;
                    else if (a == atom(Atom._NET_WM_STATE_SKIP_TASKBAR))
                        states |= NetWmStates.SkipTaskbar;
                    else if (a == atom(Atom._NET_WM_STATE_SKIP_PAGER))
                        states |= NetWmStates.SkipPager;
                    else if (a == atom(Atom._NET_WM_STATE_HIDDEN))
                        states |= NetWmStates.Hidden;
                    else if (a == atom(Atom._NET_WM_STATE_FULLSCREEN))
                        states |= NetWmStates.Fullscreen;
                    else if (a == atom(Atom._NET_WM_STATE_ABOVE))
                        states |= NetWmStates.Above;
                    else if (a == atom(Atom._NET_WM_STATE_BELOW))
                        states |= NetWmStates.Below;
                    else if (a == atom(Atom._NET_WM_STATE_DEMANDS_ATTENTION))
                        states |= NetWmStates.DemandsAttention;
                    else if (a == atom(Atom._NET_WM_STATE_FOCUSED))
                        states |= NetWmStates.Focused;
                }
                return states;
            }
            return NetWmStates.None;
        }



        void changeNetWmState(bool yes, xcb_atom_t atom1,
                xcb_atom_t atom2=XCB_ATOM_NONE)
        {
            const screen = platform_.xcbScreens[0];
            xcb_client_message_event_t e;

            e.response_type = XCB_CLIENT_MESSAGE;
            e.window = xcbWin_;
            e.type = atom(Atom._NET_WM_STATE);
            e.format = 32;
            e.data.data32[0] = yes ? 1 : 0;
            e.data.data32[1] = atom1;
            e.data.data32[2] = atom2;

            xcb_send_event(connection_, 0, screen.root,
                XCB_EVENT_MASK_STRUCTURE_NOTIFY |
                XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT,
                cast(const char*)&e);
        }

        xcb_atom_t atom(Atom atom) const
        {
            return platform_.atom(atom);
        }

        ISize creationSize() const
        {
            auto size = win_.size;
            if (size.area == 0)
            {
                size.width = 640;
                size.height = 480;
            }
            return size;
        }

        IPoint creationPos(in Screen screen, in ISize size) const
        {
            auto pos = win_.position;
            if (pos.x < 0)
            {
                // center horizontally
                pos.x = (screen.width - size.width) / 2;
            }
            if (pos.y < 0)
            {
                // center vertically
                pos.y = (screen.height - size.height) / 2;
            }
            return pos;
        }

    }
}
