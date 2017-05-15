/// Window creation and manipulation
module dgt.window;

import dgt.application;
import dgt.context;
import dgt.event;
import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.platform;
import dgt.region;
import dgt.render;
import dgt.render.frame;
import dgt.screen;
import dgt.sg.parent;
import dgt.util;
import dgt.widget.widget;

import gfx.foundation.rc;

import std.exception;
import std.experimental.logger;
import std.typecons : Rebindable;

alias GfxDevice = gfx.device.Device;

enum WindowState
{
    normal,
    maximized,
    minimized,
    fullscreen,
    hidden
}

enum WindowFlags
{
    none = 0,
    dummy = 1,
}


class Window
{
    this(WindowFlags flags=WindowFlags.none)
    {
        _flags = flags;
        _platformWindow = Application.platform.createWindow(this);
    }

    this(string title, WindowFlags flags=WindowFlags.none)
    {
        _title = title;
        this(flags);
    }

    @property string title() const
    {
        if (_platformWindow.created) {
            return _platformWindow.title;
        }
        else {
            return _title;
        }
    }

    @property void title(in string title)
    {
        if (title != _title)
        {
            _title = title;
            if (_platformWindow.created)
            {
                _platformWindow.title = title;
            }
        }
    }

    @property IPoint position() const
    {
        return geometry.topLeft;
    }

    @property void position(in IPoint position)
    {
        if (position != this.position)
        {
            geometry = IRect(position, size);
        }
    }

    @property ISize size() const
    {
        return geometry.size;
    }

    @property void size(in ISize size)
    {
        if (size != this.size)
        {
            geometry = IRect(position, size);
        }
    }

    @property IRect geometry() const
    {
        if (_platformWindow.created) {
            return _platformWindow.geometry;
        }
        else {
            return IRect(_position, _size);
        }
    }

    @property void geometry(in IRect rect)
    {
        if (rect != geometry)
        {
            if (_platformWindow.created)
            {
                _platformWindow.geometry = rect;
            }
            else
            {
                _position = rect.point;
                _size = rect.size;
            }
        }
    }

    @property GlAttribs attribs() const
    {
        return _attribs;
    }

    @property void attribs(GlAttribs)
    in { assert(!_platformWindow.created); }
    body
    {
        _attribs = attribs;
    }

    @property WindowFlags flags() const
    {
        return _flags;
    }

    @property void flags(WindowFlags flags)
    in { assert(!_platformWindow.created); }
    body
    {
        _flags = flags;
    }

    void showMaximized()
    {
        show(WindowState.maximized);
    }

    void showMinimized()
    {
        show(WindowState.minimized);
    }

    void showFullscreen()
    {
        show(WindowState.fullscreen);
    }

    void showNormal()
    {
        show(WindowState.normal);
    }

    void hide()
    {
        show(WindowState.hidden);
    }

    void show(WindowState state = WindowState.normal)
    {
        if (!_platformWindow.created) {
            if (_size.area == 0) _size = ISize(640, 480);
            _platformWindow.create();
            if (!dummy) Application.instance.registerWindow(this);
            invalidate();
        }

        if (!dummy) _platformWindow.state = state;
    }

    void close()
    {
        enforce(_platformWindow.created, "attempt to close a non-created window");
        if (_root) _root.disposeResources();
        if (!dummy) Application.instance.unregisterWindow(this);
        _platformWindow.close();
        _onClosed.fire(this);
    }

    @property size_t nativeHandle() const
    {
        enforce(_platformWindow.created);
        return _platformWindow.nativeHandle;
    }

    @property Signal!string onTitleChange()
    {
        return _onTitleChange;
    }

    @property void onShow(Slot!ShowEvent slot)
    {
        _onShow.set(slot);
    }

    @property void onHide(Slot!HideEvent slot)
    {
        _onHide.set(slot);
    }

    @property void onMove(Slot!MoveEvent slot)
    {
        _onMove.set(slot);
    }

    @property void onResize(Slot!ResizeEvent slot)
    {
        _onResize.set(slot);
    }

    @property void onMouse(Slot!MouseEvent slot)
    {
        _onMouse.set(slot);
    }
    @property void onMouseDown(Slot!MouseEvent slot)
    {
        _onMouseDown.set(slot);
    }
    @property void onMouseUp(Slot!MouseEvent slot)
    {
        _onMouseUp.set(slot);
    }

    @property void onKey(Slot!KeyEvent slot)
    {
        _onKey.set(slot);
    }
    @property void onKeyDown(Slot!KeyEvent slot)
    {
        _onKeyDown.set(slot);
    }
    @property void onKeyUp(Slot!KeyEvent slot)
    {
        _onKeyUp.set(slot);
    }

