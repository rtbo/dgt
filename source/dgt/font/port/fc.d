/// Fontconfig font library implementation
module dgt.font.port.fc;

version(linux):

import dgt.bindings.fontconfig;
import dgt.core.rc;
import dgt.font.library;
import dgt.font.port.ft;
import dgt.font.style;
import dgt.font.typeface;

import std.experimental.logger;
import std.string;
import std.typecons : Nullable;
import std.uni;

class FcFontLibrary : FontLibrary
{
    this() {
        // fontconfig is thread safe since 2.10.91. That is Jan 2013.
        // As of today (nearly 2018), even debian oldstable has > 2.10.91.
        // Only enforcing that we are on a supported version.
        import std.exception : enforce;
        enforce(FcGetVersion() >= 21091, "unsupported fontconfig version");

        config = FcInitLoadConfigAndFonts();
        tfCache = new TypefaceCache;
        families = getFamilies(config);
    }

    override void dispose() {
        tfCache.dispose();
        FcConfigDestroy(config);
        FcFini();
        families = null;
        tfCache = null;
        config = null;
    }

    override shared(Typeface) getById(in FontId fontId) {
        synchronized(this) {
            auto tf = tfCache.find!((Typeface tf) {
                return tf.id == fontId;
            });
            return cast(shared(Typeface))tf;
        }
    }


    override shared(Typeface) css3FontMatch(in string[] families, in FontStyle style, in string text)
    {
        FcCharSet* charSet;
        scope(exit) {
            if (charSet) FcCharSetDestroy(charSet);
        }
        if (text.length) {
            charSet = FcCharSetCreate();
            import std.utf : byDchar;
            foreach (const dc; text.byDchar) {
                FcCharSetAddChar(charSet, cast(FcChar32)dc);
            }
        }

        shared(Typeface) testFamily(in string family) {
            auto pattern = FcPatternCreate();
            scope(exit) FcPatternDestroy(pattern);

            auto matches = getSortedMatches(pattern, family, Nullable!FontStyle(style), charSet);
            scope(exit) FcFontSetDestroy(matches);

            return selectBestFont(matches, pattern, family);
        }

        foreach (family; families) {
            auto tf = testFamily(family);
            if (tf) return tf;
        }
        if (!families.length || sicmp(families[$-1], "system-ui") != 0) {
            return testFamily("system-ui");
        }
        else {
            return null;
        }
    }

    override @property size_t familyCount() {
        return families.length;
    }

    override string family(in size_t index) {
        return families[index];
    }

    override FamilyStyleSet matchFamily(string family) {

        auto pattern = FcPatternCreate();
        scope(exit) FcPatternDestroy(pattern);

        auto matches = getSortedMatches(pattern, family, Nullable!FontStyle.init, null);
        scope(exit) FcFontSetDestroy(matches);

        return filterStyleSet(matches, pattern, family);
    }

    override shared(Typeface) matchFamilyStyle(string family, in FontStyle style) {
        // same as above, we have to check that the family is either a generic or a perfect match
        // so the code is the same except that we add the style in the search pattern
        // and that we return the best matching typeface, instead of a set
        auto pattern = FcPatternCreate();
        scope(exit) FcPatternDestroy(pattern);

        auto matches = getSortedMatches(pattern, family, Nullable!FontStyle(style), null);
        scope(exit) FcFontSetDestroy(matches);

        return selectBestFont(matches, pattern, family);
    }

    override Typeface createFromMemory(const(ubyte)[] data, int faceIndex)
    {
        // do we need to cache this? likely not
        auto face = openFaceFromMemory(data, faceIndex);
        return new FtTypeface(face);
    }

    override Typeface createFromFile(in string path, int faceIndex)
    {
        // do we need to cache this? likely not
        auto face = openFaceFromFile(path, faceIndex);
        return new FtTypeface(face);
    }

    private FcFontSet* getSortedMatches(FcPattern* pattern, in string family, in Nullable!FontStyle style, FcCharSet* charSet) {
        // need to split 2 cases:
        //  1. family is not generic: only return exact family name match (case insensitively)
        //  2. family is generic: handle some corner cases and let fontconfig match the best it can

        if (family != "system-ui") {
            // on my system, system-ui match to the default font, but I'm not sure how it is portable.
            // likely not specifying font name is more robust to get the default family
            FcPatternAddString(pattern, FC_FAMILY, toStringz(family));
        }

        if (!style.isNull) {
            addFontStyleToFcPattern(style, pattern);
        }

        if (charSet) {
            FcPatternAddCharSet(pattern, FC_CHARSET, charSet);
        }
        FcPatternAddBool(pattern, FC_OUTLINE, FcTrue);
        FcPatternAddBool(pattern, FC_SCALABLE, FcTrue);

        FcConfigSubstitute(config, pattern, FcMatchPattern);
        FcDefaultSubstitute(pattern);

        FcResult res;
        return FcFontSort(config, pattern, FcFalse, null, &res);
    }

