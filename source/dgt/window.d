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
import dgt.sg.parent;
import dgt.signal;
import dgt.util;

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

interface OnWindowShowHandler
{
    void onWindowMove(ShowEvent ev);
}

interface OnWindowHideHandler
{
    void onWindowHide(HideEvent ev);
}

interface OnWindowMoveHandler
{
    void onWindowMove(MoveEvent ev);
}

interface OnWindowResizeHandler
{
    void onWindowResize(ResizeEvent ev);
}

interface OnWindowMouseHandler
{
    void onWindowMouse(MouseEvent ev);
}

interface OnWindowMouseDownHandler
{
    void onWindowMouseDown(MouseEvent ev);
}

interface OnWindowMouseUpHandler
{
    void onWindowMouseUp(MouseEvent ev);
}

interface OnWindowKeyHandler
{
    void onWindowKey(KeyEvent ev);
}

interface OnWindowKeyDownHandler
{
    void onWindowKeyDown(KeyEvent ev);
}

interface OnWindowKeyUpHandler
{
    void onWindowKeyUp(KeyEvent ev);
}

interface OnWindowStateChangeHandler
{
    void onWindowStateChange(StateChangeEvent ev);
}

interface OnWindowCloseHandler
{
    void onWindowClose(CloseEvent ev);
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

    mixin SignalMixin!("onTitleChange", string);
    mixin EventHandlerSignalMixin!("onShow", OnWindowShowHandler);
    mixin EventHandlerSignalMixin!("onHide", OnWindowHideHandler);
    mixin EventHandlerSignalMixin!("onMove", OnWindowMoveHandler);
    mixin EventHandlerSignalMixin!("onResize", OnWindowResizeHandler);
    mixin EventHandlerSignalMixin!("onMouse", OnWindowMouseHandler);
    mixin EventHandlerSignalMixin!("onMouseDown", OnWindowMouseDownHandler);
    mixin EventHandlerSignalMixin!("onMouseUp", OnWindowMouseUpHandler);
    mixin EventHandlerSignalMixin!("onKey", OnWindowKeyHandler);
    mixin EventHandlerSignalMixin!("onKeyDown", OnWindowKeyDownHandler);
    mixin EventHandlerSignalMixin!("onKeyUp", OnWindowKeyUpHandler);
    mixin EventHandlerSignalMixin!("onStateChange", OnWindowStateChangeHandler);
    mixin EventHandlerSignalMixin!("onClose", OnWindowCloseHandler);
    mixin SignalMixin!("onClosed", Window);


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
        _root._window = this;
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
            _onMouse.fire(cast(MouseEvent) wEv);
            if (!wEv.consumed)
            {
                _onMouseDown.fire(cast(MouseEvent) wEv);
            }
            break;
        case EventType.mouseUp:
            _onMouse.fire(cast(MouseEvent) wEv);
            if (!wEv.consumed)
            {
                _onMouseUp.fire(cast(MouseEvent) wEv);
            }
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
                import dgt.sg.layout : MeasureSpec;
                immutable fs = cast(FSize)size;
                _root.measure(
                    MeasureSpec.makeAtMost(fs.width),
                    MeasureSpec.makeAtMost(fs.height)
                );
                _root.layout(FRect(0, 0, fs));
            }
            return new immutable RenderFrame (
                nativeHandle, IRect(0, 0, size), fvec(0.6, 0.7, 0.8, 1),
                _root ? _root.collectRenderNode() : null
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
            if (_root) {
                //RenderThread.instance.frame(collectFrame);
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

        EvCompress _evCompress = EvCompress.fstFrame;
        WindowEvent[] _events;

        Rebindable!Region _dirtyReg = new Region;
    }
}
