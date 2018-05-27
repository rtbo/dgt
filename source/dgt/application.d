/// Main application module.
module dgt.application;

import dgt.core.rc : Disposable;
import dgt.eventloop : EventLoop;
import dgt.platform : Platform;

/// Singleton class that must be built by the client application
class Application : EventLoop, Disposable
{
    import dgt.window : Window;

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
        import dgt : finalizeSubsystems;

        _platform.dispose();
        finalizeSubsystems();
    }

    final @property string name() const
    {
        return _name;
    }

    final @property void name(in string name)
    {
        _name = name;
    }

    final @property uint[3] ver() const
    {
        return _ver;
    }

    final @property void ver(in uint[3] ver)
    {
        _ver = ver;
    }

    private void initialize(Platform platform)
    {
        import dgt : initializeSubsystems;
        import dgt.render.queue : RenderQueue;
        import std.experimental.logger : log;

        initializeSubsystems();

        // init Application singleton
        assert(!_instance, "Attempt to initialize twice DGT Application singleton");
        _instance = this;

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
        import dgt.context : createGlContext;
        import dgt.render.queue : RenderQueue;
        import dgt.render.renderer2 : createRenderer;
        import gfx.graal : Backend;

        assert(window.created && !window.dummy);
        const tryOrder = [ Backend.vulkan, Backend.gl3 ];
        auto renderer = createRenderer(tryOrder, name, ver, createGlContext(window));
        RenderQueue.instance.start(renderer);
    }

    private void finalizeGfx(Window window)
    {
        import dgt.render.queue : RenderQueue;

        assert(window.created && !window.dummy);
        RenderQueue.instance.stop(window.nativeHandle);
    }


    private Platform _platform;
    private string _name;
    private uint[3] _ver;

    static __gshared
    {
        /// Get the Application singleton.
        @property Application instance()
        {
            return _instance;
        }
        /// Get the Platform singleton.
        @property Platform platform()
        {
            if (_instance) return _instance._platform;
            else return null;
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
