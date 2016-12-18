module dgt.platform.xcb.window;

import dgt.platform.xcb;
import dgt.platform.xcb.context;
import dgt.screen;
import dgt.platform;
import dgt.window;
import dgt.geometry;
import dgt.event;
import dgt.enums;

import xcb.xcb;
import xcb.xcb_icccm;
import X11.Xlib;

import std.experimental.logger;
import std.typecons : scoped;
import std.string : toStringz;
import core.stdc.stdlib : free;

alias Window = dgt.window.Window;
alias Atom = dgt.platform.xcb.Atom;
alias Screen = dgt.screen.Screen;

/// Xcb implementation of PlatformWindow
class XcbWindow : PlatformWindow
{
    private
    {
        Window win_;
        XcbPlatform platform_;
        xcb_window_t xcbWin_;
        bool created_ = false;
        WindowState lastKnownState_ = WindowState.hidden;
        IRect rect_;
        bool mapped_;
    }

    this(Window w, XcbPlatform platform)
    {
        win_ = w;
        platform_ = platform;
    }

    override bool created() const { return created_; }

    override void create(WindowState state)
    {
        const screen = platform_.xcbScreens[0];
        immutable screenNum = screen.num;
        immutable size = creationSize();
        immutable pos = creationPos(screen, size);

        auto visualInfo = getXlibVisualInfo (
                g_display, screenNum, win_.attribs
        );
        if (!visualInfo) {
            throw new Exception("DGT-XCB: window could not get visual");
        }
        scope(exit) XFree(visualInfo);

        immutable cmap = xcb_generate_id(g_connection);
        xcbWin_ = xcb_generate_id(g_connection);

        xcb_create_colormap(g_connection, XCB_COLORMAP_ALLOC_NONE,
                cmap, screen.root, visualInfo.visualid);

        immutable mask = XCB_CW_BACK_PIXEL | XCB_CW_COLORMAP;
        uint[] values = [ screen.whitePixel, cmap, 0 ];

        auto cook = xcb_create_window_checked (
                g_connection, screen.rootDepth, xcbWin_,
                screen.root, cast(short)pos.x, cast(short)pos.y,
                cast(ushort)size.width, cast(ushort)size.height, 0,
                XCB_WINDOW_CLASS_INPUT_OUTPUT,
                screen.rootVisual, mask, &values[0]);

        auto err = xcb_request_check(g_connection, cook);
        if (err) {
            import std.format : format;
            throw new Exception(format(
                "DGT-XCB: could not create window: %s", err.error_code));
        }

        prepareEvents();

        platform_.registerWindow(this);

        rect_ = IRect(pos, size);
        lastKnownState_ = WindowState.hidden;
        this.state = state; // actually show the window
        created_ = true;
    }

    override void close()
    {
        if (mapped_) xcb_unmap_window(g_connection, xcbWin_);
        xcb_destroy_window(g_connection, xcbWin_);
        xcb_flush(g_connection);
    }

    override @property string title() const
    {
        auto c = xcb_get_property(g_connection, 0, xcbWin_, XCB_ATOM_WM_NAME,
            XCB_ATOM_STRING, 0, 1024);
        auto r = xcb_get_property_reply(g_connection, c, null);
        if (!r) return "";
        scope(exit) free(r);
        auto len = xcb_get_property_value_length(r);
        return cast(string)(xcb_get_property_value(r)[0 .. len].idup);
    }

    override @property void title(string title)
    {
         xcb_change_property(g_connection,
                cast(ubyte)XCB_PROP_MODE_REPLACE, xcbWin_,
                cast(xcb_atom_t)XCB_ATOM_WM_NAME, cast(xcb_atom_t)XCB_ATOM_STRING,
                8, cast(uint)title.length, toStringz(title));
        xcb_change_property(g_connection,
                cast(ubyte)XCB_PROP_MODE_REPLACE, xcbWin_,
                cast(xcb_atom_t)XCB_ATOM_WM_ICON_NAME, cast(xcb_atom_t)XCB_ATOM_STRING,
                8, cast(uint)title.length, toStringz(title));
    }

    override @property WindowState state() const
    {
        auto cookie = xcb_get_property_unchecked(
                g_connection, 0, xcbWin_, atom(Atom.WM_STATE),
                XCB_ATOM_ANY, 0, 1024
        );

        auto reply = xcb_get_property_reply(g_connection, cookie, null);
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
                xcb_map_window(g_connection, xcbWin_);
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
                xcb_send_event(g_connection, 0, screen.root,
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
                xcb_unmap_window(g_connection, xcbWin_);
                break;
            default:
                break;
        }

        xcb_flush(g_connection);
    }

