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

import gfx.device.gl3;
import gfx.device;
import gfx.pipeline;
import gfx.foundation.util;

import std.exception : enforce;
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
        disposeGfx();
        _platformWindow.close();
        _onClosed.fire(this);
        Application.instance.unregisterWindow(this);
    }

    @property size_t nativeHandle() const
    {
        enforce(_platformWindow.created);
        return _platformWindow.created;
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

    Image beginFrame()
    {
        enforce(!_renderBuf, "cannot call Window.beginFrame without a " ~
                            "Window.endFrame");
        if (!_context) {
            _context = new GlContext(this);
        }
        enforce(_context.makeCurrent(_platformWindow.nativeHandle));

        if (!_device) {
            prepareGfx();
        }

        immutable format = ImageFormat.argbPremult;
        _renderBuf = new MallocImage(format, _size, format.vgBytesForWidth(_size.width));

        _encoder.setViewport(0, 0, cast(ushort)_size.width, cast(ushort)_size.height);

        return _renderBuf;
    }

    void endFrame(Image img)
    {
        enforce(_renderBuf && _renderBuf.img is img, "must call Window.endFrame with a " ~
                              "surface matching Window.beginFrame");
        assert(img.size.contains(_size));

        _surf.updateSize(cast(ushort)_size.width, cast(ushort)_size.height);

        _encoder.clear!Rgba8(_rtv, [0.3f, 0.4f, 0.5f, 1f]);

        blitAsTexture(img);

        _encoder.flush(_device);

        _renderBuf.dispose();
        _renderBuf = null;
        _context.doneCurrent();
        _context.swapBuffers(_platformWindow.nativeHandle);
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
        void handleResize(WindowResizeEvent ev)
        {
            immutable newSize = ev.size;
            _size = newSize;
            _onResize.fire(ev);
        }

        void prepareGfx()
        {
            _device = createGlDevice();
            _device.retain();

            _surf = new BuiltinSurface!Rgba8(
                _device.builtinSurface,
                cast(ushort)_size.width, cast(ushort)_size.height,
                attribs.samples
            );
            _surf.retain();

            _rtv = _surf.viewAsRenderTarget();
            _rtv.retain();

            _prog = new Program(ShaderSet.vertexPixel(
                texBlitVShader, texBlitFShader
            ));
            _prog.retain();

            _pso = new TexBlitPipeline(_prog, Primitive.Triangles, Rasterizer.fill.withSamples());
            _pso.retain();

            _encoder = Encoder(_device.makeCommandBuffer());
        }

        void disposeGfx()
        {
            if (!_device) return;
            assert(_context);
            _context.makeCurrent(_platformWindow.nativeHandle);
            scope(exit) _context.doneCurrent();

            _encoder = Encoder.init;
            _pso.release();
            _prog.release();
            _rtv.release();
            _surf.release();
        }

        void blitAsTexture(Image img)
        {
            auto pixels = retypeSlice!(const(ubyte[4]))(img.data);
            TexUsageFlags usage = TextureUsage.ShaderResource;
            auto tex = makeRc!(Texture2D!Rgba8)(
                usage, ubyte(1), cast(ushort)img.width, cast(ushort)img.height, [pixels]
            );
            auto srv = tex.viewAsShaderResource(0, 0, newSwizzle()).rc();
            auto sampler = makeRc!Sampler(
                srv, SamplerInfo(FilterMethod.Anisotropic, WrapMode.init)
            );

            auto quadVerts = [
                TexBlitVertex([-1f, -1f], [0f, 1f]),
                TexBlitVertex([1f, -1f], [1f, 1f]),
                TexBlitVertex([1f, 1f], [1f, 0f]),
                TexBlitVertex([-1f, 1f], [0f, 0f])
            ];
            ushort[] quadInds = [0, 1, 2, 0, 2, 3];
            auto vbuf = makeRc!(VertexBuffer!TexBlitVertex)(quadVerts);

            auto slice = VertexBufferSlice(new IndexBuffer!ushort(quadInds));

            auto data = TexBlitPipeline.Data(
                vbuf, srv, sampler, rc(_rtv)
            );

            _encoder.draw!TexBlitPipeMeta(slice, _pso, data);
        }

        WindowFlags _flags;
        string _title;
        IPoint _position = IPoint(-1, -1);
        ISize _size;
        GlAttribs _attribs;
        PlatformWindow _platformWindow;
        GlContext _context;

        GfxDevice _device;
        BuiltinSurface!Rgba8 _surf;
        RenderTargetView!Rgba8 _rtv;
        Program _prog;
        TexBlitPipeline _pso;
        Encoder _encoder;

        // transient rendering state
        MallocImage _renderBuf;
    }
}

struct TexBlitVertex {
    @GfxName("a_Pos")       float[2] pos;
    @GfxName("a_TexCoord")  float[2] texCoord;
}

struct TexBlitPipeMeta {
    VertexInput!TexBlitVertex   input;

    @GfxName("t_Sampler")
    ResourceView!Rgba8          texture;

    @GfxName("t_Sampler")
    ResourceSampler             sampler;

    @GfxName("o_Color")
    ColorOutput!Rgba8           outColor;
}

alias TexBlitPipeline = PipelineState!TexBlitPipeMeta;

enum texBlitVShader = `
    #version 330
    in vec2 a_Pos;
    in vec2 a_TexCoord;

    out vec2 v_TexCoord;

    void main() {
        v_TexCoord = a_TexCoord;
        gl_Position = vec4(a_Pos, 0.0, 1.0);
    }
`;
version(LittleEndian)
{
    // ImageFormat order is argb, in native order (that is actually bgra)
    // the framebuffer order is rgba, so some swizzling is needed
    enum texBlitFShader = `
        #version 330

        in vec2 v_TexCoord;
        out vec4 o_Color;
        uniform sampler2D t_Sampler;

        void main() {
            vec4 sample = texture(t_Sampler, v_TexCoord);
            o_Color = sample.bgra;
        }
    `;
}
version(BigEndian)
{
    // ImageFormat order is argb, in native order
    // the framebuffer order is rgba, so a left shift is needed
    enum texBlitFShader = `
        #version 330

        in vec2 v_TexCoord;
        out vec4 o_Color;
        uniform sampler2D t_Sampler;

        void main() {
            vec4 sample = texture(t_Sampler, v_TexCoord);
            o_Color = sample.gbar;
        }
    `;
}