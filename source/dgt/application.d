module dgt.application;

import dgt.resource;
import dgt.platform;
import dgt.text.fontcache;

/// Singleton class that must be built by the client application
class Application : Disposable
{
    /// Build an application. This will initialize underlying platform.
    this()
    {
        initialize(makeDefaultPlatform());
    }

    /// Build an application with the provided platform.
    this(Uniq!Platform platform)
    {
        initialize(platform.release());
    }

    override void dispose()
    {
        FontCache.instance.dispose();
    }

    /// Enter main event processing loop
    int loop()
    {
        while (!exitFlag_)
            platform_.processNextEvent();
        return exitCode_;
    }

    /// Register an exit code and exit at end of current event loop
    void exit(int code = 0)
    {
        exitCode_ = code;
        exitFlag_ = true;
    }

    private void initialize(Uniq!Platform platform)
    {
        assert(!instance_, "Attempt to initialize twice DGT Application singleton");
        instance_ = this;
        assert(platform.assigned);
        platform_ = platform.release();

        // initialize other singletons
        FontCache.initialize();
    }

    private Uniq!Platform platform_;
    private bool exitFlag_;
    private int exitCode_;

    static
    {
        /// Get the Application singleton.
        @property Application instance()
        {
            assert(instance_, "Attempt to get unintialized DGT Application");
            return instance_;
        }
        /// Get the Platform singleton.
        @property Platform platform()
        {
            assert(instance_ && instance_.platform_, "Attempt to get unintialized DGT Platform");
            return instance_.platform_.obj;
        }

        private Application instance_;
    }
}

/// Make the default Platform for the running OS.
Uniq!Platform makeDefaultPlatform()
{
    import dgt.platform.xcb : XcbPlatform;

    return Uniq!Platform(new XcbPlatform);
}