    private shared(Typeface) selectBestFont(FcFontSet* matches, FcPattern* pattern, in string family) {
        if (!matches.nfont) return null;

        auto fontSet = FcFontSetCreate();
        scope(exit) FcFontSetDestroy(fontSet);

        // for generic, we simply take the family of the first entry
        const matchedFamily = isGenericFamily(family) ? getFcString(matches.fonts[0], FC_FAMILY, "") : family;

        import std.algorithm : each, filter, map;
        import std.range : iota, takeOne;

        iota(matches.nfont)
            .map!(i => matches.fonts[i])
            .filter!(f => f.isAccessible)
            // "_" is to avoid accidental match due to default values of getFcString
            .filter!(f => sicmp(matchedFamily, getFcString(f, FC_FAMILY, "_")) == 0)
            .map!(f => FcFontRenderPrepare(config, pattern, f))
            .takeOne
            .each!(f => FcFontSetAdd(fontSet, f));

        if (!fontSet.nfont) {
            return null;
        }
        else {
            return typefaceFromPattern(fontSet.fonts[0]);
        }
    }

    private FcFamilyStyleSet filterStyleSet(FcFontSet* matches, FcPattern* pattern, in string family) {
        if (!matches.nfont) return null;

        auto fontSet = FcFontSetCreate();

        // we return a style set of all fonts from the same family
        // for generic, we simply take the family of the first entry
        const matchedFamily = isGenericFamily(family) ? getFcString(matches.fonts[0], FC_FAMILY, "") : family;

        import std.algorithm : each, filter, map;
        import std.range : iota;

        iota(matches.nfont)
            .map!(i => matches.fonts[i])
            .filter!(f => f.isAccessible)
            // "_" is to avoid accidental match due to default values of getFcString
            .filter!(f => sicmp(matchedFamily, getFcString(f, FC_FAMILY, "_")) == 0)
            .map!(f => FcFontRenderPrepare(config, pattern, f))
            .each!(f => FcFontSetAdd(fontSet, f));

        if (!fontSet.nfont) {
            FcFontSetDestroy(fontSet);
            return null;
        }
        else {
            // FcFamilyStyleSet takes ownership of fontSet
            return new FcFamilyStyleSet(this, family, fontSet);
        }
    }

    private shared(Typeface) typefaceFromPattern(FcPattern* font) {
        synchronized(this) {
            auto tf = tfCache.find!((Typeface tf) {
                auto fcTf = cast(FcTypeface)tf;
                return FcPatternEqual(font, fcTf._font) == FcTrue;
            });
            if (!tf) {
                assert(font.isAccessible);
                const fname = getFcString(font, FC_FILE, "");
                const index = getFcInt(font, FC_INDEX, 0);
                auto face = openFaceFromFile(fname, index);
                tf = new FcTypeface(face, font);
                tfCache.add(tf);
            }
            return cast(shared(Typeface))tf;
        }
    }

    private FcConfig *config;
    private string[] families;
    private TypefaceCache tfCache;
}

private:

class TypefaceCache : Disposable {

    this() {}

    override void dispose() {
        releaseArr(_typefaces);
    }

    void add(Typeface tf) {
        tf.retain();
        _typefaces ~= tf;
    }

    private Typeface[] _typefaces;
}

Typeface find (alias pred)(TypefaceCache tfCache) {
    foreach(tf; tfCache._typefaces) {
        if (pred(tf)) return tf;
    }
    return null;
}

bool isGenericFamily(in string family) {
    if (!sicmp(family, "system-ui")) return true;
    if (!sicmp(family, "sans-serif")) return true;
    if (!sicmp(family, "serif")) return true;
    if (!sicmp(family, "monospace")) return true;
    if (!sicmp(family, "cursive")) return true;
    if (!sicmp(family, "fantasy")) return true;
    return false;
}

