module dgt.platform.xcb.window;

version(linux):

import dgt.context;
import dgt.enums;
import dgt.geometry;
import dgt.platform;
import dgt.platform.event;
import dgt.platform.xcb;
import dgt.platform.xcb.buffer;
import dgt.platform.xcb.context;
import dgt.screen;
import dgt.vg;
import dgt.window;

import gfx.foundation.rc;

import xcb.xcb;
import xcb.xcb_icccm;
import X11.Xlib;

import std.experimental.logger;
import std.typecons : scoped;
import std.string : toStringz;
import std.exception : enforce;
import core.stdc.stdlib : free;

alias Window = dgt.window.Window;
alias Atom = dgt.platform.xcb.Atom;
alias Screen = dgt.screen.Screen;


/// Xcb implementation of PlatformWindow
class XcbWindow : PlatformWindow
{
    private
    {
        Window _win;
        XcbPlatform _platform;
        xcb_window_t _xcbWin;
        xcb_visualid_t _visualId;
        xcb_visualtype_t* _visual;
        xcb_format_t* _format;
        xcb_gcontext_t _gc;
        ubyte _depth;
        WindowState _lastKnownState = WindowState.hidden;
        IRect _rect;
        bool _created = false;
        bool _mapped;
    }

    this(Window w, XcbPlatform platform)
    {
        _win = w;
        _platform = platform;
    }

    override @property inout(Window) window() inout
    {
        return _win;
    }

    override bool created() const
    {
        return _created;
    }

    override void create()
    {
        const screen = _platform.defaultXcbScreen;
        immutable screenNum = screen.num;
        immutable size = creationSize();
        immutable pos = creationPos(screen, size);

        _rect = IRect(pos, size);

        auto visualInfo = getXlibVisualInfo(g_display, screenNum, _win.attribs);
        if (!visualInfo)
        {
            throw new Exception("DGT-XCB: window could not get visual");
        }
        _visualId = visualInfo.visualid;
        XFree(visualInfo);

        _visual = getXcbVisualForId(_platform.xcbScreens, _visualId);
        _depth = screen.rootDepth;
        _format = _platform.formatForDepth(_depth);

        immutable cmap = xcb_generate_id(g_connection);
        _xcbWin = xcb_generate_id(g_connection);

        xcb_create_colormap(g_connection, XCB_COLORMAP_ALLOC_NONE, cmap, screen.root, _visualId);

        immutable mask = XCB_CW_COLORMAP;
        uint[] values = [cmap, 0];

        auto cook = xcb_create_window_checked(g_connection, screen.rootDepth,
                _xcbWin, screen.root, cast(short) pos.x, cast(short) pos.y,
                cast(ushort) size.width, cast(ushort) size.height, 0,
                XCB_WINDOW_CLASS_INPUT_OUTPUT, screen.rootVisual, mask, &values[0]);

        auto err = xcb_request_check(g_connection, cook);
        if (err)
        {
            import std.format : format;

            throw new Exception(format("DGT-XCB: could not create window: %s", err.error_code));
        }

        this.title = _win.title;

        prepareEvents();
        prepareGc();

        _platform.registerWindow(this);

        _lastKnownState = WindowState.hidden;
        _created = true;
    }

    override @property size_t nativeHandle() const
    {
        return _xcbWin;
    }

    override void close()
    {
        _platform.unregisterWindow(this);
        if (_mapped)
            xcb_unmap_window(g_connection, _xcbWin);
        xcb_destroy_window(g_connection, _xcbWin);
        xcb_flush(g_connection);
        _xcbWin = 0;
    }

    override @property string title() const
    {
        auto c = xcb_get_property(g_connection, 0, _xcbWin, XCB_ATOM_WM_NAME,
                XCB_ATOM_STRING, 0, 1024);
        auto r = xcb_get_property_reply(g_connection, c, null);
        if (!r)
            return "";
        scope (exit)
            free(r);
        auto len = xcb_get_property_value_length(r);
        return cast(string)(xcb_get_property_value(r)[0 .. len].idup);
    }

