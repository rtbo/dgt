module dgt.bindings.fontconfig.symbols;

import dgt.bindings.fontconfig.definitions;


extern(C) nothrow @nogc
{
    /* fcblanks.c */
    alias da_FcBlanksCreate = FcBlanks * function ();

    alias da_FcBlanksDestroy = void function (FcBlanks *b);

    alias da_FcBlanksAdd = FcBool function (FcBlanks *b, FcChar32 ucs4);

    alias da_FcBlanksIsMember = FcBool function (FcBlanks *b, FcChar32 ucs4);

    /* fccache.c */

    alias da_FcCacheDir = const(FcChar8)* function (const(FcCache)* c);

    alias da_FcCacheCopySet = FcFontSet *function (const(FcCache)* c);

    alias da_FcCacheSubdir = const(FcChar8)* function (const(FcCache)* c, int i);

    alias da_FcCacheNumSubdir = int function (const(FcCache)* c);

    alias da_FcCacheNumFont = int function (const(FcCache)* c);

    alias da_FcDirCacheUnlink = FcBool function (const(FcChar8)* dir, FcConfig *config);

    alias da_FcDirCacheValid = FcBool function (const(FcChar8)* cache_file);

    alias da_FcDirCacheClean = FcBool function (const(FcChar8)* cache_dir, FcBool verbose);

    alias da_FcCacheCreateTagFile = void function (const(FcConfig)* config);

    /* fccfg.c */
    alias da_FcConfigHome = FcChar8 * function ();

    alias da_FcConfigEnableHome = FcBool function (FcBool enable);

    alias da_FcConfigFilename = FcChar8 * function (const(FcChar8)* url);

    alias da_FcConfigCreate = FcConfig * function ();

    alias da_FcConfigReference = FcConfig * function (FcConfig *config);

    alias da_FcConfigDestroy = void function (FcConfig *config);

    alias da_FcConfigSetCurrent = FcBool function (FcConfig *config);

    alias da_FcConfigGetCurrent = FcConfig * function ();

    alias da_FcConfigUptoDate = FcBool function (FcConfig *config);

    alias da_FcConfigBuildFonts = FcBool function (FcConfig *config);

    alias da_FcConfigGetFontDirs = FcStrList * function (FcConfig   *config);

    alias da_FcConfigGetConfigDirs = FcStrList * function (FcConfig   *config);

    alias da_FcConfigGetConfigFiles = FcStrList * function (FcConfig    *config);

    alias da_FcConfigGetCache = FcChar8 * function (FcConfig  *config);

    alias da_FcConfigGetBlanks = FcBlanks * function (FcConfig *config);

    alias da_FcConfigGetCacheDirs = FcStrList * function (const(FcConfig)* config);

    alias da_FcConfigGetRescanInterval = int function (FcConfig *config);

    alias da_FcConfigSetRescanInterval = FcBool function (FcConfig *config, int rescanInterval);

    alias da_FcConfigGetFonts = FcFontSet * function (FcConfig	*config,
              FcSetName	set);

    alias da_FcConfigAppFontAddFile = FcBool function (FcConfig    *config,
                const(FcChar8)* file);

    alias da_FcConfigAppFontAddDir = FcBool function (FcConfig	    *config,
                   const(FcChar8)* dir);

    alias da_FcConfigAppFontClear = void function (FcConfig	    *config);

    alias da_FcConfigSubstituteWithPat = FcBool function (FcConfig	*config,
                   FcPattern	*p,
                   FcPattern	*p_pat,
                   FcMatchKind	kind);

    alias da_FcConfigSubstitute = FcBool function (FcConfig	*config,
                FcPattern	*p,
                FcMatchKind	kind);

    alias da_FcConfigGetSysRoot = const(FcChar8)* function (const(FcConfig)* config);

    alias da_FcConfigSetSysRoot = void function (FcConfig      *config,
                const(FcChar8)* sysroot);

    /* fccharset.c */
    alias da_FcCharSetCreate = FcCharSet* function ();

    alias da_FcCharSetDestroy = void function (FcCharSet *fcs);

    alias da_FcCharSetAddChar = FcBool function (FcCharSet *fcs, FcChar32 ucs4);

    alias da_FcCharSetDelChar = FcBool function (FcCharSet *fcs, FcChar32 ucs4);

    alias da_FcCharSetCopy = FcCharSet* function (FcCharSet *src);

    alias da_FcCharSetEqual = FcBool function (const(FcCharSet)* a, const(FcCharSet)* b);

    alias da_FcCharSetIntersect = FcCharSet* function (const(FcCharSet)* a, const(FcCharSet)* b);

    alias da_FcCharSetUnion = FcCharSet* function (const(FcCharSet)* a, const(FcCharSet)* b);

    alias da_FcCharSetSubtract = FcCharSet* function (const(FcCharSet)* a, const(FcCharSet)* b);

    alias da_FcCharSetMerge = FcBool function (FcCharSet *a, const(FcCharSet)* b, FcBool *changed);

    alias da_FcCharSetHasChar = FcBool function (const(FcCharSet)* fcs, FcChar32 ucs4);

    alias da_FcCharSetCount = FcChar32 function (const(FcCharSet)* a);

    alias da_FcCharSetIntersectCount = FcChar32 function (const(FcCharSet)* a, const(FcCharSet)* b);

    alias da_FcCharSetSubtractCount = FcChar32 function (const(FcCharSet)* a, const(FcCharSet)* b);

    alias da_FcCharSetIsSubset = FcBool function (const(FcCharSet)* a, const(FcCharSet)* b);

    alias da_FcCharSetFirstPage = FcChar32 function (const(FcCharSet)* a,
                FcChar32[FC_CHARSET_MAP_SIZE]	    map,
                FcChar32	    *next);

    alias da_FcCharSetNextPage = FcChar32 function (const(FcCharSet)* a,
               FcChar32[FC_CHARSET_MAP_SIZE]	    map,
               FcChar32	    *next);

    /*
     * old coverage API, rather hard to use correctly
     */

    alias da_FcCharSetCoverage = FcChar32 function (const(FcCharSet)* a, FcChar32 page, FcChar32 *result);

    /* fcdbg.c */
    alias da_FcValuePrint = void function (const FcValue v);

    alias da_FcPatternPrint = void function (const(FcPattern)* p);

    alias da_FcFontSetPrint = void function (const(FcFontSet)* s);

    /* fcdefault.c */
    alias da_FcGetDefaultLangs = FcStrSet * function ();

    alias da_FcDefaultSubstitute = void function (FcPattern *pattern);

    /* fcdir.c */
    alias da_FcFileIsDir = FcBool function (const(FcChar8)* file);

    alias da_FcFileScan = FcBool function (FcFontSet	    *set,
            FcStrSet	    *dirs,
            FcFileCache	    *cache,
            FcBlanks	    *blanks,
            const(FcChar8)* file,
            FcBool	    force);

    alias da_FcDirScan = FcBool function (FcFontSet	    *set,
           FcStrSet	    *dirs,
           FcFileCache	    *cache,
           FcBlanks	    *blanks,
           const(FcChar8)* dir,
           FcBool	    force);

    alias da_FcDirSave = FcBool function (FcFontSet *set, FcStrSet *dirs, const(FcChar8)* dir);

    alias da_FcDirCacheLoad = FcCache * function (const(FcChar8)* dir, FcConfig *config, FcChar8 **cache_file);

    alias da_FcDirCacheRescan = FcCache * function (const(FcChar8)* dir, FcConfig *config);

    alias da_FcDirCacheRead = FcCache * function (const(FcChar8)* dir, FcBool force, FcConfig *config);

    //alias da_FcDirCacheLoadFile = FcCache * function (const(FcChar8)* cache_file, struct stat *file_stat);

    alias da_FcDirCacheUnload = void function (FcCache *cache);

    /* fcfreetype.c */
    alias da_FcFreeTypeQuery = FcPattern * function (const(FcChar8)* file, int id, FcBlanks *blanks, int *count);

    /* fcfs.c */

    alias da_FcFontSetCreate = FcFontSet * function ();

    alias da_FcFontSetDestroy = void function (FcFontSet *s);

    alias da_FcFontSetAdd = FcBool function (FcFontSet *s, FcPattern *font);

    /* fcinit.c */
    alias da_FcInitLoadConfig = FcConfig * function ();

    alias da_FcInitLoadConfigAndFonts = FcConfig * function ();

    alias da_FcInit = FcBool function ();

    alias da_FcFini = void function ();

    alias da_FcGetVersion = int function ();

    alias da_FcInitReinitialize = FcBool function ();

    alias da_FcInitBringUptoDate = FcBool function ();

    /* fclang.c */
    alias da_FcGetLangs = FcStrSet * function ();

    alias da_FcLangNormalize = FcChar8 * function (const(FcChar8)* lang);

    alias da_FcLangGetCharSet = const(FcCharSet)* function (const(FcChar8)* lang);

    alias da_FcLangSetCreate = FcLangSet* function ();

    alias da_FcLangSetDestroy = void function (FcLangSet *ls);

    alias da_FcLangSetCopy = FcLangSet* function (const(FcLangSet)* ls);

    alias da_FcLangSetAdd = FcBool function (FcLangSet *ls, const(FcChar8)* lang);

    alias da_FcLangSetDel = FcBool function (FcLangSet *ls, const(FcChar8)* lang);

    alias da_FcLangSetHasLang = FcLangResult function (const(FcLangSet)* ls, const(FcChar8)* lang);

    alias da_FcLangSetCompare = FcLangResult function (const(FcLangSet)* lsa, const(FcLangSet)* lsb);

    alias da_FcLangSetContains = FcBool function (const(FcLangSet)* lsa, const(FcLangSet)* lsb);

    alias da_FcLangSetEqual = FcBool function (const(FcLangSet)* lsa, const(FcLangSet)* lsb);

    alias da_FcLangSetHash = FcChar32 function (const(FcLangSet)* ls);

    alias da_FcLangSetGetLangs = FcStrSet * function (const(FcLangSet)* ls);

    alias da_FcLangSetUnion = FcLangSet * function (const(FcLangSet)* a, const(FcLangSet)* b);

    alias da_FcLangSetSubtract = FcLangSet * function (const(FcLangSet)* a, const(FcLangSet)* b);

    /* fclist.c */
    alias da_FcObjectSetCreate = FcObjectSet * function ();

    alias da_FcObjectSetAdd = FcBool function (FcObjectSet *os, const(char)* object);

    alias da_FcObjectSetDestroy = void function (FcObjectSet *os);

    // alias da_FcObjectSetVaBuild = FcObjectSet * function (const(char)* first, va_list va);

    // alias da_FcObjectSetBuild  = FcObjectSet * function (const(char)* first, ...) FC_ATTRIBUTE_SENTINEL(0);

    alias da_FcFontSetList = FcFontSet * function (FcConfig	    *config,
               FcFontSet    **sets,
               int	    nsets,
               FcPattern    *p,
               FcObjectSet  *os);

    alias da_FcFontList = FcFontSet * function (FcConfig	*config,
            FcPattern	*p,
            FcObjectSet *os);

    /* fcatomic.c */

    alias da_FcAtomicCreate = FcAtomic * function (const(FcChar8)* file);

    alias da_FcAtomicLock = FcBool function (FcAtomic *atomic);

    alias da_FcAtomicNewFile = FcChar8 * function (FcAtomic *atomic);

    alias da_FcAtomicOrigFile = FcChar8 * function (FcAtomic *atomic);

    alias da_FcAtomicReplaceOrig = FcBool function (FcAtomic *atomic);

    alias da_FcAtomicDeleteNew = void function (FcAtomic *atomic);

    alias da_FcAtomicUnlock = void function (FcAtomic *atomic);

    alias da_FcAtomicDestroy = void function (FcAtomic *atomic);

    /* fcmatch.c */
    alias da_FcFontSetMatch = FcPattern * function (FcConfig    *config,
            FcFontSet   **sets,
            int	    nsets,
            FcPattern   *p,
            FcResult    *result);

    alias da_FcFontMatch = FcPattern * function (FcConfig	*config,
             FcPattern	*p,
             FcResult	*result);

    alias da_FcFontRenderPrepare = FcPattern * function (FcConfig	    *config,
                 FcPattern	    *pat,
                 FcPattern	    *font);

    alias da_FcFontSetSort = FcFontSet * function (FcConfig	    *config,
               FcFontSet    **sets,
               int	    nsets,
               FcPattern    *p,
               FcBool	    trim,
               FcCharSet    **csp,
               FcResult	    *result);

    alias da_FcFontSort = FcFontSet * function (FcConfig	 *config,
            FcPattern    *p,
            FcBool	 trim,
            FcCharSet    **csp,
            FcResult	 *result);

    alias da_FcFontSetSortDestroy = void function (FcFontSet *fs);

    /* fcmatrix.c */
    alias da_FcMatrixCopy = FcMatrix * function (const(FcMatrix)* mat);

    alias da_FcMatrixEqual = FcBool function (const(FcMatrix)* mat1, const(FcMatrix)* mat2);

    alias da_FcMatrixMultiply = void function (FcMatrix *result, const(FcMatrix)* a, const(FcMatrix)* b);

    alias da_FcMatrixRotate = void function (FcMatrix *m, double c, double s);

    alias da_FcMatrixScale = void function (FcMatrix *m, double sx, double sy);

    alias da_FcMatrixShear = void function (FcMatrix *m, double sh, double sv);

    /* fcname.c */

    alias da_FcNameGetObjectType = const(FcObjectType)* function (const(char)* object);

    alias da_FcNameGetConstant = const(FcConstant)* function (const(FcChar8)* string);

    alias da_FcNameConstant = FcBool function (const(FcChar8)* string, int *result);

    alias da_FcNameParse = FcPattern * function (const(FcChar8)* name);

    alias da_FcNameUnparse = FcChar8 * function (FcPattern *pat);

    /* fcpat.c */
    alias da_FcPatternCreate = FcPattern * function ();

    alias da_FcPatternDuplicate = FcPattern * function (const(FcPattern)* p);

    alias da_FcPatternReference = void function (FcPattern *p);

    alias da_FcPatternFilter = FcPattern * function (FcPattern *p, const(FcObjectSet)* os);

    alias da_FcValueDestroy = void function (FcValue v);

    alias da_FcValueEqual = FcBool function (FcValue va, FcValue vb);

    alias da_FcValueSave = FcValue function (FcValue v);

    alias da_FcPatternDestroy = void function (FcPattern *p);

    alias da_FcPatternEqual = FcBool function (const(FcPattern)* pa, const(FcPattern)* pb);

    alias da_FcPatternEqualSubset = FcBool function (const(FcPattern)* pa, const(FcPattern)* pb, const(FcObjectSet)* os);

    alias da_FcPatternHash = FcChar32 function (const(FcPattern)* p);

    alias da_FcPatternAdd = FcBool function (FcPattern *p, const(char)* object, FcValue value, FcBool append);

    alias da_FcPatternAddWeak = FcBool function (FcPattern *p, const(char)* object, FcValue value, FcBool append);

    alias da_FcPatternGet = FcResult function (const(FcPattern)* p, const(char)* object, int id, FcValue *v);

    alias da_FcPatternDel = FcBool function (FcPattern *p, const(char)* object);

    alias da_FcPatternRemove = FcBool function (FcPattern *p, const(char)* object, int id);

    alias da_FcPatternAddInteger = FcBool function (FcPattern *p, const(char)* object, int i);

    alias da_FcPatternAddDouble = FcBool function (FcPattern *p, const(char)* object, double d);

    alias da_FcPatternAddString = FcBool function (FcPattern *p, const(char)* object, const(FcChar8)* s);

    alias da_FcPatternAddMatrix = FcBool function (FcPattern *p, const(char)* object, const(FcMatrix)* s);

    alias da_FcPatternAddCharSet = FcBool function (FcPattern *p, const(char)* object, const(FcCharSet)* c);

    alias da_FcPatternAddBool = FcBool function (FcPattern *p, const(char)* object, FcBool b);

    alias da_FcPatternAddLangSet = FcBool function (FcPattern *p, const(char)* object, const(FcLangSet)* ls);

    alias da_FcPatternAddRange = FcBool function (FcPattern *p, const(char)* object, const(FcRange)* r);

    alias da_FcPatternGetInteger = FcResult function (const(FcPattern)* p, const(char)* object, int n, int *i);

    alias da_FcPatternGetDouble = FcResult function (const(FcPattern)* p, const(char)* object, int n, double *d);

    alias da_FcPatternGetString = FcResult function (const(FcPattern)* p, const(char)* object, int n, FcChar8 ** s);

    alias da_FcPatternGetMatrix = FcResult function (const(FcPattern)* p, const(char)* object, int n, FcMatrix **s);

    alias da_FcPatternGetCharSet = FcResult function (const(FcPattern)* p, const(char)* object, int n, FcCharSet **c);

    alias da_FcPatternGetBool = FcResult function (const(FcPattern)* p, const(char)* object, int n, FcBool *b);

    alias da_FcPatternGetLangSet = FcResult function (const(FcPattern)* p, const(char)* object, int n, FcLangSet **ls);

    alias da_FcPatternGetRange = FcResult function (const(FcPattern)* p, const(char)* object, int id, FcRange **r);

    // alias da_FcPatternVaBuild = FcPattern * function (FcPattern *p, va_list va);

    // alias da_FcPatternBuild  = FcPattern * function (FcPattern *p, ...) FC_ATTRIBUTE_SENTINEL(0);

    alias da_FcPatternFormat = FcChar8 * function (FcPattern *pat, const(FcChar8)* format);

    /* fcrange.c */
    alias da_FcRangeCreateDouble = FcRange * function (double begin, double end);

    alias da_FcRangeCreateInteger = FcRange * function (FcChar32 begin, FcChar32 end);

    alias da_FcRangeDestroy = void function (FcRange *range);

    alias da_FcRangeCopy = FcRange * function (const(FcRange)* r);

    alias da_FcRangeGetDouble = FcBool function (const(FcRange)* range, double *begin, double *end);

    /* fcweight.c */

    alias da_FcWeightFromOpenType = int function (int ot_weight);

    alias da_FcWeightToOpenType = int function (int fc_weight);

    /* fcstr.c */

    alias da_FcStrCopy = FcChar8 * function (const(FcChar8)* s);

    alias da_FcStrCopyFilename = FcChar8 * function (const(FcChar8)* s);

    alias da_FcStrPlus = FcChar8 * function (const(FcChar8)* s1, const(FcChar8)* s2);

    alias da_FcStrFree = void function (FcChar8 *s);

    alias da_FcStrDowncase = FcChar8 * function (const(FcChar8)* s);

    alias da_FcStrCmpIgnoreCase = int function (const(FcChar8)* s1, const(FcChar8)* s2);

    alias da_FcStrCmp = int function (const(FcChar8)* s1, const(FcChar8)* s2);

    alias da_FcStrStrIgnoreCase = const(FcChar8)* function (const(FcChar8)* s1, const(FcChar8)* s2);

    alias da_FcStrStr = const(FcChar8)* function (const(FcChar8)* s1, const(FcChar8)* s2);

    alias da_FcUtf8ToUcs4 = int function (const(FcChar8)* src_orig,
              FcChar32	    *dst,
              int	    len);

    alias da_FcUtf8Len = FcBool function (const(FcChar8)* string,
           int		    len,
           int		    *nchar,
           int		    *_wchar);

    // alias da_FcChar8 = int (FcChar32	ucs4,[FC_UTF8_MAX_LEN]	destfunction)
    //         FcUcs4ToUtf8;

    alias da_FcUtf16ToUcs4 = int function (const(FcChar8)* src_orig,
               FcEndian		endian,
               FcChar32		*dst,
               int		len);	    /* in bytes */

    alias da_FcUtf16Len = FcBool function (const(FcChar8)* string,
            FcEndian	    endian,
            int		    len,	    /* in bytes */
            int		    *nchar,
            int		    *_wchar);

    alias da_FcStrDirname = FcChar8 * function (const(FcChar8)* file);

    alias da_FcStrBasename = FcChar8 * function (const(FcChar8)* file);

    alias da_FcStrSetCreate = FcStrSet * function ();

    alias da_FcStrSetMember = FcBool function (FcStrSet *set, const(FcChar8)* s);

    alias da_FcStrSetEqual = FcBool function (FcStrSet *sa, FcStrSet *sb);

    alias da_FcStrSetAdd = FcBool function (FcStrSet *set, const(FcChar8)* s);

    alias da_FcStrSetAddFilename = FcBool function (FcStrSet *set, const(FcChar8)* s);

    alias da_FcStrSetDel = FcBool function (FcStrSet *set, const(FcChar8)* s);

    alias da_FcStrSetDestroy = void function (FcStrSet *set);

    alias da_FcStrListCreate = FcStrList * function (FcStrSet *set);

    alias da_FcStrListFirst = void function (FcStrList *list);

    alias da_FcStrListNext = FcChar8 * function (FcStrList *list);

    alias da_FcStrListDone = void function (FcStrList *list);

    /* fcxml.c */
    alias da_FcConfigParseAndLoad = FcBool function (FcConfig *config, const(FcChar8)* file, FcBool complain);
}


