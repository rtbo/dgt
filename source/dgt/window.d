module dgt.window;

import dgt.application : Application;
import dgt.context : GlAttribs;
import dgt.core.geometry;
import dgt.platform : PlatformWindow;

import std.exception;


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
                _platformWindow.setTitle(title);
            }
        }
    }

    @property IPoint position() const
    {
        return rect.topLeft;
    }

    @property void position(in IPoint position)
    {
        if (position != this.position)
        {
            rect = IRect(position, size);
        }
    }

    @property ISize size() const
    {
        return rect.size;
    }

    @property void size(in ISize size)
    {
        if (size != this.size)
        {
            rect = IRect(position, size);
        }
    }

    @property IRect rect() const
    {
        if (_platformWindow.created) {
            return _platformWindow.rect;
        }
        else {
            return IRect(_position, _size);
        }
    }

    @property void rect(in IRect rect)
    {
        if (rect != rect)
        {
            if (_platformWindow.created)
            {
                _platformWindow.setRect(rect);
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
        return rect.width;
    }
    @property int height() const
    {
        return rect.height;
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
            // invalidate();
        }

        if (!dummy) _platformWindow.setState(state);
    }

    void close()
    {
        enforce(_platformWindow.created, "attempt to close a non-created window");
        if (!dummy) Application.instance.unregisterWindow(this);
        _platformWindow.close();
        // _onClosed.fire(this);
    }

    @property size_t nativeHandle() const
    {
        enforce(_platformWindow.created);
        return _platformWindow.nativeHandle;
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
    }

    private WindowFlags _flags;
    private PlatformWindow _platformWindow;
    private string _title;
    private IPoint _position = IPoint(-1, -1);
    private ISize _size;
    private GlAttribs _attribs;
}
