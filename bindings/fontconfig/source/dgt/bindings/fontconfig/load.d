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

class FontconfigLoader : SharedLibLoader
{
    override void bindSymbols()
    {
        /* fcblanks.c */
        bind!(FcBlanksCreate)();
        bind!(FcBlanksDestroy)();
        bind!(FcBlanksAdd)();
        bind!(FcBlanksIsMember)();
        /* fccache.c */
        bind!(FcCacheDir)();
        bind!(FcCacheCopySet)();
        bind!(FcCacheSubdir)();
        bind!(FcCacheNumSubdir)();
        bind!(FcCacheNumFont)();
        bind!(FcDirCacheUnlink)();
        bind!(FcDirCacheValid)();
        bind!(FcDirCacheClean)();
        bind!(FcCacheCreateTagFile)();
        /* fccfg.c */
        bind!(FcConfigHome)();
        bind!(FcConfigEnableHome)();
        bind!(FcConfigFilename)();
        bind!(FcConfigCreate)();
        bind!(FcConfigReference)();
        bind!(FcConfigDestroy)();
        bind!(FcConfigSetCurrent)();
        bind!(FcConfigGetCurrent)();
        bind!(FcConfigUptoDate)();
        bind!(FcConfigBuildFonts)();
        bind!(FcConfigGetFontDirs)();
        bind!(FcConfigGetConfigDirs)();
        bind!(FcConfigGetConfigFiles)();
        bind!(FcConfigGetCache)();
        bind!(FcConfigGetBlanks)();
        bind!(FcConfigGetCacheDirs)();
        bind!(FcConfigGetRescanInterval)();
        bind!(FcConfigSetRescanInterval)();
        bind!(FcConfigGetFonts)();
        bind!(FcConfigAppFontAddFile)();
        bind!(FcConfigAppFontAddDir)();
        bind!(FcConfigAppFontClear)();
        bind!(FcConfigSubstituteWithPat)();
        bind!(FcConfigSubstitute)();
        bind!(FcConfigGetSysRoot)();
        bind!(FcConfigSetSysRoot)();
        /* fccharset.c */
        bind!(FcCharSetCreate)();
        bind!(FcCharSetDestroy)();
        bind!(FcCharSetAddChar)();
        bind!(FcCharSetDelChar)();
        bind!(FcCharSetCopy)();
        bind!(FcCharSetEqual)();
        bind!(FcCharSetIntersect)();
        bind!(FcCharSetUnion)();
        bind!(FcCharSetSubtract)();
        bind!(FcCharSetMerge)();
        bind!(FcCharSetHasChar)();
        bind!(FcCharSetCount)();
        bind!(FcCharSetIntersectCount)();
        bind!(FcCharSetSubtractCount)();
        bind!(FcCharSetIsSubset)();
        bind!(FcCharSetFirstPage)();
        bind!(FcCharSetNextPage)();
        /*
 * old coverage , rather hard to use correctly
 */
        bind!(FcCharSetCoverage)();
        /* fcdbg.c */
        bind!(FcValuePrint)();
        bind!(FcPatternPrint)();
        bind!(FcFontSetPrint)();
        /* fcdefault.c */
        bind!(FcGetDefaultLangs)();
        bind!(FcDefaultSubstitute)();
        /* fcdir.c */
        bind!(FcFileIsDir)();
        bind!(FcFileScan)();
        bind!(FcDirScan)();
        bind!(FcDirSave)();
        bind!(FcDirCacheLoad)();
        bind!(FcDirCacheRescan)();
        bind!(FcDirCacheRead)();
        //     bind!(FcDirCacheLoadFile)();
        bind!(FcDirCacheUnload)();
        /* fcfreetype.c */
        bind!(FcFreeTypeQuery)();
        /* fcfs.c */
        bind!(FcFontSetCreate)();
        bind!(FcFontSetDestroy)();
        bind!(FcFontSetAdd)();
        /* fcinit.c */
        bind!(FcInitLoadConfig)();
        bind!(FcInitLoadConfigAndFonts)();
        bind!(FcInit)();
        bind!(FcFini)();
        bind!(FcGetVersion)();
        bind!(FcInitReinitialize)();
        bind!(FcInitBringUptoDate)();
        /* fclang.c */
        bind!(FcGetLangs)();
        bind!(FcLangNormalize)();
        bind!(FcLangGetCharSet)();
        bind!(FcLangSetCreate)();
        bind!(FcLangSetDestroy)();
        bind!(FcLangSetCopy)();
        bind!(FcLangSetAdd)();
        bind!(FcLangSetDel)();
        bind!(FcLangSetHasLang)();
        bind!(FcLangSetCompare)();
        bind!(FcLangSetContains)();
        bind!(FcLangSetEqual)();
        bind!(FcLangSetHash)();
        bind!(FcLangSetGetLangs)();
        bind!(FcLangSetUnion)();
        bind!(FcLangSetSubtract)();
        /* fclist.c */
        bind!(FcObjectSetCreate)();
        bind!(FcObjectSetAdd)();
        bind!(FcObjectSetDestroy)();
        //    bind!(FcObjectSetVaBuild)();
        //    bind!(FcObjectSetBuild)(); // FC_ATTRIBUTE_SENTINEL()
        bind!(FcFontSetList)();
        bind!(FcFontList)();
        /* fcatomic.c */
        bind!(FcAtomicCreate)();
        bind!(FcAtomicLock)();
        bind!(FcAtomicNewFile)();
        bind!(FcAtomicOrigFile)();
        bind!(FcAtomicReplaceOrig)();
        bind!(FcAtomicDeleteNew)();
        bind!(FcAtomicUnlock)();
        bind!(FcAtomicDestroy)();
        /* fcmatch.c */
        bind!(FcFontSetMatch)();
        bind!(FcFontMatch)();
        bind!(FcFontRenderPrepare)();
        bind!(FcFontSetSort)();
        bind!(FcFontSort)();
        bind!(FcFontSetSortDestroy)();
        /* fcmatrix.c */
        bind!(FcMatrixCopy)();
        bind!(FcMatrixEqual)();
        bind!(FcMatrixMultiply)();
        bind!(FcMatrixRotate)();
        bind!(FcMatrixScale)();
        bind!(FcMatrixShear)();
        /* fcname.c */
        bind!(FcNameGetConstant)();
        bind!(FcNameConstant)();
        bind!(FcNameParse)();
        bind!(FcNameUnparse)();
        /* fcpat.c */
        bind!(FcPatternCreate)();
        bind!(FcPatternDuplicate)();
        bind!(FcPatternReference)();
        bind!(FcPatternFilter)();
        bind!(FcValueDestroy)();
        bind!(FcValueEqual)();
        bind!(FcValueSave)();
        bind!(FcPatternDestroy)();
        bind!(FcPatternEqual)();
        bind!(FcPatternEqualSubset)();
        bind!(FcPatternHash)();
        bind!(FcPatternAdd)();
        bind!(FcPatternAddWeak)();
        bind!(FcPatternGet)();
        bind!(FcPatternDel)();
        bind!(FcPatternRemove)();
        bind!(FcPatternAddInteger)();
        bind!(FcPatternAddDouble)();
        bind!(FcPatternAddString)();
        bind!(FcPatternAddMatrix)();
        bind!(FcPatternAddCharSet)();
        bind!(FcPatternAddBool)();
        bind!(FcPatternAddLangSet)();
        bind!(FcPatternAddRange)();
        bind!(FcPatternGetInteger)();
        bind!(FcPatternGetDouble)();
        bind!(FcPatternGetString)();
        bind!(FcPatternGetMatrix)();
        bind!(FcPatternGetCharSet)();
        bind!(FcPatternGetBool)();
        bind!(FcPatternGetLangSet)();
        bind!(FcPatternGetRange)();
        //     bind!(FcPatternVaBuild)();
        //     bind!(FcPatternBuild)(); /*FC_ATTRIBUTE_SENTINEL()*/
        bind!(FcPatternFormat)();
        /* fcrange.c */
        bind!(FcRangeCreateDouble)();
        bind!(FcRangeCreateInteger)();
        bind!(FcRangeDestroy)();
        bind!(FcRangeCopy)();
        bind!(FcRangeGetDouble)();
        /* fcweight.c */
        bind!(FcWeightFromOpenType)();
        bind!(FcWeightToOpenType)();
        /* fcstr.c */
        bind!(FcStrCopy)();
        bind!(FcStrCopyFilename)();
        bind!(FcStrPlus)();
        bind!(FcStrFree)();
        bind!(FcStrDowncase)();
        bind!(FcStrCmpIgnoreCase)();
        bind!(FcStrCmp)();
        bind!(FcStrStrIgnoreCase)();
        bind!(FcStrStr)();
        bind!(FcUtf8ToUcs4)();
        bind!(FcUtf8Len)();
        bind!(FcUcs4ToUtf8)();
        bind!(FcUtf16ToUcs4)(); /* in bytes */
        bind!(FcUtf16Len)();
        bind!(FcStrDirname)();
        bind!(FcStrBasename)();
        bind!(FcStrSetCreate)();
        bind!(FcStrSetMember)();
        bind!(FcStrSetEqual)();
        bind!(FcStrSetAdd)();
        bind!(FcStrSetAddFilename)();
        bind!(FcStrSetDel)();
        bind!(FcStrSetDestroy)();
        bind!(FcStrListCreate)();
        bind!(FcStrListFirst)();
        bind!(FcStrListNext)();
        bind!(FcStrListDone)();
        /* fcxml.c */
        bind!(FcConfigParseAndLoad)();
    }
}
