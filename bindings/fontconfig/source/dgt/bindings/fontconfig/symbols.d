module dgt.bindings.fontconfig.symbols;

import dgt.bindings.fontconfig.definitions;


extern(C) nothrow @nogc __gshared
{
    /* fcblanks.c */
    FcBlanks * function ()
            FcBlanksCreate;

    void function (FcBlanks *b)
            FcBlanksDestroy;

    FcBool function (FcBlanks *b, FcChar32 ucs4)
            FcBlanksAdd;

    FcBool function (FcBlanks *b, FcChar32 ucs4)
            FcBlanksIsMember;

    /* fccache.c */

    const(FcChar8)* function (const(FcCache)* c)
            FcCacheDir;

    FcFontSet *function (const(FcCache)* c)
            FcCacheCopySet;

    const(FcChar8)* function (const(FcCache)* c, int i)
            FcCacheSubdir;

    int function (const(FcCache)* c)
            FcCacheNumSubdir;

    int function (const(FcCache)* c)
            FcCacheNumFont;

    FcBool function (const(FcChar8)* dir, FcConfig *config)
            FcDirCacheUnlink;

    FcBool function (const(FcChar8)* cache_file)
            FcDirCacheValid;

    FcBool function (const(FcChar8)* cache_dir, FcBool verbose)
            FcDirCacheClean;

    void function (const(FcConfig)* config)
            FcCacheCreateTagFile;

    /* fccfg.c */
    FcChar8 * function ()
            FcConfigHome;

    FcBool function (FcBool enable)
            FcConfigEnableHome;

    FcChar8 * function (const(FcChar8)* url)
            FcConfigFilename;

    FcConfig * function ()
            FcConfigCreate;

    FcConfig * function (FcConfig *config)
            FcConfigReference;

    void function (FcConfig *config)
            FcConfigDestroy;

    FcBool function (FcConfig *config)
            FcConfigSetCurrent;

    FcConfig * function ()
            FcConfigGetCurrent;

    FcBool function (FcConfig *config)
            FcConfigUptoDate;

    FcBool function (FcConfig *config)
            FcConfigBuildFonts;

    FcStrList * function (FcConfig   *config)
            FcConfigGetFontDirs;

    FcStrList * function (FcConfig   *config)
            FcConfigGetConfigDirs;

    FcStrList * function (FcConfig    *config)
            FcConfigGetConfigFiles;

    FcChar8 * function (FcConfig  *config)
            FcConfigGetCache;

    FcBlanks * function (FcConfig *config)
            FcConfigGetBlanks;

    FcStrList * function (const(FcConfig)* config)
            FcConfigGetCacheDirs;

    int function (FcConfig *config)
            FcConfigGetRescanInterval;

    FcBool function (FcConfig *config, int rescanInterval)
            FcConfigSetRescanInterval;

    FcFontSet * function (FcConfig	*config,
              FcSetName	set)
            FcConfigGetFonts;

    FcBool function (FcConfig    *config,
                const(FcChar8)* file)
            FcConfigAppFontAddFile;

    FcBool function (FcConfig	    *config,
                   const(FcChar8)* dir)
            FcConfigAppFontAddDir;

    void function (FcConfig	    *config)
            FcConfigAppFontClear;

    FcBool function (FcConfig	*config,
                   FcPattern	*p,
                   FcPattern	*p_pat,
                   FcMatchKind	kind)
            FcConfigSubstituteWithPat;

    FcBool function (FcConfig	*config,
                FcPattern	*p,
                FcMatchKind	kind)
            FcConfigSubstitute;

    const(FcChar8)* function (const(FcConfig)* config)
            FcConfigGetSysRoot;

    void function (FcConfig      *config,
                const(FcChar8)* sysroot)
            FcConfigSetSysRoot;

    /* fccharset.c */
    FcCharSet* function ()
            FcCharSetCreate;

    void function (FcCharSet *fcs)
            FcCharSetDestroy;

    FcBool function (FcCharSet *fcs, FcChar32 ucs4)
            FcCharSetAddChar;

    FcBool function (FcCharSet *fcs, FcChar32 ucs4)
            FcCharSetDelChar;

    FcCharSet* function (FcCharSet *src)
            FcCharSetCopy;

    FcBool function (const(FcCharSet)* a, const(FcCharSet)* b)
            FcCharSetEqual;

    FcCharSet* function (const(FcCharSet)* a, const(FcCharSet)* b)
            FcCharSetIntersect;

    FcCharSet* function (const(FcCharSet)* a, const(FcCharSet)* b)
            FcCharSetUnion;

    FcCharSet* function (const(FcCharSet)* a, const(FcCharSet)* b)
            FcCharSetSubtract;

    FcBool function (FcCharSet *a, const(FcCharSet)* b, FcBool *changed)
            FcCharSetMerge;

    FcBool function (const(FcCharSet)* fcs, FcChar32 ucs4)
            FcCharSetHasChar;

    FcChar32 function (const(FcCharSet)* a)
            FcCharSetCount;

    FcChar32 function (const(FcCharSet)* a, const(FcCharSet)* b)
            FcCharSetIntersectCount;

    FcChar32 function (const(FcCharSet)* a, const(FcCharSet)* b)
            FcCharSetSubtractCount;

    FcBool function (const(FcCharSet)* a, const(FcCharSet)* b)
            FcCharSetIsSubset;

    FcChar32 function (const(FcCharSet)* a,
                FcChar32[FC_CHARSET_MAP_SIZE]	    map,
                FcChar32	    *next)
            FcCharSetFirstPage;

    FcChar32 function (const(FcCharSet)* a,
               FcChar32[FC_CHARSET_MAP_SIZE]	    map,
               FcChar32	    *next)
            FcCharSetNextPage;

    /*
     * old coverage API, rather hard to use correctly
     */

    FcChar32 function (const(FcCharSet)* a, FcChar32 page, FcChar32 *result)
            FcCharSetCoverage;

    /* fcdbg.c */
    void function (const FcValue v)
            FcValuePrint;

    void function (const(FcPattern)* p)
            FcPatternPrint;

    void function (const(FcFontSet)* s)
            FcFontSetPrint;

    /* fcdefault.c */
    FcStrSet * function ()
            FcGetDefaultLangs;

    void function (FcPattern *pattern)
            FcDefaultSubstitute;

    /* fcdir.c */
    FcBool function (const(FcChar8)* file)
            FcFileIsDir;

    FcBool function (FcFontSet	    *set,
            FcStrSet	    *dirs,
            FcFileCache	    *cache,
            FcBlanks	    *blanks,
            const(FcChar8)* file,
            FcBool	    force)
            FcFileScan;

    FcBool function (FcFontSet	    *set,
           FcStrSet	    *dirs,
           FcFileCache	    *cache,
           FcBlanks	    *blanks,
           const(FcChar8)* dir,
           FcBool	    force)
            FcDirScan;

    FcBool function (FcFontSet *set, FcStrSet *dirs, const(FcChar8)* dir)
            FcDirSave;

    FcCache * function (const(FcChar8)* dir, FcConfig *config, FcChar8 **cache_file)
            FcDirCacheLoad;

    FcCache * function (const(FcChar8)* dir, FcConfig *config)
            FcDirCacheRescan;

    FcCache * function (const(FcChar8)* dir, FcBool force, FcConfig *config)
            FcDirCacheRead;

    //FcCache * function (const(FcChar8)* cache_file, struct stat *file_stat)
    //        FcDirCacheLoadFile;

    void function (FcCache *cache)
            FcDirCacheUnload;

    /* fcfreetype.c */
    FcPattern * function (const(FcChar8)* file, int id, FcBlanks *blanks, int *count)
            FcFreeTypeQuery;

    /* fcfs.c */

    FcFontSet * function ()
            FcFontSetCreate;

    void function (FcFontSet *s)
            FcFontSetDestroy;

    FcBool function (FcFontSet *s, FcPattern *font)
            FcFontSetAdd;

    /* fcinit.c */
    FcConfig * function ()
            FcInitLoadConfig;

    FcConfig * function ()
            FcInitLoadConfigAndFonts;

    FcBool function ()
            FcInit;

    void function ()
            FcFini;

    int function ()
            FcGetVersion;

    FcBool function ()
            FcInitReinitialize;

    FcBool function ()
            FcInitBringUptoDate;

    /* fclang.c */
    FcStrSet * function ()
            FcGetLangs;

    FcChar8 * function (const(FcChar8)* lang)
            FcLangNormalize;

    const(FcCharSet)* function (const(FcChar8)* lang)
            FcLangGetCharSet;

    FcLangSet* function ()
            FcLangSetCreate;

    void function (FcLangSet *ls)
            FcLangSetDestroy;

    FcLangSet* function (const(FcLangSet)* ls)
            FcLangSetCopy;

    FcBool function (FcLangSet *ls, const(FcChar8)* lang)
            FcLangSetAdd;

    FcBool function (FcLangSet *ls, const(FcChar8)* lang)
            FcLangSetDel;

    FcLangResult function (const(FcLangSet)* ls, const(FcChar8)* lang)
            FcLangSetHasLang;

    FcLangResult function (const(FcLangSet)* lsa, const(FcLangSet)* lsb)
            FcLangSetCompare;

    FcBool function (const(FcLangSet)* lsa, const(FcLangSet)* lsb)
            FcLangSetContains;

    FcBool function (const(FcLangSet)* lsa, const(FcLangSet)* lsb)
            FcLangSetEqual;

    FcChar32 function (const(FcLangSet)* ls)
            FcLangSetHash;

    FcStrSet * function (const(FcLangSet)* ls)
            FcLangSetGetLangs;

    FcLangSet * function (const(FcLangSet)* a, const(FcLangSet)* b)
            FcLangSetUnion;

    FcLangSet * function (const(FcLangSet)* a, const(FcLangSet)* b)
            FcLangSetSubtract;

    /* fclist.c */
    FcObjectSet * function ()
            FcObjectSetCreate;

    FcBool function (FcObjectSet *os, const(char)* object)
            FcObjectSetAdd;

    void function (FcObjectSet *os)
            FcObjectSetDestroy;

    // FcObjectSet * function (const(char)* first, va_list va)
    //         FcObjectSetVaBuild;

    // FcObjectSet * function (const(char)* first, ...)
    //         FcObjectSetBuild FC_ATTRIBUTE_SENTINEL(0);

    FcFontSet * function (FcConfig	    *config,
               FcFontSet    **sets,
               int	    nsets,
               FcPattern    *p,
               FcObjectSet  *os)
            FcFontSetList;

    FcFontSet * function (FcConfig	*config,
            FcPattern	*p,
            FcObjectSet *os)
            FcFontList;

    /* fcatomic.c */

    FcAtomic * function (const(FcChar8)* file)
            FcAtomicCreate;

    FcBool function (FcAtomic *atomic)
            FcAtomicLock;

    FcChar8 * function (FcAtomic *atomic)
            FcAtomicNewFile;

    FcChar8 * function (FcAtomic *atomic)
            FcAtomicOrigFile;

    FcBool function (FcAtomic *atomic)
            FcAtomicReplaceOrig;

    void function (FcAtomic *atomic)
            FcAtomicDeleteNew;

    void function (FcAtomic *atomic)
            FcAtomicUnlock;

    void function (FcAtomic *atomic)
            FcAtomicDestroy;

    /* fcmatch.c */
    FcPattern * function (FcConfig    *config,
            FcFontSet   **sets,
            int	    nsets,
            FcPattern   *p,
            FcResult    *result)
            FcFontSetMatch;

    FcPattern * function (FcConfig	*config,
             FcPattern	*p,
             FcResult	*result)
            FcFontMatch;

    FcPattern * function (FcConfig	    *config,
                 FcPattern	    *pat,
                 FcPattern	    *font)
            FcFontRenderPrepare;

    FcFontSet * function (FcConfig	    *config,
               FcFontSet    **sets,
               int	    nsets,
               FcPattern    *p,
               FcBool	    trim,
               FcCharSet    **csp,
               FcResult	    *result)
            FcFontSetSort;

    FcFontSet * function (FcConfig	 *config,
            FcPattern    *p,
            FcBool	 trim,
            FcCharSet    **csp,
            FcResult	 *result)
            FcFontSort;

    void function (FcFontSet *fs)
            FcFontSetSortDestroy;

    /* fcmatrix.c */
    FcMatrix * function (const(FcMatrix)* mat)
            FcMatrixCopy;

    FcBool function (const(FcMatrix)* mat1, const(FcMatrix)* mat2)
            FcMatrixEqual;

    void function (FcMatrix *result, const(FcMatrix)* a, const(FcMatrix)* b)
            FcMatrixMultiply;

    void function (FcMatrix *m, double c, double s)
            FcMatrixRotate;

    void function (FcMatrix *m, double sx, double sy)
            FcMatrixScale;

    void function (FcMatrix *m, double sh, double sv)
            FcMatrixShear;

    /* fcname.c */

    const(FcObjectType)* function (const(char)* object)
            FcNameGetObjectType;

    const(FcConstant)* function (const(FcChar8)* string)
            FcNameGetConstant;

    FcBool function (const(FcChar8)* string, int *result)
            FcNameConstant;

    FcPattern * function (const(FcChar8)* name)
            FcNameParse;

    FcChar8 * function (FcPattern *pat)
            FcNameUnparse;

    /* fcpat.c */
    FcPattern * function ()
            FcPatternCreate;

    FcPattern * function (const(FcPattern)* p)
            FcPatternDuplicate;

    void function (FcPattern *p)
            FcPatternReference;

    FcPattern * function (FcPattern *p, const(FcObjectSet)* os)
            FcPatternFilter;

    void function (FcValue v)
            FcValueDestroy;

    FcBool function (FcValue va, FcValue vb)
            FcValueEqual;

    FcValue function (FcValue v)
            FcValueSave;

    void function (FcPattern *p)
            FcPatternDestroy;

    FcBool function (const(FcPattern)* pa, const(FcPattern)* pb)
            FcPatternEqual;

    FcBool function (const(FcPattern)* pa, const(FcPattern)* pb, const(FcObjectSet)* os)
            FcPatternEqualSubset;

    FcChar32 function (const(FcPattern)* p)
            FcPatternHash;

    FcBool function (FcPattern *p, const(char)* object, FcValue value, FcBool append)
            FcPatternAdd;

    FcBool function (FcPattern *p, const(char)* object, FcValue value, FcBool append)
            FcPatternAddWeak;

    FcResult function (const(FcPattern)* p, const(char)* object, int id, FcValue *v)
            FcPatternGet;

    FcBool function (FcPattern *p, const(char)* object)
            FcPatternDel;

    FcBool function (FcPattern *p, const(char)* object, int id)
            FcPatternRemove;

    FcBool function (FcPattern *p, const(char)* object, int i)
            FcPatternAddInteger;

    FcBool function (FcPattern *p, const(char)* object, double d)
            FcPatternAddDouble;

    FcBool function (FcPattern *p, const(char)* object, const(FcChar8)* s)
            FcPatternAddString;

    FcBool function (FcPattern *p, const(char)* object, const(FcMatrix)* s)
            FcPatternAddMatrix;

    FcBool function (FcPattern *p, const(char)* object, const(FcCharSet)* c)
            FcPatternAddCharSet;

    FcBool function (FcPattern *p, const(char)* object, FcBool b)
            FcPatternAddBool;

    FcBool function (FcPattern *p, const(char)* object, const(FcLangSet)* ls)
            FcPatternAddLangSet;

    FcBool function (FcPattern *p, const(char)* object, const(FcRange)* r)
            FcPatternAddRange;

    FcResult function (const(FcPattern)* p, const(char)* object, int n, int *i)
            FcPatternGetInteger;

    FcResult function (const(FcPattern)* p, const(char)* object, int n, double *d)
            FcPatternGetDouble;

    FcResult function (const(FcPattern)* p, const(char)* object, int n, FcChar8 ** s)
            FcPatternGetString;

    FcResult function (const(FcPattern)* p, const(char)* object, int n, FcMatrix **s)
            FcPatternGetMatrix;

    FcResult function (const(FcPattern)* p, const(char)* object, int n, FcCharSet **c)
            FcPatternGetCharSet;

    FcResult function (const(FcPattern)* p, const(char)* object, int n, FcBool *b)
            FcPatternGetBool;

    FcResult function (const(FcPattern)* p, const(char)* object, int n, FcLangSet **ls)
            FcPatternGetLangSet;

    FcResult function (const(FcPattern)* p, const(char)* object, int id, FcRange **r)
            FcPatternGetRange;

    //FcPattern * function (FcPattern *p, va_list va)
    //        FcPatternVaBuild;

    // FcPattern * function (FcPattern *p, ...)
    //         FcPatternBuild FC_ATTRIBUTE_SENTINEL(0);

    FcChar8 * function (FcPattern *pat, const(FcChar8)* format)
            FcPatternFormat;

    /* fcrange.c */
    FcRange * function (double begin, double end)
            FcRangeCreateDouble;

    FcRange * function (FcChar32 begin, FcChar32 end)
            FcRangeCreateInteger;

    void function (FcRange *range)
            FcRangeDestroy;

    FcRange * function (const(FcRange)* r)
            FcRangeCopy;

    FcBool function (const(FcRange)* range, double *begin, double *end)
            FcRangeGetDouble;

    /* fcweight.c */

    int function (int ot_weight)
            FcWeightFromOpenType;

    int function (int fc_weight)
            FcWeightToOpenType;

    /* fcstr.c */

    FcChar8 * function (const(FcChar8)* s)
            FcStrCopy;

    FcChar8 * function (const(FcChar8)* s)
            FcStrCopyFilename;

    FcChar8 * function (const(FcChar8)* s1, const(FcChar8)* s2)
            FcStrPlus;

    void function (FcChar8 *s)
            FcStrFree;

    FcChar8 * function (const(FcChar8)* s)
            FcStrDowncase;

    int function (const(FcChar8)* s1, const(FcChar8)* s2)
            FcStrCmpIgnoreCase;

    int function (const(FcChar8)* s1, const(FcChar8)* s2)
            FcStrCmp;

    const(FcChar8)* function (const(FcChar8)* s1, const(FcChar8)* s2)
            FcStrStrIgnoreCase;

    const(FcChar8)* function (const(FcChar8)* s1, const(FcChar8)* s2)
            FcStrStr;

    int function (const(FcChar8)* src_orig,
              FcChar32	    *dst,
              int	    len)
            FcUtf8ToUcs4;

    FcBool function (const(FcChar8)* string,
           int		    len,
           int		    *nchar,
           int		    *_wchar)
            FcUtf8Len;

    // int (FcChar32	ucs4,
    //           FcChar8[FC_UTF8_MAX_LEN]	destfunction)
    //         FcUcs4ToUtf8;

    int function (const(FcChar8)* src_orig,
               FcEndian		endian,
               FcChar32		*dst,
               int		len)
            FcUtf16ToUcs4;	    /* in bytes */

    FcBool function (const(FcChar8)* string,
            FcEndian	    endian,
            int		    len,	    /* in bytes */
            int		    *nchar,
            int		    *_wchar)
            FcUtf16Len;

    FcChar8 * function (const(FcChar8)* file)
            FcStrDirname;

    FcChar8 * function (const(FcChar8)* file)
            FcStrBasename;

    FcStrSet * function ()
            FcStrSetCreate;

    FcBool function (FcStrSet *set, const(FcChar8)* s)
            FcStrSetMember;

    FcBool function (FcStrSet *sa, FcStrSet *sb)
            FcStrSetEqual;

    FcBool function (FcStrSet *set, const(FcChar8)* s)
            FcStrSetAdd;

    FcBool function (FcStrSet *set, const(FcChar8)* s)
            FcStrSetAddFilename;

    FcBool function (FcStrSet *set, const(FcChar8)* s)
            FcStrSetDel;

    void function (FcStrSet *set)
            FcStrSetDestroy;

    FcStrList * function (FcStrSet *set)
            FcStrListCreate;

    void function (FcStrList *list)
            FcStrListFirst;

    FcChar8 * function (FcStrList *list)
            FcStrListNext;

    void function (FcStrList *list)
            FcStrListDone;

    /* fcxml.c */
    FcBool function (FcConfig *config, const(FcChar8)* file, FcBool complain)
            FcConfigParseAndLoad;
}

