module dgt.bindings.fontconfig.load;

import dgt.bindings;
import dgt.bindings.fontconfig.symbols;

/// Load the fontconfig library symbols.
/// Must be called before any use of hb_* functions.
/// If no libNames is provided, a per-platform guess is performed.
public void loadFontconfigSymbols(string[] libNames = [])
{
    version (linux)
    {
        auto defaultLibNames = ["libfontconfig.so", "libfontconfig.so.1"];
    }
    else version (Windows)
    {
        auto defaultLibNames = ["fontconfig.dll", "libfontconfig.dll", "libfontconfig-1.dll"];
    }
    if (libNames.length == 0)
    {
        libNames = defaultLibNames;
    }
    fontconfigLoader.load(libNames);
}

/// Checks whether fontconfig is loaded
public @property bool fontconfigLoaded()
{
    return fontconfigLoader.loaded;
}

private __gshared FontconfigLoader fontconfigLoader;

shared static this()
{
    fontconfigLoader = new FontconfigLoader();
}

shared static ~this()
{
    fontconfigLoader.unload();
}

alias FontconfigLoader = SymbolLoader!(
/* fcblanks.c */
    FcBlanksCreate,
    FcBlanksDestroy,
    FcBlanksAdd,
    FcBlanksIsMember,
/* fccache.c */
    FcCacheDir,
    FcCacheCopySet,
    FcCacheSubdir,
    FcCacheNumSubdir,
    FcCacheNumFont,
    FcDirCacheUnlink,
    FcDirCacheValid,
    FcDirCacheClean,
    FcCacheCreateTagFile,
/* fccfg.c */
    FcConfigHome,
    FcConfigEnableHome,
    FcConfigFilename,
    FcConfigCreate,
    FcConfigReference,
    FcConfigDestroy,
    FcConfigSetCurrent,
    FcConfigGetCurrent,
    FcConfigUptoDate,
    FcConfigBuildFonts,
    FcConfigGetFontDirs,
    FcConfigGetConfigDirs,
    FcConfigGetConfigFiles,
    FcConfigGetCache,
    FcConfigGetBlanks,
    FcConfigGetCacheDirs,
    FcConfigGetRescanInterval,
    FcConfigSetRescanInterval,
    FcConfigGetFonts,
    FcConfigAppFontAddFile,
    FcConfigAppFontAddDir,
    FcConfigAppFontClear,
    FcConfigSubstituteWithPat,
    FcConfigSubstitute,
    FcConfigGetSysRoot,
    FcConfigSetSysRoot,
/* fccharset.c */
    FcCharSetCreate,
    FcCharSetDestroy,
    FcCharSetAddChar,
    FcCharSetDelChar,
    FcCharSetCopy,
    FcCharSetEqual,
    FcCharSetIntersect,
    FcCharSetUnion,
    FcCharSetSubtract,
    FcCharSetMerge,
    FcCharSetHasChar,
    FcCharSetCount,
    FcCharSetIntersectCount,
    FcCharSetSubtractCount,
    FcCharSetIsSubset,
    FcCharSetFirstPage,
    FcCharSetNextPage,
/*
 * old coverage , rather hard to use correctly
 */
    FcCharSetCoverage,
/* fcdbg.c */
    FcValuePrint,
    FcPatternPrint,
    FcFontSetPrint,
/* fcdefault.c */
    FcGetDefaultLangs,
    FcDefaultSubstitute,
/* fcdir.c */
    FcFileIsDir,
    FcFileScan,
    FcDirScan,
    FcDirSave,
    FcDirCacheLoad,
    FcDirCacheRescan,
    FcDirCacheRead,
//     FcDirCacheLoadFile,
    FcDirCacheUnload,
/* fcfreetype.c */
    FcFreeTypeQuery,
/* fcfs.c */
    FcFontSetCreate,
    FcFontSetDestroy,
    FcFontSetAdd,
/* fcinit.c */
    FcInitLoadConfig,
    FcInitLoadConfigAndFonts,
    FcInit,
    FcFini,
    FcGetVersion,
    FcInitReinitialize,
    FcInitBringUptoDate,
/* fclang.c */
    FcGetLangs,
    FcLangNormalize,
    FcLangGetCharSet,
    FcLangSetCreate,
    FcLangSetDestroy,
    FcLangSetCopy,
    FcLangSetAdd,
    FcLangSetDel,
    FcLangSetHasLang,
    FcLangSetCompare,
    FcLangSetContains,
    FcLangSetEqual,
    FcLangSetHash,
    FcLangSetGetLangs,
    FcLangSetUnion,
    FcLangSetSubtract,
/* fclist.c */
    FcObjectSetCreate,
    FcObjectSetAdd,
    FcObjectSetDestroy,
//    FcObjectSetVaBuild,
//    FcObjectSetBuild, // FC_ATTRIBUTE_SENTINEL()
    FcFontSetList,
    FcFontList,
/* fcatomic.c */
    FcAtomicCreate,
    FcAtomicLock,
    FcAtomicNewFile,
    FcAtomicOrigFile,
    FcAtomicReplaceOrig,
    FcAtomicDeleteNew,
    FcAtomicUnlock,
    FcAtomicDestroy,
/* fcmatch.c */
    FcFontSetMatch,
    FcFontMatch,
    FcFontRenderPrepare,
    FcFontSetSort,
    FcFontSort,
    FcFontSetSortDestroy,
/* fcmatrix.c */
    FcMatrixCopy,
    FcMatrixEqual,
    FcMatrixMultiply,
    FcMatrixRotate,
    FcMatrixScale,
    FcMatrixShear,
/* fcname.c */
    FcNameGetConstant,
    FcNameConstant,
    FcNameParse,
    FcNameUnparse,
/* fcpat.c */
    FcPatternCreate,
    FcPatternDuplicate,
    FcPatternReference,
    FcPatternFilter,
    FcValueDestroy,
    FcValueEqual,
    FcValueSave,
    FcPatternDestroy,
    FcPatternEqual,
    FcPatternEqualSubset,
    FcPatternHash,
    FcPatternAdd,
    FcPatternAddWeak,
    FcPatternGet,
    FcPatternDel,
    FcPatternRemove,
    FcPatternAddInteger,
    FcPatternAddDouble,
    FcPatternAddString,
    FcPatternAddMatrix,
    FcPatternAddCharSet,
    FcPatternAddBool,
    FcPatternAddLangSet,
    FcPatternAddRange,
    FcPatternGetInteger,
    FcPatternGetDouble,
    FcPatternGetString,
    FcPatternGetMatrix,
    FcPatternGetCharSet,
    FcPatternGetBool,
    FcPatternGetLangSet,
    FcPatternGetRange,
//     FcPatternVaBuild,
//     FcPatternBuild, /*FC_ATTRIBUTE_SENTINEL()*/
    FcPatternFormat,
/* fcrange.c */
    FcRangeCreateDouble,
    FcRangeCreateInteger,
    FcRangeDestroy,
    FcRangeCopy,
    FcRangeGetDouble,
/* fcweight.c */
    FcWeightFromOpenType,
    FcWeightToOpenType,
/* fcstr.c */
    FcStrCopy,
    FcStrCopyFilename,
    FcStrPlus,
    FcStrFree,
    FcStrDowncase,
    FcStrCmpIgnoreCase,
    FcStrCmp,
    FcStrStrIgnoreCase,
    FcStrStr,
    FcUtf8ToUcs4,
    FcUtf8Len,
    FcUcs4ToUtf8,
    FcUtf16ToUcs4, /* in bytes */
    FcUtf16Len,
    FcStrDirname,
    FcStrBasename,
    FcStrSetCreate,
    FcStrSetMember,
    FcStrSetEqual,
    FcStrSetAdd,
    FcStrSetAddFilename,
    FcStrSetDel,
    FcStrSetDestroy,
    FcStrListCreate,
    FcStrListFirst,
    FcStrListNext,
    FcStrListDone,
/* fcxml.c */
    FcConfigParseAndLoad,
);
