module dgt.application;

import dgt.core.resource;
import dgt.platform;
import dgt.window;

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
        while (!_exitFlag)
            _platform.processNextEvent();
        return _exitCode;
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
            import dgt.bindings.cairo.load : loadCairoSymbols;
            import dgt.bindings.fontconfig.load : loadFontconfigSymbols;
            import dgt.bindings.harfbuzz.load : loadHarfbuzzSymbols;
            import dgt.bindings.libpng.load : loadLibpngSymbols;
            import derelict.opengl3.gl3 : DerelictGL3;
            import derelict.freetype.ft : DerelictFT;

            DerelictGL3.load();
            DerelictFT.load();
            loadCairoSymbols();
            loadFontconfigSymbols();
            loadHarfbuzzSymbols();
            loadLibpngSymbols();
        }

        // init platform
        if (!platform) platform = makeDefaultPlatform();
        _platform = platform;

        // init singletons
        {
            import dgt.text.font : FontEngine;
            import dgt.text.fontcache : FontCache;
            FontEngine.initialize();
            FontCache.initialize();
        }

    }

    package void registerWindow(Window w)
    {
        import std.algorithm : canFind;
        assert(!_windows.canFind(w), "tentative to register registered window");
        _windows ~= w;
    }

    package void unregisterWindow(Window w)
    {
        import std.algorithm : canFind, remove, SwapStrategy;
        assert(_windows.canFind(w), "tentative to unregister unregistered window");
        _windows = _windows.remove!(win => win is w, SwapStrategy.unstable)();

        if (!_windows.length && !_exitFlag)
        {
            exit(0);
        }
    }

    private Platform _platform;
    private bool _exitFlag;
    private int _exitCode;
    private Window[] _windows;

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
    else
    {
        assert(false, "unimplemented");
    }
}