    @property void onStateChange(Slot!StateChangeEvent slot)
    {
        _onStateChange.set(slot);
    }

    @property void onClose(Slot!CloseEvent slot)
    {
        _onClose.set(slot);
    }

    @property Signal!Window onClosed()
    {
        return _onClosed;
    }

    /// The scene graph root attached to this window
    @property inout(SgParent) root() inout { return _root; }
    /// ditto
    @property void root(SgParent root)
    {
        if (_root) {
            _root.disposeResources();
            _root._window = null;
        }
        _root = root;
        _widget = cast(Widget)_root;
        if (_root) {
            _root._window = this;
            //collectWidgetRoots(_root, _widgetRoots);
        }
    }

    /// The screen this window is on. If the window overlaps more than one screen,
    /// the screen with biggest overlap is returned.
    /// If for some reason the window is not overlapping any screen, the main monitor is returned.
    @property Screen screen() const
    {
        int overlap=-1;
        int num=-1;
        auto screens = Application.platform.screens;
        immutable rect = geometry;
        foreach (s; screens) {
            immutable sr = s.rect;
            if (sr.overlaps(rect)) {
                immutable ol = intersection(sr, rect).area;
                if (ol > overlap) {
                    overlap = ol;
                    num = s.num;
                }
            }
        }
        return num >= 0 ? screens[num] : screens[0];
    }

    /// The region that needs update
    @property Region dirtyRegion() const
    {
        return _dirtyReg;
    }

    /// Invalidate a rect
    void invalidate(in IRect rect)
    {
        _dirtyReg = unite(_dirtyReg, new Region(rect));
    }

    /// Invalidate the whole window
    void invalidate()
    {
        _dirtyReg = new Region(IRect(0, 0, size));
    }

    void handleEvent(WindowEvent wEv)
    {
        assert(wEv.window is this);
        switch (wEv.type)
        {
        case EventType.expose:
            handleExpose(cast(ExposeEvent)wEv);
            break;
        case EventType.show:
            _onShow.fire(cast(ShowEvent)wEv);
            break;
        case EventType.hide:
            _onHide.fire(cast(HideEvent)wEv);
            break;
        case EventType.move:
            auto wmEv = cast(MoveEvent) wEv;
            _position = wmEv.point;
            _onMove.fire(cast(MoveEvent) wEv);
            break;
        case EventType.resize:
            handleResize(cast(ResizeEvent) wEv);
            break;
        case EventType.mouseDown:
            handleMouseDown(cast(MouseEvent) wEv);
            break;
        case EventType.mouseUp:
            handleMouseUp(cast(MouseEvent) wEv);
            break;
        case EventType.keyDown:
            auto kEv = cast(KeyEvent) wEv;
            _onKey.fire(kEv);
            if (!kEv.consumed)
            {
                _onKeyDown.fire(kEv);
            }
            break;
        case EventType.keyUp:
            auto kEv = cast(KeyEvent) wEv;
            _onKey.fire(kEv);
            if (!kEv.consumed)
            {
                _onKeyUp.fire(kEv);
            }
            break;
        case EventType.stateChange:
            _onStateChange.fire(cast(StateChangeEvent) wEv);
            break;
        case EventType.close:
            auto cev = cast(CloseEvent) wEv;
            _onClose.fire(cev);
            if (!cev.declined)
                close();
            break;
        default:
            break;
        }
    }

