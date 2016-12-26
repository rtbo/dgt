module dgt.text.fontcache;

import dgt.text.font;
import dgt.bindings.fontconfig;
import dgt.rc;

import std.exception;
import std.string;
import std.experimental.logger;


/// A structured font request.
/// Although taking parameters as defined by the CSS specification,
/// no guarantee is made that the font matching will be 100% CSS compliant.
struct FontRequest
{
    string family;
    FontSize size = FontSize.pts(10);
    FontStyle style = FontStyle.normal;
    int weight = FontWeight.normal;
    FontVariant variant = FontVariant.normal;
    string foundry;
}


/// Result of a font request. A request typically returns a range of those results.
/// The first element will be the best match, the next ones fallbacks.
/// Has same fields as the font request, so that application can check what was
/// really matched.
/// Also has filename and face index within the file.
struct FontResult
{
    string family;
    FontSize size = FontSize.pts(10);
    FontStyle style = FontStyle.normal;
    int weight = FontWeight.normal;
    FontVariant variant = FontVariant.normal;
    string foundry;

    string filename;
    int faceIndex;
}


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
        FcConfigAppFontClear(config_);
        enforce(FcConfigAppFontAddFile(config_, toStringz(file)));
        appFontFiles_ ~= file;
    }

    FontResult[] requestFont(in FontRequest req)
    {
        auto pat = FcPatternCreate();
        scope(exit)
            FcPatternDestroy(pat);
        FcPatternAddString(pat, FC_FAMILY, toStringz(req.family));
        FcPatternAddInteger(pat, FC_SLANT, styleToFcSlant(req.style));
        FcPatternAddInteger(pat, FC_WEIGHT, FcWeightFromOpenType(req.weight));
        // FIXME: get dpi from Screen
        FcPatternAddDouble(pat, FC_DPI, 96.0);
        if (req.size.unit == FontSize.Unit.px)
        {
            FcPatternAddDouble(pat, FC_PIXEL_SIZE, req.size.value);
        }
        else
        {
            FcPatternAddDouble(pat, FC_SIZE, req.size.value);
        }
        if (req.foundry.length)
        {
            FcPatternAddString(pat, FC_FOUNDRY, toStringz(req.foundry));
        }

        FcConfigSubstitute(config_, pat, FcMatchPattern);
        FcDefaultSubstitute(pat);

        FcResult dummy;
        auto patterns = FcFontSort(config_, pat, FcTrue, null, &dummy);
        if (!patterns)
        {
            errorf("could not match any font.");
            return [];
        }
        scope(exit)
            FcFontSetDestroy(patterns);

        FontResult[] res;
        foreach (i; 0 .. patterns.nfont)
        {
            auto p = FcFontRenderPrepare(config_, pat, patterns.fonts[i]);
            if (p)
            {
                scope(exit)
                    FcPatternDestroy(p);
                double dval = void;
                char* sval = void;
                int ival = void;
                FontResult fr;
                if (FcPatternGetString(p, FC_FAMILY, 0, &sval) == FcResultMatch)
                {
                    fr.family = fromStringz(sval).idup;
                }
                if (FcPatternGetInteger(p, FC_SLANT, 0, &ival) == FcResultMatch)
                {
                    fr.style = fcSlantToStyle(ival);
                }
                if (FcPatternGetInteger(p, FC_WEIGHT, 0, &ival) == FcResultMatch)
                {
                    fr.weight = FcWeightToOpenType(ival);
                }
                immutable key = req.size.unit == FontSize.Unit.pts ? FC_SIZE : FC_PIXEL_SIZE;
                if (FcPatternGetDouble(p, toStringz(key), 0, &dval) == FcResultMatch)
                {
                    fr.size = req.size.unit == FontSize.Unit.pts ?
                        FontSize.pts(dval) : FontSize.px(dval);
                }
                if (FcPatternGetString(p, FC_FOUNDRY, 0, &sval) == FcResultMatch)
                {
                    fr.foundry = fromStringz(sval).idup;
                }
                if (FcPatternGetString(p, FC_FILE, 0, &sval) == FcResultMatch)
                {
                    fr.filename = fromStringz(sval).idup;
                }
                if (FcPatternGetInteger(p, FC_INDEX, 0, &ival) == FcResultMatch)
                {
                    fr.faceIndex = ival;
                }
                res ~= fr;
            }
        }
        return res;
    }
}


private:

int styleToFcSlant(in FontStyle style)
{
    final switch(style)
    {
        case FontStyle.normal:
            return FC_SLANT_ROMAN;
        case FontStyle.italic:
            return FC_SLANT_ITALIC;
        case FontStyle.oblique:
            return FC_SLANT_OBLIQUE;
    }
}

FontStyle fcSlantToStyle(in int slant)
{
    switch(slant)
    {
        case FC_SLANT_ROMAN:
            return FontStyle.normal;
        case FC_SLANT_ITALIC:
            return FontStyle.italic;
        case FC_SLANT_OBLIQUE:
            return FontStyle.oblique;
        default:
            warningf("fontconfig slant %d do not match a FontStyle", slant);
            return FontStyle.normal;
    }
}