@property bool isAccessible(FcPattern* pattern) {
    import std.file : exists;
    return exists(getFcString(pattern, FC_FILE, ""));
}

string[] getFamilies(FcConfig* cfg) {
    string[] families;
    immutable sets = [ FcSetSystem, FcSetApplication ];
    foreach (s; sets) {
        auto fontSet = FcConfigGetFonts(cfg, s);
        if (!fontSet) continue;

        foreach (FcPattern* font; fontSet.fonts[0 .. fontSet.nfont]) {
            if (!isAccessible(font)) {
                continue;
            }
            int id=0;
            while (1) {
                FcChar8* fcName;
                const res = FcPatternGetString(font, FC_FAMILY, id++, &fcName);
                if (res == FcResultNoId) {
                    break;
                }
                else if (res == FcResultNoMatch) {
                    continue;
                }
                immutable f = fromStringz(fcName).idup;

                import std.algorithm : canFind;
                if (!families.canFind(f)) {
                    families ~= f;
                }
            }
        }
    }
    return families;
}


class FcFamilyStyleSet : FamilyStyleSet
{
    private Rc!FcFontLibrary fl;
    private string family;
    private FcFontSet* fs;

    this (FcFontLibrary fl, string family, FcFontSet* fs) {
        this.fl = fl;
        this.family = family;
        this.fs = fs;
    }

    override void dispose() {
        FcFontSetDestroy(fs);
        fl.unload();
    }

    override @property size_t styleCount() {
        return fs.nfont;
    }

    override FontStyle style(in size_t index) {
        auto pattern = fs.fonts[index];
        return fcPatternToFontStyle(pattern);
    }

    override shared(Typeface) createTypeface(in size_t index) {
        return fl.typefaceFromPattern(fs.fonts[index]);
    }

    override shared(Typeface) matchStyle(in FontStyle style) {
        auto pattern = FcPatternCreate();
        addFontStyleToFcPattern(style, pattern);
        FcConfigSubstitute(fl.config, pattern, FcMatchPattern);
        FcDefaultSubstitute(pattern);

        FcResult res;
        auto match = FcFontSetMatch(fl.config, &fs, 1, pattern, &res);
        if (!match) return null;
        scope(exit) FcPatternDestroy(match);
        return fl.typefaceFromPattern(match);
    }
}

class FcTypeface : FtTypeface
{
    import std.typecons : Nullable;

    private FcPattern* _font;

    this(FT_Face face, FcPattern* font) {
        super(face);
        _font = font;
        FcPatternReference(_font);
    }

    override void dispose() {
        FcPatternDestroy(_font);
    }

    override @property string family() {
        return getFcString(_font, FC_FAMILY, "");
    }

    override @property FontStyle style() {
        return fcPatternToFontStyle(_font);
    }

    override CodepointSet buildCoverage() {
        FcCharSet* csval;
        if (FcPatternGetCharSet(_font, FC_CHARSET, 0, &csval) == FcResultMatch) {
            return fcCharsetToCoverage(csval);
        }
        else {
            errorf("Cannot find charset in font %s to build coverage", family);
            return CodepointSet.init;
        }
    }
}

bool getFcBool(FcPattern *pattern, in string key, in bool defVal) {
    FcBool val;
    if (FcPatternGetBool(pattern, toStringz(key), 0, &val) != FcResultMatch) {
        return defVal;
    }
    return val != FcFalse;
}

int getFcInt(FcPattern* pattern, in string key, in int defVal) {
    int val;
    if (FcPatternGetInteger(pattern, toStringz(key), 0, &val) != FcResultMatch) {
        return defVal;
    }
    return val;
}

string getFcString(FcPattern* pattern, in string key, in string defVal) {
    FcChar8* val;
    if (FcPatternGetString(pattern, toStringz(key), 0, &val) != FcResultMatch) {
        return defVal;
    }
    return fromStringz(val).idup;
}

FontStyle fcPatternToFontStyle(FcPattern* pattern) {
    return FontStyle(
        cast(FontWeight)mapRange(
            getFcInt(pattern, FC_WEIGHT, FC_WEIGHT_NORMAL),
            fcWeights, dgtWeights
        ),
        fcSlantToSlant(
            getFcInt(pattern, FC_SLANT, FC_SLANT_ROMAN)
        ),
        cast(FontWidth)mapRange(
            getFcInt(pattern, FC_WIDTH, FC_WIDTH_NORMAL),
            fcWidths, dgtWidths
        ),
    );
}

