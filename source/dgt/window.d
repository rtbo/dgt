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
import dgt.sg.renderframe;
import dgt.sg.rendernode;
import dgt.sg.renderer;

import std.exception;
import std.experimental.logger;
import std.concurrency : Tid;

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


class Window
{
    this(WindowFlags flags=WindowFlags.none)
    {
        _flags = flags;
        _platformWindow = Application.platform.createWindow(this);
        Application.instance.registerWindow(this);
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

            if (_size.area == 0) {
                _size = ISize(640, 480);
            }

            _platformWindow.create();
            if (!(_flags & WindowFlags.dummy)) {
                assert(!_gfxRunning);
                initializeGfx();
            }
        }

        if (!(_flags & WindowFlags.dummy))
            _platformWindow.state = state;
    }

    void close()
    {
        enforce(_platformWindow.created, "attempt to close a non-created window");
        if (_gfxRunning) finalizeGfx();
        _platformWindow.close();
        _onClosed.fire(this);
        Application.instance.unregisterWindow(this);
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
    mixin EventHandlerSignalMixin!("onExpose", OnWindowExposeHandler);
    mixin EventHandlerSignalMixin!("onClose", OnWindowCloseHandler);
    mixin SignalMixin!("onClosed", Window);

    alias FrameRequestHandler = immutable(RenderFrame) delegate();
    @property void onRequestFrame(FrameRequestHandler handler)
    {
        if (_onRequestFrame) {
            warning("overriding RequestFrameHandler");
        }
        _onRequestFrame = handler;
    }



    void handleEvent(WindowEvent wEv)
    {
        assert(wEv.window is this);
        switch (wEv.type)
        {
        case EventType.windowExpose:
            handleExpose(cast(WindowExposeEvent)wEv);
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

    Image beginFrame()
    {
        enforce(!_renderBuf, "cannot call Window.beginFrame without a " ~
                            "Window.endFrame");

        immutable format = ImageFormat.argbPremult;
        _renderBuf = new Image(format, _size, format.vgBytesForWidth(_size.width));

        return _renderBuf;
    }

    void endFrame(Image img)
    {
        enforce(_renderBuf && _renderBuf is img, "must call Window.endFrame with a " ~
                              "surface matching Window.beginFrame");
        assert(img.size.contains(_size));
        img = null; // still have _renderBuf


        immutable node = new immutable ImageRenderNode(
            fvec(0, 0), assumeUnique(_renderBuf)
        );

        renderFrame(_renderTid, new immutable(RenderFrame)(
            nativeHandle, IRect(0, 0, size), fvec(0.3f, 0.4f, 0.5f, 1), node
        ));
    }

    package(dgt)
    {
        @property inout(PlatformWindow) platformWindow() inout
        {
            return _platformWindow;
        }
    }

    private
    {
        void initializeGfx()
        {
            shared ctx = createGlContext(this);
            _renderTid = startRenderLoop(ctx);
            _gfxRunning = true;
        }

        void finalizeGfx()
        {
            finalizeRenderLoop(_renderTid, nativeHandle);
            _gfxRunning = false;
        }

        void handleResize(WindowResizeEvent ev)
        {
            immutable newSize = ev.size;
            _size = newSize;
            _onResize.fire(ev);
        }

        void handleExpose(WindowExposeEvent ev)
        {
            _onExpose.fire(ev);

            // if (!_context) {
            //     _context = createGlContext(this);
            // }
            // if (!_renderStarted) {
            //     _renderTid = startRenderLoop(_context);
            //     _rendererRunning = true;
            // }

            // Render frame!
        }

        WindowFlags _flags;
        string _title;
        IPoint _position = IPoint(-1, -1);
        ISize _size;
        GlAttribs _attribs;
        PlatformWindow _platformWindow;
        shared(GlContext) _context;
        Tid _renderTid;
        bool _gfxRunning;
        FrameRequestHandler _onRequestFrame;

        // transient rendering state
        Image _renderBuf;

    }
}
