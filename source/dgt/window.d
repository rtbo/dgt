module dgt.window;

import dgt.core.resource;
import dgt.core.signal;
import dgt.core.util;
import dgt.platform;
import dgt.application;
import dgt.surface;
import dgt.geometry;
import dgt.event;
import dgt.image;
import dgt.vg;

import std.exception : enforce;
import std.stdio;

enum WindowState
{
    normal,
    maximized,
    minimized,
    fullscreen,
    hidden
}

interface OnWindowShowHandler
{
    void onWindowMove(WindowShowEvent ev);
}

interface OnWindowHideHandler
{
    void onWindowHide(WindowHideEvent ev);
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

    this(string title)
    {
        this();
        _title = title;
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
            break;
        case EventType.windowShow:
            _onShow.fire(cast(WindowShowEvent)wEv);
            break;
        case EventType.windowHide:
            _onHide.fire(cast(WindowHideEvent)wEv);
            break;
        case EventType.windowMove:
            auto wmEv = cast(WindowMoveEvent) wEv;
            _position = wmEv.point;
            _onMove.fire(cast(WindowMoveEvent) wEv);
            break;
        case EventType.windowResize:
            handleResize(cast(WindowResizeEvent) wEv);
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

    WindowBuffer beginFrame()
    {
        enforce(!_buf, "cannot call Window.beginFrame without a " ~
                            "Window.endFrame");
        _buf = new WindowBuffer(this, _platformWindow.makeBuffer(_size));
        return _buf;
    }

    void endFrame(WindowBuffer buf)
    {
        enforce(_buf && _buf is buf, "must call Window.endFrame with a " ~
                              "surface matching Window.beginFrame");
        assert(buf.size.contains(_size));
        _buf._surface.flush();
        _buf._buffer.blit(IPoint(0, 0), _size);
        _buf.dispose();
        _buf = null;
    }

    private
    {
        void handleResize(WindowResizeEvent ev)
        {
            immutable newSize = ev.size;
            _size = newSize;
            _onResize.fire(ev);
        }

        string _title;
        IPoint _position = IPoint(-1, -1);
        ISize _size;
        SurfaceAttribs _attribs;
        PlatformWindow _platformWindow;

        // transient rendering state
        WindowBuffer _buf;
    }
}

final class WindowBuffer : Disposable
{
    private Window _window;
    private PlatformWindowBuffer _buffer;
    private VgSurface _surface;

    private this(Window window, PlatformWindowBuffer buffer)
    {
        _window = window;
        _buffer = buffer;
        _surface = _buffer.image.makeVgSurface();
        _surface.retain();
    }

    override void dispose()
    {
        _buffer.dispose();
        _surface.release();
    }

    @property inout(Window) window() inout
    {
        return _window;
    }

    @property inout(VgSurface) surface() inout
    {
        return _surface;
    }

    @property inout(Image) image() inout
    {
        return _buffer.image;
    }

    @property ISize size() const
    {
        return image.size;
    }
}
