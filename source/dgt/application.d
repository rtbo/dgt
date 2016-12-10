module dgt.application;

import dgt.platform;

/// Singleton class that must be built by the client application
class Application
{
    /// Build an application. This will initialize underlying platform.
    this()
    {
        instance = this;
        platform_ = defaultPlatform;
    }

    /// Build an application with the provided platform.
    this(Platform platform)
    {
        assert(platform !is null);
        instance = this;
        platform_ = platform;
    }

    private Platform platform_;


    static
    {
        /// Get the Application singleton.
        @property Application instance()
        {
            assert(instance_, "Attempt to get unintialized DGT Application");
            return instance_;
        }

        private @property void instance(Application inst)
        {
            assert(!instance_, "Attempt to initialize twice DGT Application singleton");
            instance_ = inst;
        }

        private Application instance_;
    }
}

/// Get the default Platform for the running OS.
@property Platform defaultPlatform()
{
    return null;
}