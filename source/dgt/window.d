/// Window creation and manipulation
module dgt.window;

import gfx.foundation.rc;
import dgt.signal;
import dgt.util;
import dgt.platform;
import dgt.application;
import dgt.geometry;
import dgt.event;
import dgt.image;
import dgt.context;
import dgt.vg;
import dgt.math;
import dgt.render;
import dgt.render.frame;
import dgt.sg.parent;

import std.exception;
import std.experimental.logger;

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
        return _title;
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
        return _position;
    }

    @property void position(in IPoint position)
    {
        if (position != _position)
        {
            if (_platformWindow.created)
            {
                _platformWindow.geometry = IRect(_position, _size);
            }
            else
            {
                _position = position;
            }
        }
    }

    @property ISize size() const
    {
        return _size;
    }

    @property void size(in ISize size)
    {
        if (size != _size)
        {
            if (_platformWindow.created)
            {
                _platformWindow.geometry = IRect(_position, size);
            }
            else
            {
                _size = size;
            }
        }
    }

    @property IRect geometry() const
    {
        return IRect(_position, _size);
    }

    @property void geometry(in IRect rect)
    {
        if (rect.size != _size || rect.point != _position)
        {
            if (_platformWindow.created)
            {
                _platformWindow.geometry = IRect(_position, size);
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

        immutable(RenderFrame) collectFrame()
        {
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
        }

        void handleExpose(ExposeEvent ev)
        {
            if (_root) {
                //RenderThread.instance.frame(collectFrame);
            }
        }

        WindowFlags _flags;
        string _title;
        IPoint _position = IPoint(-1, -1);
        ISize _size;
        GlAttribs _attribs;
        PlatformWindow _platformWindow;
        SgParent _root;
    }
}
