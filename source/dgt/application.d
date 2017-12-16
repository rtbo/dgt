/// Main application module.
module dgt.application;

import dgt.context;
import dgt.core.rc;
import dgt.eventloop;
import dgt.render.queue : RenderQueue;
import dgt.platform;
import dgt.window;

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
        // import dgt.text.font : FontEngine;
        // import dgt.text.fontcache : FontCache;

        // FontCache.instance.dispose();
        // FontEngine.instance.dispose();
        _platform.dispose();
    }


    private void initialize(Platform platform)
    {
        // init Application singleton
        assert(!_instance, "Attempt to initialize twice DGT Application singleton");
        _instance = this;

        log("loading 3rd party libraries");
        // init bindings to C libraries
        {
            import derelict.opengl3.gl3 : DerelictGL3;
            DerelictGL3.load();
        }

        // init platform
        log("initializing platform");
        if (!platform) platform = makeDefaultPlatform();
        _platform = platform;
        _platform.initialize();

        log("platform initialization done");

        // init other singletons
        {
            // import dgt.text.fontcache : FontCache;
            // import dgt.text.font : FontEngine;
            // FontEngine.initialize();
            // FontCache.initialize();
            RenderQueue.initialize();
        }
    }

    override protected void onRegisterWindow(Window w) {
        if (windows.length == 1) {
            initializeGfx(w);
        }
    }

    override protected void onUnregisterWindow(Window w) {
        if (windows.length == 1) {
            finalizeGfx(w);
        }
    }

    private void initializeGfx(Window window)
    {
        assert(window.created && !window.dummy);
        RenderQueue.instance.start(createGlContext(window));
    }

    private void finalizeGfx(Window window)
    {
        assert(window.created && !window.dummy);
        RenderQueue.instance.stop(window.nativeHandle);
    }


    private Platform _platform;

    static __gshared
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
