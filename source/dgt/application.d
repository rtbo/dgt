/// Main application module.
module dgt.application;

import dgt.context;
import dgt.eventloop;
import dgt.platform;
import dgt.render;
import dgt.window;
import gfx.foundation.rc;

import std.experimental.logger;

/// Singleton class that must be built by the client application
class Application : EventLoop, Disposable
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
    override int loop()
    {
        assert(!RenderThread.instance.running);
        initializeGfx();
        scope(exit) finalizeGfx();

        return EventLoop.loop();
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
            RenderThread.initialize();
        }
        log("ending initialization");
    }


    private void initializeGfx()
    {
        Window window;
        Window dummy;
        foreach (w; windows) {
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

        RenderThread.instance.start(createGlContext(window));

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
        RenderThread.instance.stop(window.nativeHandle);

        if (dummy) dummy.close();
    }

    private Platform _platform;
    private bool _exitFlag;
    private int _exitCode;

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

