module dgt.bindings.fontconfig.definitions;

import dgt.bindings;

mixin(globalEnumsAliasesCode!(
    FcType,
    FcResult,
    FcMatchKind,
    FcLangResult,
    FcSetName,
    FcEndian,
));

alias FcChar8 = char;
alias FcChar16 = wchar;
alias FcChar32 = dchar;
alias FcBool = int;

enum FC_MAJOR = 2;
enum FC_MINOR = 12;
enum FC_REVISION = 1;

enum FC_VERSION = FC_MAJOR * 10000 + FC_MINOR * 100 + FC_REVISION;

enum FC_CACHE_VERSION_NUMBER = 7;
enum FC_CACHE_VERSION = "7";

enum FcTrue = 1;
enum FcFalse = 0;

enum FC_FAMILY = "family" /* String */ ;
enum FC_STYLE = "style" /* String */ ;
enum FC_SLANT = "slant" /* Int */ ;
enum FC_WEIGHT = "weight" /* Int */ ;
enum FC_SIZE = "size" /* Range (double) */ ;
enum FC_ASPECT = "aspect" /* Double */ ;
enum FC_PIXEL_SIZE = "pixelsize" /* Double */ ;
enum FC_SPACING = "spacing" /* Int */ ;
enum FC_FOUNDRY = "foundry" /* String */ ;
enum FC_ANTIALIAS = "antialias" /* Bool (depends) */ ;
enum FC_HINTING = "hinting" /* Bool (true) */ ;
enum FC_HINT_STYLE = "hintstyle" /* Int */ ;
enum FC_VERTICAL_LAYOUT = "verticallayout" /* Bool (false) */ ;
enum FC_AUTOHINT = "autohint" /* Bool (false) */ ;
/* FC_GLOBAL_ADVANCE is deprecated. this is simply ignored on freetype 2.4.5 or later */
enum FC_GLOBAL_ADVANCE = "globaladvance" /* Bool (true) */ ;
enum FC_WIDTH = "width" /* Int */ ;
enum FC_FILE = "file" /* String */ ;
enum FC_INDEX = "index" /* Int */ ;
enum FC_FT_FACE = "ftface" /* FT_Face */ ;
enum FC_RASTERIZER = "rasterizer" /* String (deprecated) */ ;
enum FC_OUTLINE = "outline" /* Bool */ ;
enum FC_SCALABLE = "scalable" /* Bool */ ;
enum FC_COLOR = "color" /* Bool */ ;
enum FC_SCALE = "scale" /* double (deprecated) */ ;
enum FC_SYMBOL = "symbol" /* Bool */ ;
enum FC_DPI = "dpi" /* double */ ;
enum FC_RGBA = "rgba" /* Int */ ;
enum FC_MINSPACE = "minspace" /* Bool use minimum line spacing */ ;
enum FC_SOURCE = "source" /* String (deprecated) */ ;
enum FC_CHARSET = "charset" /* CharSet */ ;
enum FC_LANG = "lang" /* String RFC 3066 langs */ ;
enum FC_FONTVERSION = "fontversion" /* Int from 'head' table */ ;
enum FC_FULLNAME = "fullname" /* String */ ;
enum FC_FAMILYLANG = "familylang" /* String RFC 3066 langs */ ;
enum FC_STYLELANG = "stylelang" /* String RFC 3066 langs */ ;
enum FC_FULLNAMELANG = "fullnamelang" /* String RFC 3066 langs */ ;
enum FC_CAPABILITY = "capability" /* String */ ;
enum FC_FONTFORMAT = "fontformat" /* String */ ;
enum FC_EMBOLDEN = "embolden" /* Bool - true if emboldening needed*/ ;
enum FC_EMBEDDED_BITMAP = "embeddedbitmap" /* Bool - true to enable embedded bitmaps */ ;
enum FC_DECORATIVE = "decorative" /* Bool - true if style is a decorative variant */ ;
enum FC_LCD_FILTER = "lcdfilter" /* Int */ ;
enum FC_FONT_FEATURES = "fontfeatures" /* String */ ;
enum FC_NAMELANG = "namelang" /* String RFC 3866 langs */ ;
enum FC_PRGNAME = "prgname" /* String */ ;
enum FC_HASH = "hash" /* String (deprecated) */ ;
enum FC_POSTSCRIPT_NAME = "postscriptname" /* String */ ;

enum FC_CACHE_SUFFIX = ".cache-" ~ FC_CACHE_VERSION;
enum FC_DIR_CACHE_FILE = "fonts.cache-" ~ FC_CACHE_VERSION;
enum FC_USER_CACHE_FILE = ".fonts.cache-" ~ FC_CACHE_VERSION;

/* Adjust outline rasterizer */
enum FC_CHAR_WIDTH = "charwidth" /* Int */ ;
enum FC_CHAR_HEIGHT = "charheight" /* Int */ ;
enum FC_MATRIX = "matrix" /* FcMatrix */ ;

