module dgt.bindings.fontconfig.symbols;

import dgt.bindings.fontconfig.types;
import dgt.bindings;

/* fcblanks.c */
__gshared Symbol!(FcBlanks*,) FcBlanksCreate;

__gshared Symbol!(void, FcBlanks*) FcBlanksDestroy;

__gshared Symbol!(FcBool, FcBlanks*, FcChar32) FcBlanksAdd;

__gshared Symbol!(FcBool, FcBlanks*, FcChar32) FcBlanksIsMember;

/* fccache.c */

__gshared Symbol!(const(FcChar8)*, const(FcCache)*) FcCacheDir;

__gshared Symbol!(FcFontSet*, const(FcCache)*) FcCacheCopySet;

__gshared Symbol!(const(FcChar8)*, const(FcCache)*, int) FcCacheSubdir;

__gshared Symbol!(int, const(FcCache)*) FcCacheNumSubdir;

__gshared Symbol!(int, const(FcCache)*) FcCacheNumFont;

__gshared Symbol!(FcBool, const(FcChar8)*, FcConfig*) FcDirCacheUnlink;

__gshared Symbol!(FcBool, const(FcChar8)*) FcDirCacheValid;

__gshared Symbol!(FcBool, const(FcChar8)*, FcBool) FcDirCacheClean;

__gshared Symbol!(void, const(FcConfig)*) FcCacheCreateTagFile;

/* fccfg.c */
__gshared Symbol!(FcChar8*,) FcConfigHome;

__gshared Symbol!(FcBool, FcBool) FcConfigEnableHome;

__gshared Symbol!(FcChar8*, const(FcChar8)*) FcConfigFilename;

__gshared Symbol!(FcConfig*,) FcConfigCreate;

__gshared Symbol!(FcConfig*, FcConfig*) FcConfigReference;

__gshared Symbol!(void, FcConfig*) FcConfigDestroy;

__gshared Symbol!(FcBool, FcConfig*) FcConfigSetCurrent;

__gshared Symbol!(FcConfig*,) FcConfigGetCurrent;

__gshared Symbol!(FcBool, FcConfig*) FcConfigUptoDate;

__gshared Symbol!(FcBool, FcConfig*) FcConfigBuildFonts;

__gshared Symbol!(FcStrList*, FcConfig*) FcConfigGetFontDirs;

__gshared Symbol!(FcStrList*, FcConfig*) FcConfigGetConfigDirs;

__gshared Symbol!(FcStrList*, FcConfig*) FcConfigGetConfigFiles;

__gshared Symbol!(FcChar8*, FcConfig*) FcConfigGetCache;

__gshared Symbol!(FcBlanks*, FcConfig*) FcConfigGetBlanks;

__gshared Symbol!(FcStrList*, const(FcConfig)*) FcConfigGetCacheDirs;

__gshared Symbol!(int, FcConfig*) FcConfigGetRescanInterval;

__gshared Symbol!(FcBool, FcConfig*, int) FcConfigSetRescanInterval;

__gshared Symbol!(FcFontSet*, FcConfig*, FcSetName) FcConfigGetFonts;

__gshared Symbol!(FcBool, FcConfig*, const(FcChar8)*) FcConfigAppFontAddFile;

__gshared Symbol!(FcBool, FcConfig*, const(FcChar8)*) FcConfigAppFontAddDir;

__gshared Symbol!(void, FcConfig*) FcConfigAppFontClear;

__gshared Symbol!(FcBool, FcConfig*, FcPattern*, FcPattern*, FcMatchKind) FcConfigSubstituteWithPat;

__gshared Symbol!(FcBool, FcConfig*, FcPattern*, FcMatchKind) FcConfigSubstitute;

__gshared Symbol!(const(FcChar8)*, const(FcConfig)*) FcConfigGetSysRoot;

__gshared Symbol!(void, FcConfig*, const(FcChar8)*) FcConfigSetSysRoot;

/* fccharset.c */
__gshared Symbol!(FcCharSet*,) FcCharSetCreate;

__gshared Symbol!(void, FcCharSet*) FcCharSetDestroy;

__gshared Symbol!(FcBool, FcCharSet*, FcChar32) FcCharSetAddChar;