__gshared
{
    /* fcblanks.c */
    da_FcBlanksCreate FcBlanksCreate;

    da_FcBlanksDestroy FcBlanksDestroy;

    da_FcBlanksAdd FcBlanksAdd;

    da_FcBlanksIsMember FcBlanksIsMember;

    /* fccache.c */

    da_FcCacheDir FcCacheDir;

    da_FcCacheCopySet FcCacheCopySet;

    da_FcCacheSubdir FcCacheSubdir;

    da_FcCacheNumSubdir FcCacheNumSubdir;

    da_FcCacheNumFont FcCacheNumFont;

    da_FcDirCacheUnlink FcDirCacheUnlink;

    da_FcDirCacheValid FcDirCacheValid;

    da_FcDirCacheClean FcDirCacheClean;

    da_FcCacheCreateTagFile FcCacheCreateTagFile;

    /* fccfg.c */
    da_FcConfigHome FcConfigHome;

    da_FcConfigEnableHome FcConfigEnableHome;

    da_FcConfigFilename FcConfigFilename;

    da_FcConfigCreate FcConfigCreate;

    da_FcConfigReference FcConfigReference;

    da_FcConfigDestroy FcConfigDestroy;

    da_FcConfigSetCurrent FcConfigSetCurrent;

    da_FcConfigGetCurrent FcConfigGetCurrent;

    da_FcConfigUptoDate FcConfigUptoDate;

    da_FcConfigBuildFonts FcConfigBuildFonts;

    da_FcConfigGetFontDirs FcConfigGetFontDirs;

    da_FcConfigGetConfigDirs FcConfigGetConfigDirs;

    da_FcConfigGetConfigFiles FcConfigGetConfigFiles;

    da_FcConfigGetCache FcConfigGetCache;

    da_FcConfigGetBlanks FcConfigGetBlanks;

    da_FcConfigGetCacheDirs FcConfigGetCacheDirs;

    da_FcConfigGetRescanInterval FcConfigGetRescanInterval;

    da_FcConfigSetRescanInterval FcConfigSetRescanInterval;

    da_FcConfigGetFonts FcConfigGetFonts;

    da_FcConfigAppFontAddFile FcConfigAppFontAddFile;

    da_FcConfigAppFontAddDir FcConfigAppFontAddDir;

    da_FcConfigAppFontClear FcConfigAppFontClear;

    da_FcConfigSubstituteWithPat FcConfigSubstituteWithPat;

    da_FcConfigSubstitute FcConfigSubstitute;

    da_FcConfigGetSysRoot FcConfigGetSysRoot;

    da_FcConfigSetSysRoot FcConfigSetSysRoot;

    /* fccharset.c */
    da_FcCharSetCreate FcCharSetCreate;

    da_FcCharSetDestroy FcCharSetDestroy;

    da_FcCharSetAddChar FcCharSetAddChar;

    da_FcCharSetDelChar FcCharSetDelChar;

    da_FcCharSetCopy FcCharSetCopy;

    da_FcCharSetEqual FcCharSetEqual;

    da_FcCharSetIntersect FcCharSetIntersect;

    da_FcCharSetUnion FcCharSetUnion;

    da_FcCharSetSubtract FcCharSetSubtract;

    da_FcCharSetMerge FcCharSetMerge;

    da_FcCharSetHasChar FcCharSetHasChar;

    da_FcCharSetCount FcCharSetCount;

    da_FcCharSetIntersectCount FcCharSetIntersectCount;

    da_FcCharSetSubtractCount FcCharSetSubtractCount;

    da_FcCharSetIsSubset FcCharSetIsSubset;

    da_FcCharSetFirstPage FcCharSetFirstPage;

    da_FcCharSetNextPage FcCharSetNextPage;

    /*
     * old coverage API, rather hard to use correctly
     */

    da_FcCharSetCoverage FcCharSetCoverage;

    /* fcdbg.c */
    da_FcValuePrint FcValuePrint;

    da_FcPatternPrint FcPatternPrint;

    da_FcFontSetPrint FcFontSetPrint;

    /* fcdefault.c */
    da_FcGetDefaultLangs FcGetDefaultLangs;

    da_FcDefaultSubstitute FcDefaultSubstitute;

    /* fcdir.c */
    da_FcFileIsDir FcFileIsDir;

    da_FcFileScan FcFileScan;

    da_FcDirScan FcDirScan;

    da_FcDirSave FcDirSave;

    da_FcDirCacheLoad FcDirCacheLoad;

    da_FcDirCacheRescan FcDirCacheRescan;

    da_FcDirCacheRead FcDirCacheRead;

    //da_FcDirCacheLoadFile FcDirCacheLoadFile;

    da_FcDirCacheUnload FcDirCacheUnload;

    /* fcfreetype.c */
    da_FcFreeTypeQuery FcFreeTypeQuery;

    /* fcfs.c */

    da_FcFontSetCreate FcFontSetCreate;

    da_FcFontSetDestroy FcFontSetDestroy;

    da_FcFontSetAdd FcFontSetAdd;

    /* fcinit.c */
    da_FcInitLoadConfig FcInitLoadConfig;

    da_FcInitLoadConfigAndFonts FcInitLoadConfigAndFonts;

    da_FcInit FcInit;

    da_FcFini FcFini;

    da_FcGetVersion FcGetVersion;

    da_FcInitReinitialize FcInitReinitialize;

    da_FcInitBringUptoDate FcInitBringUptoDate;

    /* fclang.c */
    da_FcGetLangs FcGetLangs;

    da_FcLangNormalize FcLangNormalize;

    da_FcLangGetCharSet FcLangGetCharSet;

    da_FcLangSetCreate FcLangSetCreate;

    da_FcLangSetDestroy FcLangSetDestroy;

    da_FcLangSetCopy FcLangSetCopy;

    da_FcLangSetAdd FcLangSetAdd;

    da_FcLangSetDel FcLangSetDel;

    da_FcLangSetHasLang FcLangSetHasLang;

    da_FcLangSetCompare FcLangSetCompare;

    da_FcLangSetContains FcLangSetContains;

    da_FcLangSetEqual FcLangSetEqual;

    da_FcLangSetHash FcLangSetHash;

    da_FcLangSetGetLangs FcLangSetGetLangs;

    da_FcLangSetUnion FcLangSetUnion;

    da_FcLangSetSubtract FcLangSetSubtract;

    /* fclist.c */
    da_FcObjectSetCreate FcObjectSetCreate;

    da_FcObjectSetAdd FcObjectSetAdd;

    da_FcObjectSetDestroy FcObjectSetDestroy;

    //da_FcObjectSetVaBuild FcObjectSetVaBuild;

    da_FcFontSetList FcFontSetList;

    da_FcFontList FcFontList;

    /* fcatomic.c */

    da_FcAtomicCreate FcAtomicCreate;

    da_FcAtomicLock FcAtomicLock;

    da_FcAtomicNewFile FcAtomicNewFile;

    da_FcAtomicOrigFile FcAtomicOrigFile;

    da_FcAtomicReplaceOrig FcAtomicReplaceOrig;

    da_FcAtomicDeleteNew FcAtomicDeleteNew;

    da_FcAtomicUnlock FcAtomicUnlock;

    da_FcAtomicDestroy FcAtomicDestroy;

    /* fcmatch.c */
    da_FcFontSetMatch FcFontSetMatch;

    da_FcFontMatch FcFontMatch;

    da_FcFontRenderPrepare FcFontRenderPrepare;

    da_FcFontSetSort FcFontSetSort;

    da_FcFontSort FcFontSort;

    da_FcFontSetSortDestroy FcFontSetSortDestroy;

    /* fcmatrix.c */
    da_FcMatrixCopy FcMatrixCopy;

    da_FcMatrixEqual FcMatrixEqual;

    da_FcMatrixMultiply FcMatrixMultiply;

    da_FcMatrixRotate FcMatrixRotate;

    da_FcMatrixScale FcMatrixScale;

    da_FcMatrixShear FcMatrixShear;

    /* fcname.c */

    da_FcNameGetObjectType FcNameGetObjectType;

    da_FcNameGetConstant FcNameGetConstant;

    da_FcNameConstant FcNameConstant;

    da_FcNameParse FcNameParse;

    da_FcNameUnparse FcNameUnparse;

    /* fcpat.c */
    da_FcPatternCreate FcPatternCreate;

    da_FcPatternDuplicate FcPatternDuplicate;

    da_FcPatternReference FcPatternReference;

    da_FcPatternFilter FcPatternFilter;

    da_FcValueDestroy FcValueDestroy;

    da_FcValueEqual FcValueEqual;

    da_FcValueSave FcValueSave;

    da_FcPatternDestroy FcPatternDestroy;

    da_FcPatternEqual FcPatternEqual;

    da_FcPatternEqualSubset FcPatternEqualSubset;

    da_FcPatternHash FcPatternHash;

    da_FcPatternAdd FcPatternAdd;

    da_FcPatternAddWeak FcPatternAddWeak;

    da_FcPatternGet FcPatternGet;

    da_FcPatternDel FcPatternDel;

    da_FcPatternRemove FcPatternRemove;

    da_FcPatternAddInteger FcPatternAddInteger;

    da_FcPatternAddDouble FcPatternAddDouble;

    da_FcPatternAddString FcPatternAddString;

    da_FcPatternAddMatrix FcPatternAddMatrix;

    da_FcPatternAddCharSet FcPatternAddCharSet;

    da_FcPatternAddBool FcPatternAddBool;

    da_FcPatternAddLangSet FcPatternAddLangSet;

    da_FcPatternAddRange FcPatternAddRange;

    da_FcPatternGetInteger FcPatternGetInteger;

    da_FcPatternGetDouble FcPatternGetDouble;

    da_FcPatternGetString FcPatternGetString;

    da_FcPatternGetMatrix FcPatternGetMatrix;

    da_FcPatternGetCharSet FcPatternGetCharSet;

    da_FcPatternGetBool FcPatternGetBool;

    da_FcPatternGetLangSet FcPatternGetLangSet;

    da_FcPatternGetRange FcPatternGetRange;

    // da_FcPatternVaBuild FcPatternVaBuild;

    da_FcPatternFormat FcPatternFormat;

    /* fcrange.c */
    da_FcRangeCreateDouble FcRangeCreateDouble;

    da_FcRangeCreateInteger FcRangeCreateInteger;

    da_FcRangeDestroy FcRangeDestroy;

    da_FcRangeCopy FcRangeCopy;

    da_FcRangeGetDouble FcRangeGetDouble;

    /* fcweight.c */

    da_FcWeightFromOpenType FcWeightFromOpenType;

    da_FcWeightToOpenType FcWeightToOpenType;

    /* fcstr.c */

    da_FcStrCopy FcStrCopy;

    da_FcStrCopyFilename FcStrCopyFilename;

    da_FcStrPlus FcStrPlus;

    da_FcStrFree FcStrFree;

    da_FcStrDowncase FcStrDowncase;

    da_FcStrCmpIgnoreCase FcStrCmpIgnoreCase;

    da_FcStrCmp FcStrCmp;

    da_FcStrStrIgnoreCase FcStrStrIgnoreCase;

    da_FcStrStr FcStrStr;

    da_FcUtf8ToUcs4 FcUtf8ToUcs4;

    da_FcUtf8Len FcUtf8Len;

    // da_FcUcs4ToUtf8 FcUcs4ToUtf8;

    da_FcUtf16ToUcs4 FcUtf16ToUcs4;	    /* in bytes */

    da_FcUtf16Len FcUtf16Len;

    da_FcStrDirname FcStrDirname;

    da_FcStrBasename FcStrBasename;

    da_FcStrSetCreate FcStrSetCreate;

    da_FcStrSetMember FcStrSetMember;

    da_FcStrSetEqual FcStrSetEqual;

    da_FcStrSetAdd FcStrSetAdd;

    da_FcStrSetAddFilename FcStrSetAddFilename;

    da_FcStrSetDel FcStrSetDel;

    da_FcStrSetDestroy FcStrSetDestroy;

    da_FcStrListCreate FcStrListCreate;

    da_FcStrListFirst FcStrListFirst;

    da_FcStrListNext FcStrListNext;

    da_FcStrListDone FcStrListDone;

    /* fcxml.c */
    da_FcConfigParseAndLoad FcConfigParseAndLoad;
}

