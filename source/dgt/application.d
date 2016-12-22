module dgt.application;

import dgt.platform;

/// Singleton class that must be built by the client application
class Application
{
    /// Build an application. This will initialize underlying platform.
    this()
    {
        initialize(makeDefaultPlatform());
    }

    /// Build an application with the provided platform.
    this(Platform platform)
    {
        initialize(platform);
    }

    ~this()
    {
        platform_.shutdown();
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

    private void initialize(Platform platform)
    {
        assert(!instance_, "Attempt to initialize twice DGT Application singleton");
        instance_ = this;
        assert(platform !is null);
        platform_ = platform;
    }

    private Platform platform_;
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
            return instance_.platform_;
        }

        private Application instance_;
    }
}

/// Make the default Platform for the running OS.
Platform makeDefaultPlatform()
{
    import dgt.platform.xcb : XcbPlatform;

    return new XcbPlatform();
}
