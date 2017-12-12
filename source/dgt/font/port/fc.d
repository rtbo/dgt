module dgt.font.port.fc;

version(linux):

import dgt.bindings.fontconfig;
import dgt.bindings.fontconfig.load : loadFontconfigSymbols;
import dgt.font.library;
import dgt.font.style;
import dgt.font.typeface;
import gfx.foundation.rc;

import std.experimental.logger;
import std.string;

class FcFontLibrary : FontLibrary
{
    private FcConfig *config;
    private string[] families;

    this() {
        config = FcInitLoadConfigAndFonts();
        families = getFamilies(config);
    }

    override void dispose() {
        FcConfigDestroy(config);
        FcFini();
    }

    override @property size_t length() {
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
            // is the following necessary?
            .filter!(f => familyMatches(f, family))
            .map!(f => FcFontRenderPrepare(config, f, pattern))
            .each!(f => FcFontSetAdd(fontSet, f));

        return new FcFamilyStyleSet(family, fontSet);
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
            // is the following necessary?
            .filter!(f => familyMatches(f, family))
            .map!(f => FcFontRenderPrepare(config, f, pattern))
            .each!(f => FcFontSetAdd(fontSet, f));

        return new FcFamilyStyleSet(family, fontSet);
    }

}

private:

shared static this() {
    loadFontconfigSymbols();
}

@property bool isAccessible(FcPattern* pattern) {
    import std.file : exists;
    return exists(getFcString(pattern, FC_FILE, ""));
}

bool familyMatches(FcPattern* pattern, string family) {
    import std.uni : sicmp;
    foreach (const i; 0 .. 16) {
        FcChar8* val;
        const res = FcPatternGetString(pattern, FC_FAMILY, i, &val);
        if (res == FcResultNoId) {
            break;
        }
        if (res == FcResultNoMatch) {
            continue;
        }
        const f = fromStringz(val).idup;
        if (sicmp(f, family) == 0) return true;
    }
    return false;
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

    override @property size_t length() {
        return fs.nfont;
    }

    override FontStyle style(in size_t index) {
        auto pattern = fs.fonts[index];
        return fcPatternToFontStyle(pattern);
    }

    override Typeface createTypeface(in size_t index) {
        return null;
    }
}

string[] getFamilies(FcConfig* cfg) {
    string[] families;
    immutable sets = [ FcSetSystem, FcSetApplication ];
    foreach (s; sets) {
        auto fontSet = FcConfigGetFonts(cfg, s);
        if (!fontSet) continue;

        foreach (FcPattern* font; fontSet.fonts[0 .. fontSet.nfont]) {
            int id=0;
            while (1) {
                FcChar8* fcName;
                const res = FcPatternGetString(font, FC_FAMILY, id, &fcName);
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


/// template that resolves to true if an object of type T can be assigned to null
template isNullAssignable(T) {
    enum isNullAssignable =
        is(typeof((inout int = 0) {
            T t = T.init;
            t = null;
        }));
}


template GenericRc(T, alias CreateF, alias RefF, alias ReleaseF)
if (isNullAssignable!T)
{
    struct GenericRc
    {
        private T _obj;

        @disable this();
        this(T obj) {
            import std.exception : enforce;
            enforce(obj, "contructing GenericRc!("~T.stringof~") with an invalid reference");
            RefF(obj);
            _obj = obj;
        }
        this(this) {
            RefF(_obj);
        }
        ~this() {
            ReleaseF(_obj);
            _obj = null;
        }

        // trick to define a ctor that do not call RefT
        // and therefore allow create to not release the reference
        private enum CtorTok { _ }
        private this(T obj, CtorTok _) {
            _obj = obj;
        }

        static GenericRc create(Args...)(Args args) {
            import std.exception : enforce;
            auto obj = CreateF(args);
            enforce(obj, CreateF.stringof~" returned an invalid reference");
            return GenericRc(obj);
        }

        @property inout(T) obj() inout {
            return _obj;
        }

        alias obj this;
    }
}

alias FcPatternRc = GenericRc!(FcPattern*, FcPatternCreate, FcPatternReference, FcPatternDestroy);