    package(dgt)
    {
        @property bool dummy() const
        {
            return (_flags & WindowFlags.dummy) != 0;
        }

        @property inout(PlatformWindow) platformWindow() inout
        {
            return _platformWindow;
        }

        @property bool created() const
        {
            return _platformWindow.created;
        }

        void compressEvent(WindowEvent ev)
        {
            if (ev.type == EventType.move) {
                if (_evCompress & EvCompress.move) {
                    auto prev = getEvent!MoveEvent(EventType.move);
                    auto cur = cast(MoveEvent)ev;
                    prev.point = cur.point;
                }
                else {
                    _events ~= ev;
                    _evCompress |= EvCompress.move;
                }
            }
            else if (ev.type == EventType.resize) {
                if (_evCompress & EvCompress.resize) {
                    auto prev = getEvent!ResizeEvent(EventType.resize);
                    auto cur = cast(ResizeEvent)ev;
                    prev.size = cur.size;
                }
                else {
                    _events ~= ev;
                    _evCompress |= EvCompress.resize;
                }
            }
            else if (ev.type == EventType.mouseMove) {
                if (_evCompress & EvCompress.mouseMove && !(_evCompress & EvCompress.click)) {
                    auto prev = getEvent!MouseEvent(EventType.mouseMove);
                    auto cur = cast(MouseEvent)ev;
                    prev.point = cur.point;
                    prev.modifiers = prev.modifiers | cur.modifiers;
                }
                else {
                    _events ~= ev;
                    _evCompress |= EvCompress.mouseMove;
                }
            }
            else {
                if (ev.type == EventType.mouseDown || ev.type == EventType.mouseUp) {
                    _evCompress |= EvCompress.click;
                }
                else if (ev.type == EventType.show) {
                    _evCompress |= EvCompress.show;
                }
                _events ~= ev;
            }
        }

        void deliverEvents()
        {
            if (_evCompress & EvCompress.fstFrame) {
                if (!(_evCompress & EvCompress.show)) {
                    handleEvent(new ShowEvent(this));
                }
                if (!(_evCompress & EvCompress.resize)) {
                    handleEvent(new ResizeEvent(this, size));
                }
            }
            foreach(ev; _events) {
                handleEvent(ev);
            }
            _events = [];
            _evCompress = EvCompress.none;
        }

        immutable(RenderFrame) collectFrame()
        {
            scope(exit) _dirtyReg = new Region;
            if (_root) {
                import dgt.css.cascade;
                cssCascade(_root);
            }
            if (_widget) {
                import dgt.widget.layout : MeasureSpec;
                immutable fs = cast(FSize)size;
                _widget.measure(
                    MeasureSpec.makeAtMost(fs.width),
                    MeasureSpec.makeAtMost(fs.height)
                );
                _widget.layout(FRect(0, 0, fs));
            }
            return new immutable RenderFrame (
                nativeHandle, IRect(0, 0, size),
                _root ? _root.collectTransformedRenderNode() : null
            );
        }
    }

    private
    {
        void handleResize(ResizeEvent ev)
        {
            immutable newSize = ev.size;
            _size = newSize;
            _onResize.fire(ev);
            invalidate();
        }

        void handleExpose(ExposeEvent ev)
        {
        }

        void handleMouseDown(MouseEvent ev)
        {
            assert(ev.type == EventType.mouseDown);
            _onMouse.fire(ev);
            if (!ev.consumed) _onMouseDown.fire(ev);
            if (!ev.consumed && _root) {
                _root.eventTargetedChain(ev);
            }
        }

        void handleMouseUp(MouseEvent ev)
        {
            assert(ev.type == EventType.mouseUp);
            _onMouse.fire(ev);
            if (!ev.consumed) _onMouseUp.fire(ev);
            if (!ev.consumed && _root) {
                _root.eventTargetedChain(ev);
            }
        }

        EvT getEvent(EvT)(EventType type)
        {
            foreach(e; _events) {
                if (e.type == type) return cast(EvT)e;
            }
            return null;
        }

        enum EvCompress
        {
            none        = 0,
            fstFrame    = 1,
            move        = 2,
            resize      = 4,
            mouseMove   = 8,
            click       = 16,
            show        = 32,
        }

        WindowFlags _flags;
        string _title;
        IPoint _position = IPoint(-1, -1);
        ISize _size;
        GlAttribs _attribs;
        PlatformWindow _platformWindow;
        SgParent _root;
        Widget _widget;
        // Widget[] _widgetRoots;

        EvCompress _evCompress = EvCompress.fstFrame;
        WindowEvent[] _events;

        Rebindable!Region _dirtyReg = new Region;

        FireableSignal!string    _onTitleChange = new FireableSignal!string;
        Handler!ShowEvent        _onShow        = new Handler!ShowEvent;
        Handler!HideEvent        _onHide        = new Handler!HideEvent;
        Handler!MoveEvent        _onMove        = new Handler!MoveEvent;
        Handler!ResizeEvent      _onResize      = new Handler!ResizeEvent;
        Handler!MouseEvent       _onMouse       = new Handler!MouseEvent;
        Handler!MouseEvent       _onMouseDown   = new Handler!MouseEvent;
        Handler!MouseEvent       _onMouseUp     = new Handler!MouseEvent;
        Handler!KeyEvent         _onKey         = new Handler!KeyEvent;
        Handler!KeyEvent         _onKeyDown     = new Handler!KeyEvent;
        Handler!KeyEvent         _onKeyUp       = new Handler!KeyEvent;
        Handler!StateChangeEvent _onStateChange = new Handler!StateChangeEvent;
        Handler!CloseEvent       _onClose       = new Handler!CloseEvent;
        FireableSignal!Window    _onClosed      = new FireableSignal!Window;
    }
}


private void collectWidgetRoots(SgParent parent, ref Widget[] roots)
{
    auto w = cast(Widget)parent;
    if (w && !cast(Widget)w.parent) {
        roots ~= w;
    }
    import std.algorithm : each, filter, map;
    parent.children
        .map!(n => cast(SgParent)n)
        .filter!(p => p !is null)
        .each!(p => collectWidgetRoots(p, roots));
}