__gshared Symbol!(FcBool, FcCharSet*, FcChar32) FcCharSetDelChar;

__gshared Symbol!(FcCharSet*, FcCharSet*) FcCharSetCopy;

__gshared Symbol!(FcBool, const(FcCharSet)*, const(FcCharSet)*) FcCharSetEqual;

__gshared Symbol!(FcCharSet*, const(FcCharSet)*, const(FcCharSet)*) FcCharSetIntersect;

__gshared Symbol!(FcCharSet*, const(FcCharSet)*, const(FcCharSet)*) FcCharSetUnion;

__gshared Symbol!(FcCharSet*, const(FcCharSet)*, const(FcCharSet)*) FcCharSetSubtract;

__gshared Symbol!(FcBool, FcCharSet*, const(FcCharSet)*, FcBool*) FcCharSetMerge;

__gshared Symbol!(FcBool, const(FcCharSet)*, FcChar32) FcCharSetHasChar;

__gshared Symbol!(FcChar32, const(FcCharSet)*) FcCharSetCount;

__gshared Symbol!(FcChar32, const(FcCharSet)*, const(FcCharSet)*) FcCharSetIntersectCount;

__gshared Symbol!(FcChar32, const(FcCharSet)*, const(FcCharSet)*) FcCharSetSubtractCount;

__gshared Symbol!(FcBool, const(FcCharSet)*, const(FcCharSet)*) FcCharSetIsSubset;

enum FC_CHARSET_MAP_SIZE = 256 / 32;
enum FC_CHARSET_DONE = cast()-1;

__gshared Symbol!(FcChar32, const(FcCharSet)*, FcChar32[FC_CHARSET_MAP_SIZE], FcChar32*) FcCharSetFirstPage;

__gshared Symbol!(FcChar32, const(FcCharSet)*, FcChar32[FC_CHARSET_MAP_SIZE], FcChar32*) FcCharSetNextPage;

/*
 * old coverage , rather hard to use correctly
 */

__gshared Symbol!(FcChar32, const(FcCharSet)*, FcChar32, FcChar32*) FcCharSetCoverage;

/* fcdbg.c */
__gshared Symbol!(void, const(FcValue)) FcValuePrint;

__gshared Symbol!(void, const(FcPattern)*) FcPatternPrint;

__gshared Symbol!(void, const(FcFontSet)*) FcFontSetPrint;

/* fcdefault.c */
__gshared Symbol!(FcStrSet*,) FcGetDefaultLangs;

__gshared Symbol!(void, FcPattern*) FcDefaultSubstitute;

/* fcdir.c */
__gshared Symbol!(FcBool, const(FcChar8)*) FcFileIsDir;

__gshared Symbol!(FcBool, FcFontSet*, FcStrSet*, FcFileCache*, FcBlanks*,
        const(FcChar8)*, FcBool) FcFileScan;

__gshared Symbol!(FcBool, FcFontSet*, FcStrSet*, FcFileCache*, FcBlanks*,
        const(FcChar8)*, FcBool) FcDirScan;

__gshared Symbol!(FcBool, FcFontSet*, FcStrSet*, const(FcChar8)*) FcDirSave;

__gshared Symbol!(FcCache*, const(FcChar8)*, FcConfig*, FcChar8**) FcDirCacheLoad;

__gshared Symbol!(FcCache*, const(FcChar8)*, FcConfig*) FcDirCacheRescan;

__gshared Symbol!(FcCache*, const(FcChar8)*, FcBool, FcConfig*) FcDirCacheRead;

// __gshared Symbol!(FcCache * , const(FcChar8) *, struct stat *) FcDirCacheLoadFile;

__gshared Symbol!(void, FcCache*) FcDirCacheUnload;

/* fcfreetype.c */
__gshared Symbol!(FcPattern*, const(FcChar8)*, int, FcBlanks*, int*) FcFreeTypeQuery;

/* fcfs.c */

__gshared Symbol!(FcFontSet*,) FcFontSetCreate;

__gshared Symbol!(void, FcFontSet*) FcFontSetDestroy;

__gshared Symbol!(FcBool, FcFontSet*, FcPattern*) FcFontSetAdd;