enum FC_WEIGHT_THIN = 0;
enum FC_WEIGHT_EXTRALIGHT = 40;
enum FC_WEIGHT_ULTRALIGHT = FC_WEIGHT_EXTRALIGHT;
enum FC_WEIGHT_LIGHT = 50;
enum FC_WEIGHT_DEMILIGHT = 55;
enum FC_WEIGHT_SEMILIGHT = FC_WEIGHT_DEMILIGHT;
enum FC_WEIGHT_BOOK = 75;
enum FC_WEIGHT_REGULAR = 80;
enum FC_WEIGHT_NORMAL = FC_WEIGHT_REGULAR;
enum FC_WEIGHT_MEDIUM = 100;
enum FC_WEIGHT_DEMIBOLD = 180;
enum FC_WEIGHT_SEMIBOLD = FC_WEIGHT_DEMIBOLD;
enum FC_WEIGHT_BOLD = 200;
enum FC_WEIGHT_EXTRABOLD = 205;
enum FC_WEIGHT_ULTRABOLD = FC_WEIGHT_EXTRABOLD;
enum FC_WEIGHT_BLACK = 210;
enum FC_WEIGHT_HEAVY = FC_WEIGHT_BLACK;
enum FC_WEIGHT_EXTRABLACK = 215;
enum FC_WEIGHT_ULTRABLACK = FC_WEIGHT_EXTRABLACK;

enum FC_SLANT_ROMAN = 0;
enum FC_SLANT_ITALIC = 100;
enum FC_SLANT_OBLIQUE = 110;

enum FC_WIDTH_ULTRACONDENSED = 50;
enum FC_WIDTH_EXTRACONDENSED = 63;
enum FC_WIDTH_CONDENSED = 75;
enum FC_WIDTH_SEMICONDENSED = 87;
enum FC_WIDTH_NORMAL = 100;
enum FC_WIDTH_SEMIEXPANDED = 113;
enum FC_WIDTH_EXPANDED = 125;
enum FC_WIDTH_EXTRAEXPANDED = 150;
enum FC_WIDTH_ULTRAEXPANDED = 200;

enum FC_PROPORTIONAL = 0;
enum FC_DUAL = 90;
enum FC_MONO = 100;
enum FC_CHARCELL = 110;

/* sub-pixel order */
enum FC_RGBA_UNKNOWN = 0;
enum FC_RGBA_RGB = 1;
enum FC_RGBA_BGR = 2;
enum FC_RGBA_VRGB = 3;
enum FC_RGBA_VBGR = 4;
enum FC_RGBA_NONE = 5;

/* hinting style */
enum FC_HINT_NONE = 0;
enum FC_HINT_SLIGHT = 1;
enum FC_HINT_MEDIUM = 2;
enum FC_HINT_FULL = 3;

/* LCD filter */
enum FC_LCD_NONE = 0;
enum FC_LCD_DEFAULT = 1;
enum FC_LCD_LIGHT = 2;
enum FC_LCD_LEGACY = 3;

enum FcType
{
    FcTypeUnknown = -1,
    FcTypeVoid,
    FcTypeInteger,
    FcTypeDouble,
    FcTypeString,
    FcTypeBool,
    FcTypeMatrix,
    FcTypeCharSet,
    FcTypeFTFace,
    FcTypeLangSet,
    FcTypeRange
}

struct FcMatrix
{
    double xx, xy, yx, yy;
}

void FcMatrixInit(ref FcMatrix m)
{
    m.xx = 1;
    m.yy = 1;
    m.xy = 0;
    m.yx = 0;
}


enum FC_CHARSET_MAP_SIZE = 256 / 32;
enum FC_CHARSET_DONE = cast()-1;

/* These are ASCII only, suitable only for pattern element names */
bool FcIsUpper(C)(C c)
{
    import std.conv : octal;

    return (octal!101 <= c) && (c <= octal!132);
}

bool FcIsLower(C)(C c)
{
    import std.conv : octal;

    return (octal!141 <= c) && (c <= octal!172);
}

C FcToLower(C)(C c)
{
    import std.conv : octal;

    return FcIsUpper() ? c - octal!101 + octal!141 : c;
}

enum FC_UTF8_MAX_LEN = 6;

/*
 * A data structure to represent the available glyphs in a font.
 * This is represented as a sparse boolean btree.
 */

struct FcCharSet;

struct FcObjectType
{
    char* object;
    FcType type;
}

struct FcConstant
{
    const FcChar8* name;
    const char* object;
    int value;
}

enum FcResult
{
    FcResultMatch,
    FcResultNoMatch,
    FcResultTypeMismatch,
    FcResultNoId,
    FcResultOutOfMemory
}

struct FcPattern;

struct FcLangSet;

struct FcRange;

struct FcValue
{
    union u_t
    {
        const FcChar8* s;
        int i;
        FcBool b;
        double d;
        const FcMatrix* m;
        const FcCharSet* c;
        void* f;
        const FcLangSet* l;
        const FcRange* r;
    }

    FcType type;
    u_t u;
}

struct FcFontSet
{
    int nfont;
    int sfont;
    FcPattern** fonts;
}

struct FcObjectSet
{
    int nobject;
    int sobject;
    const char** objects;
}

enum FcMatchKind
{
    FcMatchPattern,
    FcMatchFont,
    FcMatchScan
}

enum FcLangResult
{
    FcLangEqual = 0,
    FcLangDifferentCountry = 1,
    FcLangDifferentTerritory = 1,
    FcLangDifferentLang = 2
}

enum FcSetName
{
    FcSetSystem = 0,
    FcSetApplication = 1
}

struct FcAtomic;

enum FcEndian
{
    FcEndianBig,
    FcEndianLittle
}

struct FcConfig;

struct FcFileCache;

struct FcBlanks;

struct FcStrList;

struct FcStrSet;

struct FcCache;
