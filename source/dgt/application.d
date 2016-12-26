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

    private void initialize(Uniq!Platform platform)
    {
        assert(!_instance, "Attempt to initialize twice DGT Application singleton");
        _instance = this;
        assert(platform.assigned);
        _platform = platform.release();

        // initialize other singletons
        FontCache.initialize();
    }

    private Uniq!Platform _platform;
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
            return _instance._platform.obj;
        }

        private Application _instance;
    }
}

/// Make the default Platform for the running OS.
Uniq!Platform makeDefaultPlatform()
{
    import dgt.platform.xcb : XcbPlatform;

    return Uniq!Platform(new XcbPlatform);
}
