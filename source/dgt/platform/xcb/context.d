module dgt.platform.xcb.context;

version(linux):

package:

import dgt.platform : PlatformWindow;
import dgt.platform.xcb : g_display;
import dgt.screen : Screen;
import gfx.bindings.core : SharedLib;
import gfx.gl3.context : GlAttribs, GlContext, glVersions;
import X11.Xlib : XDisplay = Display, XErrorEvent;

GlContext createXcbGlContext(GlAttribs attribs, PlatformWindow window,
                             GlContext sharedCtx, Screen screen)
{
    const size_t windowHdl = window ? window.nativeHandle : 0;
    const int screenNum = screen ? screen.num : 0;
    auto glxSharedCtx = sharedCtx ? (cast(XcbGlContext)sharedCtx)._ctx : null;

    return new XcbGlContext(windowHdl, screenNum, attribs, glxSharedCtx);
}

private:

/// GlX backed OpenGL context
class XcbGlContext : GlContext
{
    import gfx.bindings.core : SharedSym;
    import gfx.bindings.opengl.gl : Gl;
    import gfx.bindings.opengl.glx : Glx, GLXContext, GLXFBConfig;
    import gfx.core.rc : atomicRcCode, Disposable;

    mixin(atomicRcCode);

    private int _mainScreenNum;
    private GlAttribs _attribs;
    private Glx _glx;
    private Gl _gl;
    private string[] _glxAvailExts;
    private string[] _glAvailExts;
    private DummyWindow[size_t] dummies;
    private size_t hiddenDummy;
    private GLXContext _ctx;
    private bool ARB_create_context;
    private bool MESA_query_renderer;
    private bool MESA_swap_control;
    private bool EXT_swap_control;

    /// Contruct an OpenGL context for the given display and screen.
    /// It internally creates a dummy window
    this (size_t window, int mainScreenNum, GlAttribs attribs, GLXContext sharedCtx)
    {
        import gfx.bindings.core : openSharedLib, loadSharedSym, SharedLib;
        import gfx.bindings.opengl : splitExtString;
        import gfx.bindings.opengl.gl : GL_EXTENSIONS;
        import gfx.bindings.opengl.glx : PFN_glXGetProcAddressARB;
        import std.algorithm : canFind;
        import std.exception : enforce;
        import std.experimental.logger : trace, tracef;
        import X11.Xlib : XSetErrorHandler, XSync;

        _mainScreenNum = mainScreenNum;
        _attribs = attribs;

        auto lib = loadGlLib();
        auto getProcAddress = cast(PFN_glXGetProcAddressARB)enforce(loadSharedSym(lib, "glXGetProcAddressARB"));
        SharedSym loadSymbol(in string symbol) {
            import std.string : toStringz;
            return cast(SharedSym)getProcAddress(cast(const(ubyte)*)toStringz(symbol));
        }

        _glx = new Glx(&loadSymbol);

        const glxExts = splitExtString(_glx.QueryExtensionsString(g_display, _mainScreenNum));
        ARB_create_context = glxExts.canFind("GLX_ARB_create_context");
        MESA_query_renderer = glxExts.canFind("GLX_MESA_query_renderer");
        MESA_swap_control = glxExts.canFind("GLX_MESA_swap_control");
        EXT_swap_control = glxExts.canFind("GLX_EXT_swap_control");

        enforce( ARB_create_context && ( MESA_swap_control || EXT_swap_control ));

        auto fbc = getGlxFBConfig(attribs);
        if (!window) {
            window = XcbGlContext.createDummy();
            hiddenDummy = window;
        }
        GlAttribs attrs = attribs;

        auto oldHandler = XSetErrorHandler(&createCtxErrorHandler);

        foreach (const glVer; glVersions) {
            attrs.majorVersion = glVer / 10;
            attrs.minorVersion = glVer % 10;
            if (attrs.decimalVersion < attribs.decimalVersion) break;

            const ctxAttribs = getCtxAttribs(attrs);
            tracef("attempting to create OpenGL %s.%s context", attrs.majorVersion, attrs.minorVersion);

            createContextErrorFlag = false;
            _ctx = _glx.CreateContextAttribsARB(g_display, fbc, sharedCtx, 1, &ctxAttribs[0]);

            if (_ctx && !createContextErrorFlag) break;
        }

        XSetErrorHandler(oldHandler);

        enforce(_ctx);
        XSync(g_display, 0);
        _attribs = attrs;

        tracef("created OpenGL %s.%s context", attrs.majorVersion, attrs.minorVersion);

        XcbGlContext.makeCurrent(hiddenDummy);
        _gl = new Gl(&loadSymbol);

        trace("done loading GL/GLX");
    }

