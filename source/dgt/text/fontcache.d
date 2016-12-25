module dgt.text.fontcache;

import dgt.bindings.fontconfig;
import dgt.rc;

import std.exception;
import std.string;

private __gshared FontCache instance_;

/// Singleton that acts like a system font database and that perform
/// font files queries given structured requests
/// Tightly coupled to fontconfig, but this might (should) change.
class FontCache : Disposable
{
    // called by Application.initialize
    package(dgt) static FontCache initialize()
    in
    {
        assert(instance_ is null);
    }
    body
    {
        instance_ = new FontCache();
        return instance_;
    }

    /// Returns the singleton instance.
    /// Should not be called before Application is created.
    public static FontCache instance()
    in
    {
        assert(instance_ !is null);
    }
    body
    {
        return instance_;
    }

    private FcConfig* config_;
    private string[] appFontFiles_;

    private this()
    {
        loadFontconfigSymbols();
        enforce(FcInit());
        config_ = enforce(FcConfigGetCurrent());
    }

    override void dispose()
    {
        FcFini();
    }

    /// Returns the font files add by the application
    @property const(string[]) appFontFiles() const
    {
        return appFontFiles_;
    }

    /// Sets the font files added by the application
    @property void appFontFiles(string[] files)
    {
        import std.algorithm : each;
        files.each!(f => addAppFontFile(f));
    }

    void addAppFontFile(string file)
    {
        enforce(FcConfigAppFontAddFile(config_, toStringz(file)));
        appFontFiles_ ~= file;
    }
}
