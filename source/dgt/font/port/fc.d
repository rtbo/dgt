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
import std.uni;

class FcFontLibrary : FontLibrary
{
    this() {
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

    override @property size_t familyCount() {
        return families.length;
    }

    override string family(in size_t index) {
        return families[index];
    }

    override FamilyStyleSet matchFamily(string family) {
        auto pattern = FcPatternCreate();
        scope(exit) FcPatternDestroy(pattern);

        FcPatternAddString(pattern, FC_FAMILY, toStringz(family));
        FcConfigSubstitute(config, pattern, FcMatchPattern);
        FcDefaultSubstitute(pattern);

        FcResult res;
        auto matches = FcFontSort(config, pattern, FcFalse, null, &res);
        scope(exit) FcFontSetDestroy(matches);

        auto fontSet = FcFontSetCreate();

        import std.algorithm : each, filter, map;
        import std.range : iota;
        iota(matches.nfont)
            .map!(i => matches.fonts[i])
            .filter!(f => f.isAccessible)
            .filter!(f => familyMatches(f, pattern))
            .map!(f => FcFontRenderPrepare(config, pattern, f))
            .each!(f => FcFontSetAdd(fontSet, f));

        return new FcFamilyStyleSet(this, family, fontSet);
    }

    override Typeface matchFamilyStyle(string family, in FontStyle style) {
        auto pattern = FcPatternCreate();
        scope(exit) FcPatternDestroy(pattern);

        FcPatternAddString(pattern, FC_FAMILY, toStringz(family));
        addFontStyleToFcPattern(style, pattern);
        FcConfigSubstitute(config, pattern, FcMatchPattern);
        FcDefaultSubstitute(pattern);

        FcResult res;
        auto font = FcFontMatch(config, pattern, &res);
        if (!font) return null;
        scope(exit) FcPatternDestroy(font);
        if (!font.isAccessible) return null;

        return typefaceFromPattern(font);
    }

    override Typeface createFromMemory(const(ubyte)[] data, int faceIndex)
    {
        auto face = openFaceFromMemory(data, faceIndex);
        return new FtTypeface(face);
    }

    override Typeface createFromFile(in string path, int faceIndex)
    {
        auto face = openFaceFromFile(path, faceIndex);
        return new FtTypeface(face);
    }

    private Typeface typefaceFromPattern(FcPattern* font) {
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
        return tf;
    }

    private FcConfig *config;
    private string[] families;
    private TypefaceCache tfCache;
}

private:


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

    override Typeface createTypeface(in size_t index) {
        return fl.typefaceFromPattern(fs.fonts[index]);
    }

    override Typeface matchStyle(in FontStyle style) {
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

bool familyMatches(FcPattern* font, FcPattern* pattern) {
    import std.uni : sicmp;
    foreach (const pi; 0 .. 16) {
        FcChar8* val;
        const pres = FcPatternGetString(pattern, FC_FAMILY, pi, &val);
        if (pres == FcResultNoId) {
            break;
        }
        if (pres == FcResultNoMatch) {
            continue;
        }
        const pf = fromStringz(val).idup;
        foreach (const fi; 0 .. 16) {
            const fres = FcPatternGetString(font, FC_FAMILY, fi, &val);
            if (fres == FcResultNoId) {
                break;
            }
            if (fres == FcResultNoMatch) {
                continue;
            }
            const ff = fromStringz(val).idup;
            if (sicmp(pf, ff) == 0) return true;
        }
    }
    return false;
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
