module dgt.window;

import dgt.platform;
import dgt.application;
import dgt.surface;
import dgt.geometry;
import dgt.event;
import dgt.core.signal;
import dgt.core.util;
import dgt.vg;

import std.exception : enforce;

enum WindowState
{
    normal,
    maximized,
    minimized,
    fullscreen,
    hidden
}

interface OnWindowMoveHandler
{
    void onWindowMove(WindowMoveEvent ev);
}

interface OnWindowResizeHandler
{
    void onWindowResize(WindowResizeEvent ev);
}

interface OnWindowMouseHandler
{
    void onWindowMouse(WindowMouseEvent ev);
}

interface OnWindowMouseDownHandler
{
    void onWindowMouseDown(WindowMouseEvent ev);
}

interface OnWindowMouseUpHandler
{
    void onWindowMouseUp(WindowMouseEvent ev);
}

interface OnWindowKeyHandler
{
    void onWindowKey(WindowKeyEvent ev);
}

interface OnWindowKeyDownHandler
{
    void onWindowKeyDown(WindowKeyEvent ev);
}

interface OnWindowKeyUpHandler
{
    void onWindowKeyUp(WindowKeyEvent ev);
}

interface OnWindowStateChangeHandler
{
    void onWindowStateChange(WindowStateChangeEvent ev);
}

interface OnWindowCloseHandler
{
    void onWindowClose(WindowCloseEvent ev);
}

interface OnWindowExposeHandler
{
    void onWindowExpose(WindowExposeEvent ev);
}

class Window : Surface
{
    this()
    {
        _platformWindow = Application.platform.createWindow(this);
        Application.instance.registerWindow(this);
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

    override @property ISize size() const
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

    @property SurfaceAttribs attribs() const
    {
        return _attribs;
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
        if (!_platformWindow.created)
        {
            _platformWindow.create(state);
        }
        else
        {
            _platformWindow.state = state;
        }
    }

    void close()
    {
        enforce(_platformWindow.created, "attempt to close a non-created window");
        _platformWindow.close();
        _onClosed.fire(this);
        Application.instance.unregisterWindow(this);
    }

    mixin SignalMixin!("onTitleChange", string);
    mixin EventHandlerSignalMixin!("onMove", OnWindowMoveHandler);
    mixin EventHandlerSignalMixin!("onResize", OnWindowResizeHandler);
    mixin EventHandlerSignalMixin!("onMouse", OnWindowMouseHandler);
    mixin EventHandlerSignalMixin!("onMouseDown", OnWindowMouseDownHandler);
    mixin EventHandlerSignalMixin!("onMouseUp", OnWindowMouseUpHandler);
    mixin EventHandlerSignalMixin!("onKey", OnWindowKeyHandler);
    mixin EventHandlerSignalMixin!("onKeyDown", OnWindowKeyDownHandler);
    mixin EventHandlerSignalMixin!("onKeyUp", OnWindowKeyUpHandler);
    mixin EventHandlerSignalMixin!("onStateChange", OnWindowStateChangeHandler);
    mixin EventHandlerSignalMixin!("onExpose", OnWindowExposeHandler);
    mixin EventHandlerSignalMixin!("onClose", OnWindowCloseHandler);
    mixin SignalMixin!("onClosed", Window);

    void handleEvent(WindowEvent wEv)
    {
        assert(wEv.window is this);
        switch (wEv.type)
        {
        case EventType.windowExpose:
            _onExpose.fire(cast(WindowExposeEvent) wEv);
            _platformWindow.drawingBuffer.flushTo(_platformWindow);
            break;
        case EventType.windowMove:
            auto wmEv = cast(WindowMoveEvent) wEv;
            _position = wmEv.point;
            _onMove.fire(cast(WindowMoveEvent) wEv);
            break;
        case EventType.windowResize:
            auto rsEv = cast(WindowResizeEvent) wEv;
            _size = rsEv.size;
            _onResize.fire(rsEv);
            break;
        case EventType.windowMouseDown:
            _onMouse.fire(cast(WindowMouseEvent) wEv);
            if (!wEv.consumed)
            {
                _onMouseDown.fire(cast(WindowMouseEvent) wEv);
            }
            break;
        case EventType.windowMouseUp:
            _onMouse.fire(cast(WindowMouseEvent) wEv);
            if (!wEv.consumed)
            {
                _onMouseUp.fire(cast(WindowMouseEvent) wEv);
            }
            break;
        case EventType.windowKeyDown:
            auto kEv = cast(WindowKeyEvent) wEv;
            _onKey.fire(kEv);
            if (!kEv.consumed)
            {
                _onKeyDown.fire(kEv);
            }
            break;
        case EventType.windowKeyUp:
            auto kEv = cast(WindowKeyEvent) wEv;
            _onKey.fire(kEv);
            if (!kEv.consumed)
            {
                _onKeyUp.fire(kEv);
            }
            break;
        case EventType.windowStateChange:
            _onStateChange.fire(cast(WindowStateChangeEvent) wEv);
            break;
        case EventType.windowClose:
            auto cev = cast(WindowCloseEvent) wEv;
            _onClose.fire(cev);
            if (!cev.declined)
                close();
            break;
        default:
            break;
        }
    }

    /// Return a vector graphics surface to draw into this window.
    @property VgSurface surface()
    {
        return _platformWindow.surface;
    }

    private
    {
        IPoint _position = IPoint(-1, -1);
        ISize _size;
        SurfaceAttribs _attribs;
        PlatformWindow _platformWindow;
    }
}
