module dgt.text.fontcache;

import dgt.bindings.fontconfig;
import dgt.css.style;
import dgt.text.font;
import dgt.view.view;

import gfx.foundation.rc;

import std.exception;
import std.experimental.logger;
import std.string;
import std.typecons : Flag, No, Yes;
import std.uni;


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
    // todo: build coverage lazily and cache it.
    CodepointSet coverage;

    /// hash suitable to AA key
    @property size_t hash() const
    {
        return hashOf(filename, hashOf(faceIndex, hashOf(size)));
    }
}



private __gshared FontCache _fcInst;

/// Singleton that acts like a system font database and that perform
/// font files queries given structured requests
/// Tightly coupled to fontconfig, but this might (should) change.
class FontCache : Disposable
{
    // called by Application.initialize
    package(dgt) static void initialize()
    in
    {
        assert(_fcInst is null);
    }
    body
    {
        _fcInst = new FontCache();
    }

    /// Returns the singleton instance.
    /// Should not be called before Application is created.
    static @property FontCache instance()
    in
    {
        assert(_fcInst !is null);
    }
    body
    {
        return _fcInst;
    }

    private FcConfig* _config;
    private string[] _appFontFiles;

    private Font[size_t]   _liveCache;

    private this()
    {
        log("loading font cache");
        enforce(FcInit());
        _config = enforce(FcConfigGetCurrent());
    }

    override void dispose()
    {
        release(_liveCache);
        FcFini();
    }

    /// Returns the font files add by the application
    @property const(string[]) appFontFiles() const
    {
        return _appFontFiles;
    }

    /// Sets the font files added by the application
    @property void appFontFiles(string[] files)
    {
        import std.algorithm : each;
        files.each!(f => addAppFontFile(f));
    }

    void addAppFontFile(string file)
    {
        FcConfigAppFontClear(_config);
        enforce(FcConfigAppFontAddFile(_config, toStringz(file)));
        _appFontFiles ~= file;
    }

    FontResult[] requestFont(View view)
    {
        auto pat = FcPatternCreate();
        scope(exit)
            FcPatternDestroy(pat);
        if (view.fontFamily.length) {
            FcPatternAddString(pat, FC_FAMILY, toStringz(view.fontFamily[0]));
        }
        FcPatternAddInteger(pat, FC_SLANT, styleToFcSlant(view.fontStyle));
        FcPatternAddInteger(pat, FC_WEIGHT, FcWeightFromOpenType(view.fontWeight));
        FcPatternAddDouble(pat, FC_PIXEL_SIZE, view.fontSize);
        FcPatternAddBool(pat, FC_OUTLINE, FcTrue);
        FcPatternAddBool(pat, FC_SCALABLE, FcTrue);

        FcConfigSubstitute(_config, pat, FcMatchPattern);
        FcDefaultSubstitute(pat);

        FcResult dummy;
        auto patterns = FcFontSort(_config, pat, FcTrue, null, &dummy);
        if (!patterns) {
            errorf("could not match any font.");
            return [];
        }
        scope(exit)
            FcFontSetDestroy(patterns);

        FontResult[] res;
        foreach (i; 0 .. patterns.nfont) {
            auto p = FcFontRenderPrepare(_config, pat, patterns.fonts[i]);
            if (p) {
                scope(exit)
                    FcPatternDestroy(p);
                double dval = void;
                char* sval = void;
                int ival = void;
                FcCharSet *csval = void;
                FontResult fr;
                if (FcPatternGetString(p, FC_FAMILY, 0, &sval) == FcResultMatch) {
                    fr.family = fromStringz(sval).idup;
                }
                if (FcPatternGetInteger(p, FC_SLANT, 0, &ival) == FcResultMatch) {
                    fr.style = fcSlantToStyle(ival);
                }
                if (FcPatternGetInteger(p, FC_WEIGHT, 0, &ival) == FcResultMatch) {
                    fr.weight = FcWeightToOpenType(ival);
                }
                if (FcPatternGetDouble(p, toStringz(FC_PIXEL_SIZE), 0, &dval) == FcResultMatch) {
                    fr.size = FontSize.px(dval);
                }
                string fn;
                int fi;
                CodepointSet cps;
                if (FcPatternGetString(p, FC_FILE, 0, &sval) == FcResultMatch) {
                    fr.filename = fromStringz(sval).idup;
                }
                if (FcPatternGetInteger(p, FC_INDEX, 0, &ival) == FcResultMatch) {
                    fr.faceIndex = ival;
                }
                if (FcPatternGetCharSet(p, FC_CHARSET, 0, &csval) == FcResultMatch) {
                    fr.coverage = buildCoverage(csval);
                }
                res ~= fr;
            }
        }
        return res;
    }

    /// Create a new font based on the font result, or fetch it from the cache
    /// if it was created before.
    Font createOrGetFont(in FontResult res)
    {
        Font f;
        immutable hash = res.hash;
        auto fp = hash in _liveCache;
        if (fp) {
            f = *fp;
        }
        else {
            f = new Font(res);
            f.retain();
            _liveCache[hash] = f;
        }
        return f;
    }

    package void onFontDispose(size_t hash)
    {
        _liveCache.remove(hash);
    }

    private CodepointSet buildCoverage(FcCharSet* cs)
    {
        CodepointSet coverage;
        Flag!"included" inSet = No.included;
        dchar intervalSt;
        dchar intervalEnd;

        FcChar32[FC_CHARSET_MAP_SIZE] map;
        FcChar32 pos;
        for(FcChar32 base = FcCharSetFirstPage(cs, map, &pos);
            base != FC_CHARSET_DONE;
            base = FcCharSetNextPage(cs, map, &pos))
        {
            foreach (immutable uint i, bits; map)
            {
                foreach (immutable dchar cp; base+i*32 .. base+i*64)
                {
                    immutable cIsIn = (bits & 1) ? Yes.included : No.included;
                    if (cIsIn)
                    {
                        intervalEnd = cp;
                    }

                    if (cIsIn && !inSet)
                    {
                        intervalSt = cp;
                    }
                    else if (!cIsIn && inSet)
                    {
                        coverage.add(intervalSt, intervalEnd + 1);
                    }

                    inSet = cIsIn;
                    bits >>>= 1;
                    if (!cIsIn && !bits) break;
                }
            }
        }
        if (inSet)
        {
            coverage.add(intervalSt, intervalEnd+1);
        }
        return coverage;
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