/* fcinit.c */
__gshared Symbol!(FcConfig*,) FcInitLoadConfig;

__gshared Symbol!(FcConfig*,) FcInitLoadConfigAndFonts;

__gshared Symbol!(FcBool,) FcInit;

__gshared Symbol!(void,) FcFini;

__gshared Symbol!(int,) FcGetVersion;

__gshared Symbol!(FcBool,) FcInitReinitialize;

__gshared Symbol!(FcBool,) FcInitBringUptoDate;

/* fclang.c */
__gshared Symbol!(FcStrSet*,) FcGetLangs;

__gshared Symbol!(FcChar8*, const(FcChar8)*) FcLangNormalize;

__gshared Symbol!(const(FcCharSet)*, const(FcChar8)*) FcLangGetCharSet;

__gshared Symbol!(FcLangSet*,) FcLangSetCreate;

__gshared Symbol!(void, FcLangSet*) FcLangSetDestroy;

__gshared Symbol!(FcLangSet*, const(FcLangSet)*) FcLangSetCopy;

__gshared Symbol!(FcBool, FcLangSet*, const(FcChar8)*) FcLangSetAdd;

__gshared Symbol!(FcBool, FcLangSet*, const(FcChar8)*) FcLangSetDel;

__gshared Symbol!(FcLangResult, const(FcLangSet)*, const(FcChar8)*) FcLangSetHasLang;

__gshared Symbol!(FcLangResult, const(FcLangSet)*, const(FcLangSet)*) FcLangSetCompare;

__gshared Symbol!(FcBool, const(FcLangSet)*, const(FcLangSet)*) FcLangSetContains;

__gshared Symbol!(FcBool, const(FcLangSet)*, const(FcLangSet)*) FcLangSetEqual;

__gshared Symbol!(FcChar32, const(FcLangSet)*) FcLangSetHash;

__gshared Symbol!(FcStrSet*, const(FcLangSet)*) FcLangSetGetLangs;

__gshared Symbol!(FcLangSet*, const(FcLangSet)*, const(FcLangSet)*) FcLangSetUnion;

__gshared Symbol!(FcLangSet*, const(FcLangSet)*, const(FcLangSet)*) FcLangSetSubtract;

/* fclist.c */
__gshared Symbol!(FcObjectSet*,) FcObjectSetCreate;

__gshared Symbol!(FcBool, FcObjectSet*, const(char)*) FcObjectSetAdd;

__gshared Symbol!(void, FcObjectSet*) FcObjectSetDestroy;

//__gshared Symbol!(FcObjectSet * , const(char) *, va_list ) FcObjectSetVaBuild;

//__gshared Symbol!(FcObjectSet *, const(char) *, ...) FcObjectSetBuild; // FC_ATTRIBUTE_SENTINEL()

__gshared Symbol!(FcFontSet*, FcConfig*, FcFontSet**, int, FcPattern*, FcObjectSet*) FcFontSetList;

__gshared Symbol!(FcFontSet*, FcConfig*, FcPattern*, FcObjectSet*) FcFontList;

/* fcatomic.c */

__gshared Symbol!(FcAtomic*, const(FcChar8)*) FcAtomicCreate;

__gshared Symbol!(FcBool, FcAtomic*) FcAtomicLock;

__gshared Symbol!(FcChar8*, FcAtomic*) FcAtomicNewFile;

__gshared Symbol!(FcChar8*, FcAtomic*) FcAtomicOrigFile;

__gshared Symbol!(FcBool, FcAtomic*) FcAtomicReplaceOrig;

__gshared Symbol!(void, FcAtomic*) FcAtomicDeleteNew;

__gshared Symbol!(void, FcAtomic*) FcAtomicUnlock;

__gshared Symbol!(void, FcAtomic*) FcAtomicDestroy;

/* fcmatch.c */
__gshared Symbol!(FcPattern*, FcConfig*, FcFontSet**, int, FcPattern*, FcResult*) FcFontSetMatch;

__gshared Symbol!(FcPattern*, FcConfig*, FcPattern*, FcResult*) FcFontMatch;

__gshared Symbol!(FcPattern*, FcConfig*, FcPattern*, FcPattern*) FcFontRenderPrepare;

