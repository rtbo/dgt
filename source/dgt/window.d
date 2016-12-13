module dgt.window;

import dgt.platform;
import dgt.application;
import dgt.surface;
import dgt.geometry;

enum WindowState
{
    normal,
    maximized,
    minimized,
    fullscreen,
    hidden
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


    private
    {
        IPoint position_ = IPoint(-1, -1);
        ISize size_;
        SurfaceAttribs attribs_;
        PlatformWindow platformWindow_;
    }
}