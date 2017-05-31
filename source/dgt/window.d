/// Window creation and manipulation
module dgt.window;

import dgt.application;
import dgt.context;
import dgt.event;
import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.platform;
import dgt.platform.event;
import dgt.region;
import dgt.render;
import dgt.render.frame;
import dgt.screen;
import dgt.util;
import dgt.view.view;

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

    @property int width() const
    {
        return geometry.width;
    }
    @property int height() const
    {
        return geometry.height;
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

    @property FVec4 clearColor()
    {
        return _clearColor;
    }
    @property void clearColor(in FVec4 color)
    {
        _clearColor = color;
        _hasClearColor = true;
    }
    @property bool hasClearColor()
    {
        return _hasClearColor;
    }
    @property void hasClearColor(bool has)
    {
        _hasClearColor = has;
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

    @property void onMouse(Slot!PlMouseEvent slot)
    {
        _onMouse.set(slot);
    }
    @property void onMouseDown(Slot!PlMouseEvent slot)
    {
        _onMouseDown.set(slot);
    }
    @property void onMouseUp(Slot!PlMouseEvent slot)
    {
        _onMouseUp.set(slot);
    }

    @property void onKey(Slot!PlKeyEvent slot)
    {
        _onKey.set(slot);
    }
    @property void onKeyDown(Slot!PlKeyEvent slot)
    {
        _onKeyDown.set(slot);
    }
    @property void onKeyUp(Slot!PlKeyEvent slot)
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
    @property inout(View) root() inout { return _root; }
    /// ditto
    @property void root(View root)
    {
        if (_root) {
            _root._window = null;
        }
        _root = root;
        if (_root) {
            _root._window = this;
        }
    }

    /// The screen this window is on. If the window overlaps more than one screen,
    /// the screen with biggest overlap is returned.
    /// If for some reason the window is not overlapping any screen, the main monitor is returned.
    @property Screen screen() const
    {
        int overlap=-1;
        size_t ind = size_t.max;
        auto screens = Application.platform.screens;
        immutable rect = geometry;
        foreach (i, s; screens) {
            immutable sr = s.rect;
            if (sr.overlaps(rect)) {
                immutable ol = intersection(sr, rect).area;
                if (ol > overlap) {
                    overlap = ol;
                    ind = i;
                }
            }
        }
        return ind != size_t.max ? screens[ind] : screens[0];
    }

    /// Whether the window need to be rendered
    @property bool dirtyContent()
    {
        return _dirtyContent;
    }

    /// notify that rendering occured
    package(dgt) void cleanContent()
    {
        _dirtyContent = false;
    }

    /// The region that needs update
    @property Region dirtyRegion() const
    {
        return _dirtyReg;
    }

    /// Reset the invalidate region to empty
    void cleanRegion()
    out {
        assert(_dirtyReg.empty);
    }
    body {
        _dirtyReg = new Region;
    }

    void invalidate(in IRect rect)
    {
        _dirtyReg = unite(_dirtyReg, new Region(rect));
        _dirtyContent = true;
    }

    /// Invalidate the whole window
    void invalidate()
    {
        _dirtyReg = new Region(IRect(0, 0, size));
        _dirtyContent = true;
    }

    /// request a layout pass
    void requestLayout()
    {
        _dirtyLayout = true;
    }

    /// request a style pass
    void requestStylePass()
    {
        _dirtyStyle = true;
    }

    void handleEvent(WindowEvent wEv)
    {
        assert(wEv.window is this);
        switch (wEv.type)
        {
        case PlEventType.expose:
            handleExpose(cast(ExposeEvent)wEv);
            break;
        case PlEventType.show:
            _onShow.fire(cast(ShowEvent)wEv);
            break;
        case PlEventType.hide:
            _onHide.fire(cast(HideEvent)wEv);
            break;
        case PlEventType.move:
            auto wmEv = cast(MoveEvent) wEv;
            _position = wmEv.point;
            _onMove.fire(cast(MoveEvent) wEv);
            break;
        case PlEventType.resize:
            handleResize(cast(ResizeEvent) wEv);
            break;
        case PlEventType.mouseDown:
            handleMouseDown(cast(PlMouseEvent) wEv);
            break;
        case PlEventType.mouseUp:
            handleMouseUp(cast(PlMouseEvent) wEv);
            break;
        case PlEventType.mouseMove:
            handleMouseMove(cast(PlMouseEvent) wEv);
            break;
        case PlEventType.mouseEnter:
            handleMouseEnter(cast(PlMouseEvent) wEv);
            break;
        case PlEventType.mouseLeave:
            handleMouseLeave(cast(PlMouseEvent) wEv);
            break;
        case PlEventType.keyDown:
            auto kEv = cast(PlKeyEvent) wEv;
            _onKey.fire(kEv);
            if (!kEv.consumed)
            {
                _onKeyDown.fire(kEv);
            }
            break;
        case PlEventType.keyUp:
            auto kEv = cast(PlKeyEvent) wEv;
            _onKey.fire(kEv);
            if (!kEv.consumed)
            {
                _onKeyUp.fire(kEv);
            }
            break;
        case PlEventType.stateChange:
            _onStateChange.fire(cast(StateChangeEvent) wEv);
            break;
        case PlEventType.close:
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
            if (ev.type == PlEventType.move) {
                if (_evCompress & EvCompress.move) {
                    auto prev = getEvent!MoveEvent(PlEventType.move);
                    auto cur = cast(MoveEvent)ev;
                    prev.point = cur.point;
                }
                else {
                    _events ~= ev;
                    _evCompress |= EvCompress.move;
                }
            }
            else if (ev.type == PlEventType.resize) {
                if (_evCompress & EvCompress.resize) {
                    auto prev = getEvent!ResizeEvent(PlEventType.resize);
                    auto cur = cast(ResizeEvent)ev;
                    prev.size = cur.size;
                }
                else {
                    _events ~= ev;
                    _evCompress |= EvCompress.resize;
                }
            }
            else if (ev.type == PlEventType.mouseMove) {
                if (_evCompress & EvCompress.mouseMove && !(_evCompress & EvCompress.click)) {
                    auto prev = getEvent!PlMouseEvent(PlEventType.mouseMove);
                    auto cur = cast(PlMouseEvent)ev;
                    prev.point = cur.point;
                    prev.modifiers = prev.modifiers | cur.modifiers;
                }
                else {
                    _events ~= ev;
                    _evCompress |= EvCompress.mouseMove;
                }
            }
            else {
                if (ev.type == PlEventType.mouseDown || ev.type == PlEventType.mouseUp) {
                    _evCompress |= EvCompress.click;
                }
                else if (ev.type == PlEventType.show) {
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

        void styleAndLayout()
        {
            if (!_root) return;

            if (_dirtyStyle) {
                import dgt.css.cascade : cssCascade;
                cssCascade(_root);
                _dirtyStyle = false;
            }

            if (_dirtyLayout) {
                import dgt.view.layout : MeasureSpec;
                immutable fs = cast(FSize)size;
                _root.measure(
                    MeasureSpec.makeAtMost(fs.width),
                    MeasureSpec.makeAtMost(fs.height)
                );
                _root.layout(FRect(0, 0, fs));
                _dirtyLayout = false;
            }
        }

        immutable(RenderFrame) collectFrame()
        {
            scope(exit) _dirtyReg = new Region;

            if (!_root) {
                return new immutable RenderFrame (
                    nativeHandle, IRect(0, 0, size)
                );
            }

            styleAndLayout();

            import dgt.render.node : GroupRenderNode;
            immutable rn = _root.collectRenderNode();
            immutable bg = _root.backgroundRenderNode();
            immutable fn = bg ?
                new immutable GroupRenderNode(_root.localRect, [bg, rn]) :
                rn;
            return new immutable RenderFrame (
                nativeHandle, IRect(0, 0, size), fn
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

        void handleMouseDown(PlMouseEvent ev)
        {
            assert(ev.type == PlEventType.mouseDown);
            _onMouse.fire(ev);
            if (!ev.consumed) _onMouseDown.fire(ev);
            if (!ev.consumed && _root) {
                import std.typecons : scoped;

                immutable pos = cast(FVec2)ev.point;

                if (!_mouseNodes.length) {
                    errorf("mouse down without prior move");
                    _root.viewsAtPos(pos, _mouseNodes);
                }
                _dragChain = _mouseNodes;

                auto sceneEv = scoped!MouseEvent(
                    EventType.mouseDown, _dragChain, pos, pos, ev.button, ev.state, ev.modifiers
                );
                auto consumer = sceneEv.chainToNext();
                if (consumer) {
                    // if a view has explicitely consumed the event, we trim
                    // the chain after it, such as its children won't receive
                    // the drag event.
                    import std.algorithm : countUntil;
                    auto ind = _dragChain.countUntil!"a is b"(consumer);
                    _dragChain = _dragChain[0 .. ind+1];
                }
            }
        }

        void handleMouseMove(PlMouseEvent ev)
        {
            assert(ev.type == PlEventType.mouseMove);
            _onMouse.fire(ev);
            if (!ev.consumed) _onMouseUp.fire(ev);
            if (!ev.consumed && _root) {
                import std.algorithm : swap;
                import std.typecons : scoped;

                immutable pos = cast(FPoint)ev.point;

                assert(!_tempNodes.length);
                _root.viewsAtPos(pos, _tempNodes);
                checkEnterLeave(_mouseNodes, _tempNodes, ev);

                swap(_mouseNodes, _tempNodes);
                _tempNodes.length = 0;

                if (_dragChain.length) {
                    auto dragEv = scoped!MouseEvent(
                        EventType.mouseDrag, _dragChain, pos, pos,
                        ev.button, ev.state, ev.modifiers
                    );
                    dragEv.chainToNext();
                }
                else {
                    auto moveEv = scoped!MouseEvent(
                        EventType.mouseMove, _mouseNodes, pos, pos,
                        ev.button, ev.state, ev.modifiers
                    );
                    moveEv.chainToNext();
                }
            }
        }

        void handleMouseUp(PlMouseEvent ev)
        {
            assert(ev.type == PlEventType.mouseUp);
            _onMouse.fire(ev);
            if (!ev.consumed) _onMouseUp.fire(ev);
            if (!ev.consumed && _root) {
                import std.typecons : scoped;

                immutable pos = cast(FVec2)ev.point;

                if (_dragChain.length) {
                    auto upEv = scoped!MouseEvent(
                        EventType.mouseUp, _dragChain, pos, pos,
                        ev.button, ev.state, ev.modifiers
                    );
                    upEv.chainToNext();

                    if (_mouseNodes.length >= _dragChain.length &&
                        _dragChain[$-1] is _mouseNodes[_dragChain.length-1])
                    {
                        // still on same view => trigger click
                        auto clickEv = scoped!MouseEvent(
                            EventType.mouseClick, _dragChain, pos, pos,
                            ev.button, ev.state, ev.modifiers
                        );
                        clickEv.chainToNext();
                    }

                    _dragChain.length = 0;
                }
                else {
                    // should not happen
                    warning("mouse up without drag?");
                    auto upEv = scoped!MouseEvent(
                        EventType.mouseUp, _mouseNodes, pos, pos,
                        ev.button, ev.state, ev.modifiers
                    );
                    upEv.chainToNext();
                }

                _mouseNodes.length = 0;
            }
        }

        void handleMouseEnter(PlMouseEvent ev)
        {
            if (_root) {
                import std.algorithm : swap;
                immutable pos = cast(FPoint)ev.point;

                if (_mouseNodes.length) {
                    errorf("Enter window while having already nodes under mouse??");
                    _mouseNodes.length = 0;
                }
                assert(!_tempNodes.length);
                _root.viewsAtPos(pos, _mouseNodes);
                checkEnterLeave(_tempNodes, _mouseNodes, ev);
            }
        }

        void handleMouseLeave(PlMouseEvent ev)
        {
            if (_root) {
                import std.algorithm : swap;
                immutable pos = cast(FPoint)ev.point;

                assert(!_tempNodes.length);
                checkEnterLeave(_mouseNodes, _tempNodes, ev);

                swap(_mouseNodes, _tempNodes);
                _tempNodes.length = 0;
            }
        }

        static void emitEnterLeave(View view, EventType type, PlMouseEvent src)
        {
            import std.typecons : scoped;
            immutable scPos = cast(FPoint)src.point;
            auto ev = scoped!MouseEvent(
                type, [view], scPos - view.scenePos, scPos, src.button, src.state, src.modifiers
            );
            ev.chainToNext();
        }

        static checkEnterLeave(View[] was, View[] now, PlMouseEvent src)
        {
            import std.algorithm : min;
            immutable common = min(was.length, now.length);
            foreach (i; 0 .. common) {
                if (was[i] !is now[i]) {
                    emitEnterLeave(was[i], EventType.mouseLeave, src);
                    emitEnterLeave(now[i], EventType.mouseEnter, src);
                }
            }
            foreach (n; was[common .. $]) {
                emitEnterLeave(n, EventType.mouseLeave, src);
            }
            foreach (n; now[common .. $]) {
                emitEnterLeave(n, EventType.mouseEnter, src);
            }
        }

        EvT getEvent(EvT)(PlEventType type)
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
        PlatformWindow _platformWindow;
        string _title;
        IPoint _position = IPoint(-1, -1);
        ISize _size;
        GlAttribs _attribs;
        FVec4 _clearColor;
        bool _hasClearColor;

        View _root;
        View[] _dragChain;
        View[] _mouseNodes;
        View[] _tempNodes;

        EvCompress _evCompress = EvCompress.fstFrame;
        WindowEvent[] _events;

        Rebindable!Region _dirtyReg = new Region;
        bool _dirtyStyle    = true;
        bool _dirtyLayout   = true;
        bool _dirtyContent  = true;

        FireableSignal!string    _onTitleChange = new FireableSignal!string;
        Handler!ShowEvent        _onShow        = new Handler!ShowEvent;
        Handler!HideEvent        _onHide        = new Handler!HideEvent;
        Handler!MoveEvent        _onMove        = new Handler!MoveEvent;
        Handler!ResizeEvent      _onResize      = new Handler!ResizeEvent;
        Handler!PlMouseEvent       _onMouse       = new Handler!PlMouseEvent;
        Handler!PlMouseEvent       _onMouseDown   = new Handler!PlMouseEvent;
        Handler!PlMouseEvent       _onMouseUp     = new Handler!PlMouseEvent;
        Handler!PlKeyEvent         _onKey         = new Handler!PlKeyEvent;
        Handler!PlKeyEvent         _onKeyDown     = new Handler!PlKeyEvent;
        Handler!PlKeyEvent         _onKeyUp       = new Handler!PlKeyEvent;
        Handler!StateChangeEvent _onStateChange = new Handler!StateChangeEvent;
        Handler!CloseEvent       _onClose       = new Handler!CloseEvent;
        FireableSignal!Window    _onClosed      = new FireableSignal!Window;
    }

    // scene graph reserved fields and methods
package(dgt):

    Object sgData;

}