__gshared Symbol!(FcFontSet*, FcConfig*, FcFontSet**, int, FcPattern*,
        FcBool, FcCharSet**, FcResult*) FcFontSetSort;

__gshared Symbol!(FcFontSet*, FcConfig*, FcPattern*, FcBool, FcCharSet**, FcResult*) FcFontSort;

__gshared Symbol!(void, FcFontSet*) FcFontSetSortDestroy;

/* fcmatrix.c */
__gshared Symbol!(FcMatrix*, const(FcMatrix)*) FcMatrixCopy;

__gshared Symbol!(FcBool, const(FcMatrix)*, const(FcMatrix)*) FcMatrixEqual;

__gshared Symbol!(void, FcMatrix*, const(FcMatrix)*, const(FcMatrix)*) FcMatrixMultiply;

__gshared Symbol!(void, FcMatrix*, double, double) FcMatrixRotate;

__gshared Symbol!(void, FcMatrix*, double, double) FcMatrixScale;

__gshared Symbol!(void, FcMatrix*, double, double) FcMatrixShear;

/* fcname.c */

__gshared Symbol!(const(FcConstant)*, const(FcChar8)*) FcNameGetConstant;

__gshared Symbol!(FcBool, const(FcChar8)*, int*) FcNameConstant;

__gshared Symbol!(FcPattern*, const(FcChar8)*) FcNameParse;

__gshared Symbol!(FcChar8*, FcPattern*) FcNameUnparse;

/* fcpat.c */
__gshared Symbol!(FcPattern*,) FcPatternCreate;

__gshared Symbol!(FcPattern*, const(FcPattern)*) FcPatternDuplicate;

__gshared Symbol!(void, FcPattern*) FcPatternReference;

__gshared Symbol!(FcPattern*, FcPattern*, const(FcObjectSet)*) FcPatternFilter;

__gshared Symbol!(void, FcValue) FcValueDestroy;

__gshared Symbol!(FcBool, FcValue, FcValue) FcValueEqual;

__gshared Symbol!(FcValue, FcValue) FcValueSave;

__gshared Symbol!(void, FcPattern*) FcPatternDestroy;

__gshared Symbol!(FcBool, const(FcPattern)*, const(FcPattern)*) FcPatternEqual;

__gshared Symbol!(FcBool, const(FcPattern)*, const(FcPattern)*, const(FcObjectSet)*) FcPatternEqualSubset;

__gshared Symbol!(FcChar32, const(FcPattern)*) FcPatternHash;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, FcValue, FcBool) FcPatternAdd;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, FcValue, FcBool) FcPatternAddWeak;

__gshared Symbol!(FcResult, const(FcPattern)*, const(char)*, int, FcValue*) FcPatternGet;

__gshared Symbol!(FcBool, FcPattern*, const(char)*) FcPatternDel;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, int) FcPatternRemove;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, int) FcPatternAddInteger;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, double) FcPatternAddDouble;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, const(FcChar8)*) FcPatternAddString;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, const(FcMatrix)*) FcPatternAddMatrix;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, const(FcCharSet)*) FcPatternAddCharSet;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, FcBool) FcPatternAddBool;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, const(FcLangSet)*) FcPatternAddLangSet;

__gshared Symbol!(FcBool, FcPattern*, const(char)*, const(FcRange)*) FcPatternAddRange;

__gshared Symbol!(FcResult, const(FcPattern)*, const(char)*, int, int*) FcPatternGetInteger;

__gshared Symbol!(FcResult, const(FcPattern)*, const(char)*, int, double*) FcPatternGetDouble;

__gshared Symbol!(FcResult, const(FcPattern)*, const(char)*, int, FcChar8**) FcPatternGetString;

__gshared Symbol!(FcResult, const(FcPattern)*, const(char)*, int, FcMatrix**) FcPatternGetMatrix;

__gshared Symbol!(FcResult, const(FcPattern)*, const(char)*, int, FcCharSet**) FcPatternGetCharSet;

__gshared Symbol!(FcResult, const(FcPattern)*, const(char)*, int, FcBool*) FcPatternGetBool;

__gshared Symbol!(FcResult, const(FcPattern)*, const(char)*, int, FcLangSet**) FcPatternGetLangSet;

