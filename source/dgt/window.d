module dgt.window;

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

final class CloseEvent
{
    void decline() {
        _declined = true;
    }

    @property bool declined() const {
        return _declined;
    }

    @property void declined(in bool value) {
        _declined = value;
    }

    private bool _declined = false;
}

class Window
{
    import dgt.gfx.geometry : IPoint, IRect, ISize;
    import dgt.core.signal : Handler, Slot;
    import dgt.platform : PlatformWindow;
    import dgt.platform.event : PlWindowEvent;
    import dgt.ui : UserInterface;
    import gfx.gl3.context : GlAttribs;

    this(WindowFlags flags=WindowFlags.none)
    {
        import dgt.application : Application;
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
        import dgt.application : Application;
        import dgt.gfx.geometry : area;


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
        import dgt.application : Application;
        import std.exception : enforce;

        enforce(_platformWindow.created, "attempt to close a non-created window");
        if (!dummy) Application.instance.unregisterWindow(this);
        _platformWindow.close();
        // _onClosed.fire(this);
    }

    @property void onStateChange(Slot!WindowState slot)
    {
        _onStateChange.set(slot);
    }

    @property size_t nativeHandle() const
    {
        import std.exception : enforce;

        enforce(_platformWindow.created);
        return _platformWindow.nativeHandle;
    }

    void handleEvent(PlWindowEvent wEv)
    {
        import dgt.platform.event;

        assert(wEv.window is this);
        switch (wEv.type)
        {
        case PlEventType.move:
            auto mEv = cast(PlMoveEvent) wEv;
            _position = mEv.point;
            break;
        case PlEventType.resize:
            auto rEv = cast(PlResizeEvent)wEv;
            _size = rEv.size;
            if (_ui) _ui.handleEvent(wEv);
            break;
        case PlEventType.stateChange:
            auto scEv = cast(PlStateChangeEvent)wEv;
            _onStateChange.fire(scEv.state);
            break;
        case PlEventType.closeRequest:
            auto cev = new CloseEvent;
            _onClose.fire(cev);
            if (!cev.declined) close();
            break;
        default:
            if (_ui) _ui.handleEvent(wEv);
            break;
        }
    }

    @property UserInterface ui() {
        return _ui;
    }

    @property void ui(UserInterface ui)
    {
        import dgt.platform.event : PlResizeEvent;
        import dgt.gfx.geometry : area;

        _ui = ui;
        if (_ui && size.area) {
            _ui.handleEvent(new PlResizeEvent(this, size));
        }
    }

    package(dgt)
    {
        import dgt.platform.event : PlEventType;

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

        void compressEvent(PlWindowEvent ev)
        {
            import dgt.platform.event : PlMoveEvent, PlMouseEvent, PlResizeEvent;

            if (ev.type == PlEventType.move) {
                if (_evCompress & EvCompress.move) {
                    auto prev = getEvent!PlMoveEvent(PlEventType.move);
                    auto cur = cast(PlMoveEvent)ev;
                    prev.point = cur.point;
                }
                else {
                    _events ~= ev;
                    _evCompress |= EvCompress.move;
                }
            }
            else if (ev.type == PlEventType.resize) {
                if (_evCompress & EvCompress.resize) {
                    auto prev = getEvent!PlResizeEvent(PlEventType.resize);
                    auto cur = cast(PlResizeEvent)ev;
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
            import dgt.platform.event : PlResizeEvent, PlShowEvent;

            if (_evCompress & EvCompress.fstFrame) {
                if (!(_evCompress & EvCompress.show)) {
                    handleEvent(new PlShowEvent(this));
                }
                if (!(_evCompress & EvCompress.resize)) {
                    handleEvent(new PlResizeEvent(this, size));
                }
            }
            foreach(ev; _events) {
                handleEvent(ev);
            }
            _events = [];
            _evCompress = EvCompress.none;
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

    }

    private WindowFlags _flags;
    private PlatformWindow _platformWindow;
    private string _title;
    private IPoint _position = IPoint(-1, -1);
    private ISize _size;
    private GlAttribs _attribs;

    private EvCompress _evCompress = EvCompress.fstFrame;
    private PlWindowEvent[] _events;
    private Handler!CloseEvent _onClose = new Handler!CloseEvent;
    private Handler!WindowState _onStateChange = new Handler!WindowState;

    private UserInterface _ui;
}