    override @property void title(string title)
    {
        xcb_change_property(g_connection, cast(ubyte) XCB_PROP_MODE_REPLACE, _xcbWin,
                cast(xcb_atom_t) XCB_ATOM_WM_NAME, cast(xcb_atom_t) XCB_ATOM_STRING,
                8, cast(uint) title.length, toStringz(title));
        xcb_change_property(g_connection, cast(ubyte) XCB_PROP_MODE_REPLACE, _xcbWin,
                cast(xcb_atom_t) XCB_ATOM_WM_ICON_NAME, cast(xcb_atom_t) XCB_ATOM_STRING,
                8, cast(uint) title.length, toStringz(title));
    }

    override @property WindowState state() const
    {
        auto cookie = xcb_get_property_unchecked(g_connection, 0, _xcbWin,
                atom(Atom.WM_STATE), XCB_ATOM_ANY, 0, 1024);

        auto reply = xcb_get_property_reply(g_connection, cookie, null);
        if (reply)
        {
            scope (exit)
                free(reply);
            if (reply.format == 32 && reply.type == atom(Atom.WM_STATE) && reply.length >= 1)
            {
                auto data = cast(uint*) xcb_get_property_value(reply);
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
        if (_lastKnownState == ws)
            return;

        const screen = _platform.defaultXcbScreen;

        // removing attribute that makes other than normal

        switch (_lastKnownState)
        {
        case WindowState.maximized:
            changeNetWmState(false,
                    atom(Atom._NET_WM_STATE_MAXIMIZED_HORZ),
                    atom(Atom._NET_WM_STATE_MAXIMIZED_VERT));
            break;
        case WindowState.fullscreen:
            changeNetWmState(false, atom(Atom._NET_WM_STATE_FULLSCREEN));
            break;
        case WindowState.minimized:
        case WindowState.hidden:
            xcb_map_window(g_connection, _xcbWin);
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
            ev.window = _xcbWin;
            ev.type = atom(Atom.WM_CHANGE_STATE);
            ev.data.data32[0] = XCB_ICCCM_WM_STATE_ICONIC;
            xcb_send_event(g_connection, 0, screen.root,
                    XCB_EVENT_MASK_STRUCTURE_NOTIFY | XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT,
                    cast(const(char)*)&ev);
            break;
        case WindowState.maximized:
            changeNetWmState(true,
                    atom(Atom._NET_WM_STATE_MAXIMIZED_HORZ),
                    atom(Atom._NET_WM_STATE_MAXIMIZED_VERT));
            break;
        case WindowState.fullscreen:
            changeNetWmState(true, atom(Atom._NET_WM_STATE_FULLSCREEN));
            break;
        case WindowState.hidden:
            xcb_unmap_window(g_connection, _xcbWin);
            break;
        default:
            break;
        }

        xcb_flush(g_connection);
    }

    override @property IRect geometry() const
    {
        return _rect;
    }

    private @property IRect sysGeometry() const
    {
        assert(created);
        auto c = xcb_get_geometry(g_connection, _xcbWin);
        xcb_generic_error_t* err;
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
        if (rect.area == 0)
            return;
        uint[5] values = [rect.x, rect.y, rect.width, rect.height, 0];
        auto cookie = xcb_configure_window_checked(g_connection, xcbWin,
                XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y | XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT,
                &values[0]);
        auto err = xcb_request_check(g_connection, cookie);
        if (err)
        {
            warningf("DGT-XCB: error resizing window");
            free(err);
        }
        xcb_flush(g_connection);
    }

    override PlatformWindowBuffer makeBuffer(in ISize size)
    {
        return new XcbWindowBuffer(this, size);
    }

    package
    {
        @property xcb_window_t xcbWin() const
        {
            return _xcbWin;
        }

        @property xcb_gcontext_t xcbGc() const
        {
            return _gc;
        }

        @property ubyte depth() const
        {
            return _depth;
        }

        @property uint xcbVisualId() const
        {
            return _visualId;
        }

        @property inout(xcb_visualtype_t)* xcbVisual() inout
        {
            return _visual;
        }

        @property inout(xcb_format_t)* xcbFormat() inout
        {
            return _format;
        }

        void processButtonEvent(xcb_button_press_event_t* e, void delegate(PlEvent) collector)
        in
        {
            assert(e.event == _xcbWin);
        }
        body
        {
            auto ev = new PlMouseEvent((xcbEventType(e) == XCB_BUTTON_PRESS) ? PlEventType.mouseDown
                    : PlEventType.mouseUp, _win, IPoint(e.event_x, e.event_y),
                    dgtMouseButton(e.detail), dgtMouseState(e.state), dgtKeyMods(e.state));
            collector(ev);
        }

        void processMotionEvent(xcb_motion_notify_event_t* e, void delegate(PlEvent) collector)
        in
        {
            assert(e.event == _xcbWin);
        }
        body
        {
            auto ev = new PlMouseEvent(PlEventType.mouseMove, _win, IPoint(e.event_x,
                    e.event_y), MouseButton.none, dgtMouseState(e.state), dgtKeyMods(e.state));
            collector(ev);
        }

        void processEnterLeaveEvent(xcb_enter_notify_event_t* e, void delegate(PlEvent) collector)
        in
        {
            assert(e.event == _xcbWin);
        }
        body
        {
            auto ev = new PlMouseEvent(xcbEventType(e) == XCB_ENTER_NOTIFY ? PlEventType.mouseEnter
                    : PlEventType.mouseLeave, _win, IPoint(e.event_x, e.event_y),
                    MouseButton.none, dgtMouseState(e.state), dgtKeyMods(e.state));
            collector(ev);
        }

        void processConfigureEvent(xcb_configure_notify_event_t* e, void delegate(PlEvent) collector)
        in
        {
            assert(e.event == _xcbWin);
        }
        body
        {
            if (e.x != _rect.x || e.y != _rect.y)
            {
                _rect.point = IPoint(e.x, e.y);
                collector(new MoveEvent(_win, _rect.point));
            }
            if (e.width != _rect.width || e.height != _rect.height)
            {
                _rect.size = ISize(e.width, e.height);
                collector(new ResizeEvent(_win, _rect.size));
            }
        }

        void processUnmapEvent(xcb_unmap_notify_event_t* e, void delegate(PlEvent) collector)
        in
        {
            assert(e.event == _xcbWin);
        }
        body
        {
            _mapped = false;
            auto ev = new HideEvent(_win);
            collector(ev);
        }

        void processMapEvent(xcb_map_notify_event_t* e, void delegate(PlEvent) collector)
        in
        {
            assert(e.event == _xcbWin);
        }
        body
        {
            _mapped = true;
            auto ev = new ShowEvent(_win);
            collector(ev);
        }

        void processPropertyEvent(xcb_property_notify_event_t* e, void delegate(PlEvent) collector)
        in
        {
            assert(e.window == _xcbWin);
        }
        body
        {

            if (e.atom == atom(Atom.WM_STATE) || e.atom == atom(Atom._NET_WM_STATE))
            {
                WindowState ws = state;
                if (ws != _lastKnownState)
                {
                    _lastKnownState = ws;
                    collector(new StateChangeEvent(_win, ws));
                }
            }
        }

        void processExposeEvent(xcb_expose_event_t* e, void delegate(PlEvent) collector)
        in
        {
            assert(e.window == _xcbWin);
        }
        body
        {
            auto ev = new ExposeEvent(_win, IRect(e.x, e.y, e.width, e.height));
            collector(ev);
        }
    }

    private
    {
        void prepareEvents()
        {
            // register regular events
            {
                uint[] values = [
                    XCB_EVENT_MASK_KEY_PRESS | XCB_EVENT_MASK_KEY_RELEASE | XCB_EVENT_MASK_BUTTON_PRESS
                    | XCB_EVENT_MASK_BUTTON_RELEASE | XCB_EVENT_MASK_ENTER_WINDOW
                    | XCB_EVENT_MASK_LEAVE_WINDOW | XCB_EVENT_MASK_POINTER_MOTION
                    | XCB_EVENT_MASK_BUTTON_MOTION | XCB_EVENT_MASK_EXPOSURE
                    | XCB_EVENT_MASK_STRUCTURE_NOTIFY | XCB_EVENT_MASK_PROPERTY_CHANGE, 0
                ];
                xcb_change_window_attributes(g_connection, _xcbWin,
                        XCB_CW_EVENT_MASK, &values[0]);
            }
            // register window close event
            {
                xcb_atom_t[] values = [atom(Atom.WM_DELETE_WINDOW), 0];
                xcb_change_property(g_connection, XCB_PROP_MODE_REPLACE, _xcbWin,
                        atom(Atom.WM_PROTOCOLS), XCB_ATOM_ATOM, 32, 1, &values[0]);
            }
        }

        void prepareGc()
        {
            immutable uint mask = XCB_GC_GRAPHICS_EXPOSURES;
            immutable uint values = 0;

            _gc = xcb_generate_id(g_connection);
            xcb_create_gc(g_connection, _gc, xcbWin, mask, &values);
        }

        enum NetWmStates
        {
            None = 0x0000,
            Modal = 0x0001,
            Sticky = 0x0002,
            MaximizedVert = 0x0004,
            MaximizedHorz = 0x0008,
            Maximized = 0x000C,
            Shaded = 0x0010,
            SkipTaskbar = 0x0020,
            SkipPager = 0x0040,
            Hidden = 0x0080,
            Fullscreen = 0x0100,
            Above = 0x0200,
            Below = 0x0400,
            DemandsAttention = 0x0800,
            Focused = 0x1000
        }

        @property NetWmStates netWmStates() const
        {
            auto cookie = xcb_get_property_unchecked(g_connection, 0, _xcbWin,
                    atom(Atom._NET_WM_STATE), XCB_ATOM_ATOM, 0, 1024);

            auto reply = xcb_get_property_reply(g_connection, cookie, null);
            if (!reply)
                return NetWmStates.None;
            scope (exit)
                free(reply);

            if (reply && reply.format == 32 && reply.type == XCB_ATOM_ATOM)
            {
                NetWmStates states;
                auto stateAtoms = cast(xcb_atom_t*) xcb_get_property_value(reply);
                foreach (a; stateAtoms[0 .. reply.length])
                {
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

        void changeNetWmState(bool yes, xcb_atom_t atom1, xcb_atom_t atom2 = XCB_ATOM_NONE)
        {
            const screen = _platform.defaultXcbScreen;
            xcb_client_message_event_t e;

            e.response_type = XCB_CLIENT_MESSAGE;
            e.window = _xcbWin;
            e.type = atom(Atom._NET_WM_STATE);
            e.format = 32;
            e.data.data32[0] = yes ? 1 : 0;
            e.data.data32[1] = atom1;
            e.data.data32[2] = atom2;

            xcb_send_event(g_connection, 0, screen.root,
                    XCB_EVENT_MASK_STRUCTURE_NOTIFY | XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT,
                    cast(const(char)*)&e);
        }

        xcb_atom_t atom(Atom atom) const
        {
            return _platform.atom(atom);
        }

        ISize creationSize() const
        {
            auto size = _win.size;
            if (size.area == 0)
            {
                size.width = 640;
                size.height = 480;
            }
            return size;
        }

        IPoint creationPos(in Screen screen, in ISize size) const
        {
            auto pos = _win.position;
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
