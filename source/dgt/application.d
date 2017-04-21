/// Main application module.
module dgt.application;

import gfx.foundation.rc;
import dgt.platform;
import dgt.context;
import dgt.window;
import dgt.sg.render;
import dgt.sg.render.frame;

import std.experimental.logger;
import std.concurrency : Tid;

/// Singleton class that must be built by the client application
class Application : Disposable
{
    /// Build an application. This will initialize underlying platform.
    this()
    {
        initialize(null);
    }

    /// Build an application with the provided platform.
    /// Ownership of the platform is taken, caller must not call dispose().
    this(Platform platform)
    {
        initialize(platform);
    }

    override void dispose()
    {
        import dgt.text.font : FontEngine;
        import dgt.text.fontcache : FontCache;

        FontCache.instance.dispose();
        FontEngine.instance.dispose();
        _platform.dispose();
    }

    /// Enter main event processing loop
    int loop()
    {
        assert(!_gfxRunning);
        initializeGfx();

        while (!_exitFlag)
            _platform.processNextEvent();

        finalizeGfx();
        return _exitCode;
    }

    void renderFrame(immutable(RenderFrame) frame)
    {
        assert(_gfxRunning);
        .renderFrame(_renderTid, frame);
    }

    void deleteRenderCache(in ulong cookie)
    {
        assert(_gfxRunning);
        .deleteRenderCache(_renderTid, cookie);
    }

    /// Get a new valid cookie for caching render data
    ulong nextRenderCacheCookie()
    {
        if (_renderCacheCookie == ulong.max) {
            error("Render cache cookie overflow!");
            return 0;
        }
        return ++_renderCacheCookie;
    }

    /// Register an exit code and exit at end of current event loop
    void exit(int code = 0)
    {
        _exitCode = code;
        _exitFlag = true;
    }

    private void initialize(Platform platform)
    {
        // init Application singleton
        assert(!_instance, "Attempt to initialize twice DGT Application singleton");
        _instance = this;

        // init bindings to C libraries
        {
            import dgt.bindings.libpng.load : loadLibPngSymbols;
            import dgt.bindings.turbojpeg.load : loadTurboJpegSymbols;
            import dgt.bindings.cairo.load : loadCairoSymbols;
            import dgt.bindings.fontconfig.load : loadFontconfigSymbols;
            import dgt.bindings.harfbuzz.load : loadHarfbuzzSymbols;
            import derelict.opengl3.gl3 : DerelictGL3;
            import derelict.freetype.ft : DerelictFT;

            DerelictGL3.load();
            DerelictFT.load();
            loadLibPngSymbols();
            loadTurboJpegSymbols();
            loadCairoSymbols();
            loadFontconfigSymbols();
            loadHarfbuzzSymbols();
        }

        // init platform
        if (!platform) platform = makeDefaultPlatform();
        _platform = platform;
        _platform.initialize();

        log("platform initialization done");

        // init other singletons
        {
            import dgt.text.font : FontEngine;
            import dgt.text.fontcache : FontCache;
            FontEngine.initialize();
            FontCache.initialize();
        }
        log("ending initialization");
    }

    package void registerWindow(Window w)
    {
        import std.algorithm : canFind;
        assert(!_windows.canFind(w), "tentative to register registered window");
        logf(`register window: 0x%08x "%s"`, cast(void*)w, w.title);
        _windows ~= w;
    }

    package void unregisterWindow(Window w)
    {
        import std.algorithm : canFind, remove, SwapStrategy;
        assert(_windows.canFind(w), "tentative to unregister unregistered window");
        _windows = _windows.remove!(win => win is w, SwapStrategy.unstable)();
        logf(`unregister window: 0x%08x "%s"`, cast(void*)w, w.title);

        // do not exit for a dummy window (they can be created and closed before event loop starts)
        if (w.flags & WindowFlags.dummy) return;

        if (!_windows.length && !_exitFlag)
        {
            logf("last window exit!");
            exit(0);
        }
    }

    private void initializeGfx()
    {
        Window window;
        Window dummy;
        foreach (w; _windows) {
            if (w.platformWindow.created) {
                window = w;
                break;
            }
        }
        if (!window) {
            dummy = new Window("dummy", WindowFlags.dummy);
            dummy.show();
            window = dummy;
        }

        shared ctx = createGlContext(window);
        _renderTid = startRenderLoop(ctx);
        _gfxRunning = true;

        if (dummy) {
            dummy.close();
        }
    }

    private void finalizeGfx(Window window=null)
    {
        Window dummy;
        if (!window) {
            dummy = new Window("dummy", WindowFlags.dummy);
            dummy.show();
            window = dummy;
        }
        finalizeRenderLoop(_renderTid, window.nativeHandle);
        _gfxRunning = false;

        if (dummy) dummy.close();
    }

    private Platform _platform;
    private bool _exitFlag;
    private int _exitCode;
    private Window[] _windows;

    ulong _renderCacheCookie;
    Tid _renderTid;
    bool _gfxRunning;

    static
    {
        /// Get the Application singleton.
        @property Application instance()
        {
            assert(_instance, "Attempt to get unintialized DGT Application");
            return _instance;
        }
        /// Get the Platform singleton.
        @property Platform platform()
        {
            assert(_instance && _instance._platform, "Attempt to get unintialized DGT Platform");
            return _instance._platform;
        }

        private Application _instance;
    }
}

/// Make the default Platform for the running OS.
Platform makeDefaultPlatform()
{
    version(linux)
    {
        import dgt.platform.xcb : XcbPlatform;
        return new XcbPlatform;
    }
    else version(Windows)
    {
        import dgt.platform.win32 : Win32Platform;
        return new Win32Platform;
    }
    else
    {
        assert(false, "unimplemented");
    }
}