void addFontStyleToFcPattern(in FontStyle fs, FcPattern* pattern) {
    const int weight = mapRange(cast(int)fs.weight, dgtWeights, fcWeights);
    const int slant = slantToFcSlant(fs.slant);
    const int width = mapRange(cast(int)fs.width, dgtWidths, fcWidths);

    FcPatternAddInteger(pattern, FC_WEIGHT, weight);
    FcPatternAddInteger(pattern, FC_SLANT, slant);
    FcPatternAddInteger(pattern, FC_WIDTH, width);
}

int slantToFcSlant(in FontSlant slant)
{
    final switch(slant)
    {
        case FontSlant.normal:
            return FC_SLANT_ROMAN;
        case FontSlant.italic:
            return FC_SLANT_ITALIC;
        case FontSlant.oblique:
            return FC_SLANT_OBLIQUE;
    }
}

FontSlant fcSlantToSlant(in int slant)
{
    switch(slant)
    {
        case FC_SLANT_ROMAN:
            return FontSlant.normal;
        case FC_SLANT_ITALIC:
            return FontSlant.italic;
        case FC_SLANT_OBLIQUE:
            return FontSlant.oblique;
        default:
            warningf("fontconfig slant %d do not match a FontSlant", slant);
            return FontSlant.normal;
    }
}

immutable int[] fcWeights = [
    FC_WEIGHT_THIN,
    FC_WEIGHT_EXTRALIGHT,
    FC_WEIGHT_LIGHT,
    FC_WEIGHT_NORMAL,
    FC_WEIGHT_MEDIUM,
    FC_WEIGHT_SEMIBOLD,
    FC_WEIGHT_BOLD,
    FC_WEIGHT_BLACK,
    FC_WEIGHT_EXTRABLACK,
];
immutable dgtWeights = [
    cast(int)FontWeight.thin,
    cast(int)FontWeight.extraLight,
    cast(int)FontWeight.light,
    cast(int)FontWeight.normal,
    cast(int)FontWeight.medium,
    cast(int)FontWeight.semiBold,
    cast(int)FontWeight.bold,
    cast(int)FontWeight.large,
    cast(int)FontWeight.extraLarge,
];

immutable int[] fcWidths = [
    FC_WIDTH_ULTRACONDENSED,
    FC_WIDTH_EXTRACONDENSED,
    FC_WIDTH_CONDENSED,
    FC_WIDTH_SEMICONDENSED,
    FC_WIDTH_NORMAL,
    FC_WIDTH_SEMIEXPANDED,
    FC_WIDTH_EXPANDED,
    FC_WIDTH_EXTRAEXPANDED,
    FC_WIDTH_ULTRAEXPANDED,
];
immutable int[] dgtWidths = [
    cast(int)FontWidth.ultraCondensed,
    cast(int)FontWidth.extraCondensed,
    cast(int)FontWidth.condensed,
    cast(int)FontWidth.semiCondensed,
    cast(int)FontWidth.normal,
    cast(int)FontWidth.semiExpanded,
    cast(int)FontWidth.expanded,
    cast(int)FontWidth.extraExpanded,
    cast(int)FontWidth.ultraExpanded,
];

int mapRange(in int lookUp, const(int)[] from, const(int)[] to)
in {
    import std.algorithm : isSorted;
    assert(from.length == to.length && from.length > 1);
    assert(isSorted(from) && isSorted(to));
}
body {
    if (lookUp < from[0]) return to[0];

    size_t bef = 0;
    size_t aft = 1;
    while (aft < from.length) {
        if (lookUp == from[bef]) return to[bef];
        assert(lookUp > from[bef]);
        if (lookUp < from[aft]) {
            import std.math: round;
            return cast(int)round(to[bef] +
                (lookUp-from[bef]) * (to[aft]-to[bef]) / (cast(float)(from[aft]-from[bef]))
            );
        }
        bef++;
        aft++;
    }

    return to[$-1];
}

unittest {
    assert(mapRange(FC_WIDTH_SEMICONDENSED, fcWidths, dgtWidths) == cast(int)FontWidth.semiCondensed);
}

CodepointSet fcCharsetToCoverage(FcCharSet* cs)
{
    import std.typecons : Flag, Yes, No;

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
        foreach (const uint i, bits; map)
        {
            foreach (const dchar cp; base+i*32 .. base+i*64)
            {
                const cIsIn = (bits & 1) ? Yes.included : No.included;
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