    override @property IRect geometry() const
    {
        assert(created);
        auto c = xcb_get_geometry(g_connection, xcbWin_);
        xcb_generic_error_t *err;
        auto r = xcb_get_geometry_reply(g_connection, c, &err);
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

    override @property void geometry(IRect rect)
    {
        if (rect.area == 0) return;
        uint[5] values = [
            rect.x, rect.y, rect.width, rect.height, 0
        ];
        auto cookie = xcb_configure_window_checked (g_connection, xcbWin,
                XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y |
                XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT,
                &values[0]
        );
        auto err = xcb_request_check(g_connection, cookie);
        if (err)
        {
            warningf("DGT-XCB: error resizing window");
            free(err);
        }
        xcb_flush(g_connection);
    }

    @property inout(Window) window() inout
    {
        return win_;
    }

    package
    {
        @property xcb_window_t xcbWin() const
        {
            return xcbWin_;
        }

        void processButtonEvent(xcb_button_press_event_t* e)
        in {
            assert(e.event == xcbWin_);
        }
        body {
            auto ev = scoped!WindowMouseEvent (
                (xcbEventType(e) == XCB_BUTTON_PRESS) ?
                    EventType.windowMouseDown : EventType.windowMouseUp,
                win_, IPoint(e.event_x, e.event_y),
                dgtMouseButton(e.detail), dgtMouseState(e.state),
                dgtKeyMods(e.state)
            );
            win_.handleEvent(ev);
        }

        void processMotionEvent(xcb_motion_notify_event_t* e)
        in {
            assert(e.event == xcbWin_);
        }
        body {
            auto ev = scoped!WindowMouseEvent (
                EventType.windowMouseMove, win_,
                IPoint(e.event_x, e.event_y),
                MouseButton.none, dgtMouseState(e.state),
                dgtKeyMods(e.state)
            );
            win_.handleEvent(ev);
        }

        void processEnterLeaveEvent(xcb_enter_notify_event_t* e)
        in {
            assert(e.event == xcbWin_);
        }
        body {
            auto ev = scoped!WindowMouseEvent (
                xcbEventType(e) == XCB_ENTER_NOTIFY ?
                    EventType.windowMouseEnter : EventType.windowMouseLeave,
                win_, IPoint(e.event_x, e.event_y),
                MouseButton.none, dgtMouseState(e.state),
                dgtKeyMods(e.state)
            );
            win_.handleEvent(ev);
        }

        void processConfigureEvent(xcb_configure_notify_event_t* e)
        in {
            assert(e.event == xcbWin_);
        }
        body {
            if (e.x != rect_.x || e.y != rect_.y)
            {
                rect_.point = IPoint(e.x, e.y);
                win_.handleEvent(scoped!WindowMoveEvent(win_, rect_.point));
            }
            if (e.width != rect_.width || e.height != rect_.height)
            {
                rect_.size = ISize(e.width, e.height);
                win_.handleEvent(scoped!WindowResizeEvent(win_, rect_.size));
            }
        }

        void processUnmapEvent(xcb_unmap_notify_event_t* e)
        in {
            assert(e.event == xcbWin_);
        }
        body {
            mapped_ = false;
            auto ev = scoped!WindowHideEvent(win_);
            win_.handleEvent(ev);
        }

        void processMapEvent(xcb_map_notify_event_t* e)
        in {
            assert(e.event == xcbWin_);
        }
        body {
            mapped_ = true;
            auto ev = scoped!WindowShowEvent(win_);
            win_.handleEvent(ev);
        }

        void processPropertyEvent(xcb_property_notify_event_t* e)
        in {
            assert(e.window == xcbWin_);
        }
        body {

            if (e.atom == atom(Atom.WM_STATE) || e.atom == atom(Atom._NET_WM_STATE)) {
                WindowState ws = state;
                if (ws != lastKnownState_) {
                    lastKnownState_ = ws;
                    win_.handleEvent(scoped!WindowStateChangeEvent(win_, ws));
                }
            }
        }
    }

    private
    {
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
                xcb_change_window_attributes(g_connection, xcbWin_,
                        XCB_CW_EVENT_MASK, &values[0]);
            }
            // register window close event
            {
                xcb_atom_t[] values = [
                    atom(Atom.WM_DELETE_WINDOW), 0
                ];
                xcb_change_property(g_connection, XCB_PROP_MODE_REPLACE, xcbWin_,
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
            auto cookie = xcb_get_property_unchecked(
                    g_connection, 0, xcbWin_, atom(Atom._NET_WM_STATE),
                                 XCB_ATOM_ATOM, 0, 1024);

            auto reply = xcb_get_property_reply(g_connection, cookie, null);
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

            xcb_send_event(g_connection, 0, screen.root,
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
