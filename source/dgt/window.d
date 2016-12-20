module dgt.window;

import dgt.platform;
import dgt.application;
import dgt.surface;
import dgt.geometry;
import dgt.event;
import dgt.signal;
import dgt.util;
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

class Window : Surface, VgSurface
{
    this()
    {
        platformWindow_ = Application.platform.createWindow(this);
    }

    @property IPoint position() const
    {
        return position_;
    }

    @property void position(in IPoint position)
    {
        if (position != position_)
        {
            if (platformWindow_.created)
            {
                platformWindow_.geometry = IRect(position_, size_);
            }
            else
            {
                position_ = position;
            }
        }
    }

    override @property ISize size() const
    {
        return size_;
    }

    @property void size(in ISize size)
    {
        if (size != size_)
        {
            if (platformWindow_.created)
            {
                platformWindow_.geometry = IRect(position_, size);
            }
            else
            {
                size_ = size;
            }
        }
    }

    @property IRect geometry() const
    {
        return IRect(position_, size_);
    }

    @property void geometry(in IRect rect)
    {
        if (rect.size != size_ || rect.point != position_)
        {
            if (platformWindow_.created)
            {
                platformWindow_.geometry = IRect(position_, size);
            }
            else
            {
                position_ = rect.point;
                size_ = rect.size;
            }
        }
    }

    @property SurfaceAttribs attribs() const
    {
        return attribs_;
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
        if (!platformWindow_.created)
        {
            platformWindow_.create(state);
        }
        else
        {
            platformWindow_.state = state;
        }
    }

    void close()
    {
        enforce(platformWindow_.created, "attempt to close a non-created window");
        platformWindow_.close();
        onClosed_.fire(this);
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
            onExpose_.fire(cast(WindowExposeEvent) wEv);
            break;
        case EventType.windowMove:
            auto wmEv = cast(WindowMoveEvent) wEv;
            position_ = wmEv.point;
            onMove_.fire(cast(WindowMoveEvent) wEv);
            break;
        case EventType.windowResize:
            auto rsEv = cast(WindowResizeEvent) wEv;
            size_ = rsEv.size;
            onResize_.fire(rsEv);
            break;
        case EventType.windowMouseDown:
            onMouse_.fire(cast(WindowMouseEvent) wEv);
            if (!wEv.consumed)
            {
                onMouseDown_.fire(cast(WindowMouseEvent) wEv);
            }
            break;
        case EventType.windowMouseUp:
            onMouse_.fire(cast(WindowMouseEvent) wEv);
            if (!wEv.consumed)
            {
                onMouseUp_.fire(cast(WindowMouseEvent) wEv);
            }
            break;
        case EventType.windowKeyDown:
            auto kEv = cast(WindowKeyEvent) wEv;
            onKey_.fire(kEv);
            if (!kEv.consumed)
            {
                onKeyDown_.fire(kEv);
            }
            break;
        case EventType.windowKeyUp:
            auto kEv = cast(WindowKeyEvent) wEv;
            onKey_.fire(kEv);
            if (!kEv.consumed)
            {
                onKeyUp_.fire(kEv);
            }
            break;
        case EventType.windowStateChange:
            onStateChange_.fire(cast(WindowStateChangeEvent) wEv);
            break;
        case EventType.windowClose:
            auto cev = cast(WindowCloseEvent) wEv;
            onClose_.fire(cev);
            if (!cev.declined)
                close();
            break;
        default:
            break;
        }
    }

    override @property VgFactory vgFactory()
    {
        return platformWindow_.vgFactory;
    }

    private
    {
        IPoint position_ = IPoint(-1, -1);
        ISize size_;
        SurfaceAttribs attribs_;
        PlatformWindow platformWindow_;
    }
}