    override void dispose() {
        import gfx.bindings.core : closeSharedLib;
        import gfx.core.rc : disposeArray;
        import std.experimental.logger : trace;

        disposeArray(dummies);

        _glx.DestroyContext(g_display, _ctx);
        trace("destroyed GL/GLX context");
    }


    override @property Gl gl() {
        return _gl;
    }

    override @property GlAttribs attribs() {
        return _attribs;
    }

    override bool makeCurrent(size_t nativeHandle)
    {
        import gfx.bindings.opengl.glx : GLXDrawable;
        return _glx.MakeCurrent(g_display, cast(GLXDrawable)nativeHandle, _ctx) != 0;
    }

    override void doneCurrent()
    {
        _glx.MakeCurrent(g_display, 0, null);
    }

    override @property bool current() const
    {
        return _glx.GetCurrentContext() is _ctx;
    }

    override @property int swapInterval()
    {
        import gfx.bindings.opengl.glx : GLXDrawable;
        if (MESA_swap_control) {
            return _glx.GetSwapIntervalMESA();
        }
        else if (EXT_swap_control) {
            GLXDrawable drawable = _glx.GetCurrentDrawable();
            uint swap;

            if (drawable) {
                import gfx.bindings.opengl.glx : GLX_SWAP_INTERVAL_EXT;
                _glx.QueryDrawable(g_display, drawable, GLX_SWAP_INTERVAL_EXT, &swap);
                return swap;
            }
            else {
                import std.experimental.logger : warningf;
                warningf("could not get glx drawable to get swap interval");
                return -1;
            }

        }
        return -1;
    }

    override @property void swapInterval(int interval)
    {
        import gfx.bindings.opengl.glx : GLXDrawable;

        if (MESA_swap_control) {
            _glx.SwapIntervalMESA(interval);
        }
        else if (EXT_swap_control) {
            GLXDrawable drawable = _glx.GetCurrentDrawable();

            if (drawable) {
                _glx.SwapIntervalEXT(g_display, drawable, interval);
            }
            else {
                import std.experimental.logger : warningf;
                warningf("could not get glx drawable to set swap interval");
            }
        }
    }

    override void swapBuffers(size_t nativeHandle)
    {
        import gfx.bindings.opengl.glx : GLXDrawable;
        _glx.SwapBuffers(g_display, cast(GLXDrawable)nativeHandle);
    }

    private GLXFBConfig getGlxFBConfig(in GlAttribs attribs)
    {
        import X11.Xlib : XFree;

        const glxAttribs = getGlxAttribs(attribs);

        int numConfigs;
        auto fbConfigs = _glx.ChooseFBConfig(g_display, _mainScreenNum, &glxAttribs[0], &numConfigs);

        if (!fbConfigs || !numConfigs)
        {
            import std.experimental.logger : critical;
            critical("GFX-GLX: could not get fb config");
            return null;
        }
        scope (exit) XFree(fbConfigs);

        return fbConfigs[0];
    }

    override size_t createDummy() {
        if (hiddenDummy) {
            const d = hiddenDummy;
            hiddenDummy = 0;
            return d;
        }
        auto dummy = new DummyWindow(g_display, _glx, getGlxFBConfig(_attribs));
        size_t hdl = dummy.win;
        dummies[hdl] = dummy;
        return hdl;
    }

    override void releaseDummy(size_t dummy) {
        auto d = dummy in dummies;
        if (d) {
            auto win = *d;
            win.dispose();
            dummies.remove(dummy);
        }
    }

    private static class DummyWindow : Disposable
    {
        import X11.Xlib : XWindow = Window, XColormap = Colormap;
        import X11.Xlib;

        XWindow win;
        XColormap cmap;
        XDisplay* dpy;