__gshared Symbol!(FcResult, const(FcPattern)*, const(char)*, int, FcRange**) FcPatternGetRange;

// __gshared Symbol!(FcPattern*, FcPattern*, va_list) FcPatternVaBuild;

// __gshared Symbol!(FcPattern *, FcPattern *, ...) FcPatternBuild; /*FC_ATTRIBUTE_SENTINEL()*/

__gshared Symbol!(FcChar8*, FcPattern*, const(FcChar8)*) FcPatternFormat;

/* fcrange.c */
__gshared Symbol!(FcRange*, double, double) FcRangeCreateDouble;

__gshared Symbol!(FcRange*, FcChar32, FcChar32) FcRangeCreateInteger;

__gshared Symbol!(void, FcRange*) FcRangeDestroy;

__gshared Symbol!(FcRange*, const(FcRange)*) FcRangeCopy;

__gshared Symbol!(FcBool, const(FcRange)*, double*, double*) FcRangeGetDouble;

/* fcweight.c */

__gshared Symbol!(int, int) FcWeightFromOpenType;

__gshared Symbol!(int, int) FcWeightToOpenType;

/* fcstr.c */

__gshared Symbol!(FcChar8*, const(FcChar8)*) FcStrCopy;

__gshared Symbol!(FcChar8*, const(FcChar8)*) FcStrCopyFilename;

__gshared Symbol!(FcChar8*, const(FcChar8)*, const(FcChar8)*) FcStrPlus;

__gshared Symbol!(void, FcChar8*) FcStrFree;

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

__gshared Symbol!(FcChar8*, const(FcChar8)*) FcStrDowncase;

__gshared Symbol!(int, const(FcChar8)*, const(FcChar8)*) FcStrCmpIgnoreCase;

__gshared Symbol!(int, const(FcChar8)*, const(FcChar8)*) FcStrCmp;

__gshared Symbol!(const(FcChar8)*, const(FcChar8)*, const(FcChar8)*) FcStrStrIgnoreCase;

__gshared Symbol!(const(FcChar8)*, const(FcChar8)*, const(FcChar8)*) FcStrStr;

__gshared Symbol!(int, const(FcChar8)*, FcChar32*, int) FcUtf8ToUcs4;

__gshared Symbol!(FcBool, const(FcChar8)*, int, int*, int*) FcUtf8Len;

enum FC_UTF8_MAX_LEN = 6;

__gshared Symbol!(int, FcChar32, FcChar8[FC_UTF8_MAX_LEN]) FcUcs4ToUtf8;

__gshared Symbol!(int, const(FcChar8)*, FcEndian, FcChar32*, int) FcUtf16ToUcs4; /* in bytes */

__gshared Symbol!(FcBool, const(FcChar8)*, FcEndian, int, /* in bytes */
        int*, int*) FcUtf16Len;

__gshared Symbol!(FcChar8*, const(FcChar8)*) FcStrDirname;

__gshared Symbol!(FcChar8*, const(FcChar8)*) FcStrBasename;

__gshared Symbol!(FcStrSet*,) FcStrSetCreate;

__gshared Symbol!(FcBool, FcStrSet*, const(FcChar8)*) FcStrSetMember;

__gshared Symbol!(FcBool, FcStrSet*, FcStrSet*) FcStrSetEqual;

__gshared Symbol!(FcBool, FcStrSet*, const(FcChar8)*) FcStrSetAdd;

__gshared Symbol!(FcBool, FcStrSet*, const(FcChar8)*) FcStrSetAddFilename;

__gshared Symbol!(FcBool, FcStrSet*, const(FcChar8)*) FcStrSetDel;

__gshared Symbol!(void, FcStrSet*) FcStrSetDestroy;

__gshared Symbol!(FcStrList*, FcStrSet*) FcStrListCreate;

__gshared Symbol!(void, FcStrList*) FcStrListFirst;

__gshared Symbol!(FcChar8*, FcStrList*) FcStrListNext;

__gshared Symbol!(void, FcStrList*) FcStrListDone;

/* fcxml.c */
__gshared Symbol!(FcBool, FcConfig*, const(FcChar8)*, FcBool) FcConfigParseAndLoad;
