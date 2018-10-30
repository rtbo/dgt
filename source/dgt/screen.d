/// Screen module
module dgt.screen;

interface Screen
{
    import dgt.core.geometry : IRect;

    @property int num() const;
    @property IRect rect() const;
    @property double dpi() const;
    final @property int width() const
    {
        return rect.width;
    }
    final @property int height() const
    {
        return rect.height;
    }
}

/// Get the resolution in pixels per inch of a screen (screen 0 is the main monitor).
/// If a platform is loaded (i.e. an Application instance is on), this will
/// return the info from the loaded platform. Otherwise it instanciate a temporary
/// platform to get the info from it.
double getScreenDPI(int screen=0)
{
    import dgt.application : Application, makeDefaultPlatform;
    import std.exception : enforce;

    auto platform = Application.platform;
    if (!platform) {
        platform = makeDefaultPlatform();
        platform.initialize();
    }
    enforce(platform);
    scope(exit) {
        if (!Application.platform) {
            platform.dispose();
        }
    }

    auto screens = platform.screens;
    enforce(screen < screens.length);

    return screens[screen].dpi;
}