        this (XDisplay* dpy, Glx glx, GLXFBConfig fbc)
        {
            this.dpy = dpy;
            auto vi = glx.GetVisualFromFBConfig( dpy, fbc );
            scope(exit) {
                XFree(vi);
            }

            cmap = XCreateColormap(dpy, XRootWindow(dpy, XDefaultScreen(dpy)),
                                                vi.visual, AllocNone );

            XSetWindowAttributes swa;
            swa.colormap = cmap;
            swa.background_pixmap = None ;
            swa.border_pixel      = 0;
            swa.event_mask        = StructureNotifyMask;

            win = XCreateWindow(dpy, XRootWindow(dpy, vi.screen),
                    0, 0, 100, 100, 0, vi.depth, InputOutput, vi.visual,
                    CWBorderPixel|CWColormap|CWEventMask, &swa);
        }

        override void dispose()
        {
            XDestroyWindow(dpy, win);
            XFreeColormap(dpy, cmap);
        }
    }
}


private SharedLib loadGlLib()
{
    import gfx.bindings.core : openSharedLib;

    immutable glLibNames = ["libGL.so.1", "libGL.so"];

    foreach (ln; glLibNames) {
        auto lib = openSharedLib(ln);
        if (lib) {
            import std.experimental.logger : tracef;
            tracef("opening shared library %s", ln);
            return lib;
        }
    }

    import std.conv : to;
    throw new Exception("could not load any of these libraries: " ~ glLibNames.to!string);
}

private bool createContextErrorFlag;

extern(C) private int createCtxErrorHandler(XDisplay *dpy, XErrorEvent *error)
{
   createContextErrorFlag = true;
   return 0;
}

private int[] getGlxAttribs(in GlAttribs attribs) pure
{
    import gfx.bindings.opengl.glx;
    import gfx.graal.format : formatDesc, redBits, greenBits, blueBits,
                              alphaBits, depthBits, stencilBits;

    int[] glxAttribs = [
        GLX_X_RENDERABLE,   1,
        GLX_DRAWABLE_TYPE,  GLX_WINDOW_BIT,
        GLX_RENDER_TYPE,    GLX_RGBA_BIT,
        GLX_X_VISUAL_TYPE,  GLX_TRUE_COLOR
    ];

    const colorDesc = formatDesc(attribs.colorFormat);
    const depthStencilDesc = formatDesc(attribs.depthStencilFormat);

    const r = redBits(colorDesc.surfaceType);
    const g = greenBits(colorDesc.surfaceType);
    const b = blueBits(colorDesc.surfaceType);
    const a = alphaBits(colorDesc.surfaceType);
    const d = depthBits(depthStencilDesc.surfaceType);
    const s = stencilBits(depthStencilDesc.surfaceType);

    if (r) glxAttribs ~= [GLX_RED_SIZE, r];
    if (g) glxAttribs ~= [GLX_GREEN_SIZE, g];
    if (b) glxAttribs ~= [GLX_BLUE_SIZE, b];
    if (a) glxAttribs ~= [GLX_ALPHA_SIZE, a];
    if (d) glxAttribs ~= [GLX_DEPTH_SIZE, d];
    if (s) glxAttribs ~= [GLX_STENCIL_SIZE, s];

    if (attribs.doublebuffer) glxAttribs ~= [GLX_DOUBLEBUFFER, 1];

    if (attribs.samples > 1)
        glxAttribs ~= [GLX_SAMPLE_BUFFERS, 1, GLX_SAMPLES, attribs.samples];

    return glxAttribs ~ 0;
}

private int[] getCtxAttribs(in GlAttribs attribs) pure
{
    import gfx.bindings.opengl.glx;
    import gfx.gl3.context : GlProfile;

    int[] ctxAttribs = [
        GLX_CONTEXT_MAJOR_VERSION_ARB, attribs.majorVersion,
        GLX_CONTEXT_MINOR_VERSION_ARB, attribs.minorVersion
    ];
    if (attribs.decimalVersion >= 32) {
        ctxAttribs ~= GLX_CONTEXT_PROFILE_MASK_ARB;
        if (attribs.profile == GlProfile.core) {
            ctxAttribs ~= GLX_CONTEXT_CORE_PROFILE_BIT_ARB;
        }
        else {
            ctxAttribs ~= GLX_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB;
        }
    }

    return ctxAttribs ~ 0;
}
