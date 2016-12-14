module dgt.window;

import dgt.platform;
import dgt.application;
import dgt.surface;
import dgt.geometry;
import dgt.event;
import dgt.signal;
import dgt.util;

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
        platformWindow_ = Application.platform.createWindow(this);
    }


    @property IPoint position() const
    {
        return position_;
    }

    override @property ISize size() const
    {
        return size_;
    }

    @property void size(ISize size)
    {
        size_ = size;
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

    void show(WindowState state=WindowState.normal)
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
        case EventType.windowKeyDown:
            auto kEv = cast(WindowKeyEvent)wEv;
            onKey_.fire(kEv);
            if (!kEv.consumed) {
                onKeyDown_.fire(kEv);
            }
            break;
        case EventType.windowKeyUp:
            auto kEv = cast(WindowKeyEvent)wEv;
            onKey_.fire(kEv);
            if (!kEv.consumed) {
                onKeyUp_.fire(kEv);
            }
            break;
        case EventType.windowClose:
            auto cev = cast(WindowCloseEvent)wEv;
            onClose_.fire(cev);
            if (!cev.declined) close();
            break;
        default:
            break;
        }

    }


    private
    {
        IPoint position_ = IPoint(-1, -1);
        ISize size_;
        SurfaceAttribs attribs_;
        PlatformWindow platformWindow_;
    }
}