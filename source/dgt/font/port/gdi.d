module dgt.font.port.gdi;

version(Windows):

import core.sys.windows.windows;
import core.sys.windows.wingdi;

import dgt.core.rc;
import dgt.font.library;
import dgt.font.port.ft;
import dgt.font.style;
import dgt.font.typeface;

import std.exception;
import std.experimental.logger;
import std.string;
import std.stdio;

class GdiFontLibrary : FontLibrary
{
    private ENUMLOGFONTEX[] fonts;
    private TypefaceCache tfCache;
    private string sansFam;
    private string serifFam;
    private string monoFam;
    private string cursiveFam;
    private string fantasyFam;
    private string systemFam;

    this() {
        tfCache = new TypefaceCache;
        auto dc = CreateCompatibleDC(null);
        scope(exit) DeleteDC(dc);
        LOGFONT lf;
        lf.lfCharSet = DEFAULT_CHARSET;
        lf.lfFaceName[] = 0;
        EnumFontFamiliesEx(dc, &lf, &enumFontLibProc, cast(LPARAM)(cast(void*)this), 0);
        initGenericFamilies();
    }

    override void dispose() {
        tfCache.dispose();
    }

    override shared(Typeface) getById(in FontId fontId) {
        synchronized(this) {
            auto tf = tfCache.find!((Typeface tf) {
                return tf.id == fontId;
            });
            return cast(shared(Typeface))tf;
        }
    }

    override shared(Typeface) css3FontMatch(in string[] families, in FontStyle style, in string text) {
        const fam = families.length ? families[0] : null;
        // TODO: handle unicode coverage
        return matchFamilyStyle(fam, style);
    }

    override @property size_t familyCount() {
        return fonts.length;
    }
    override string family(in size_t index) {
        import std.conv : to;
        return fonts[index].elfLogFont.lfFaceName.ptr.to!string;
    }
    override FamilyStyleSet matchFamily(in string family) {
        return new GdiFamilyStyleSet(checkGenFamily(family));
    }

    override Typeface createFromMemory(const(ubyte)[] data, int faceIndex)
    {
        import dgt.font.port.ft : FtTypeface, openFaceFromMemory;

        auto ftF = openFaceFromMemory(data, faceIndex);
        return new FtTypeface(ftF, data);
    }

    override Typeface createFromFile(in string path, int faceIndex)
    {
        import dgt.font.port.ft : FtTypeface, openFaceFromFile;
        import std.conv : to;

        auto ftF = openFaceFromFile(path, faceIndex);
        return new FtTypeface(ftF);
    }

    private string checkGenFamily(in string familyName) {
        import std.uni : toLower;
        switch(familyName.toLower) {
            case "sans-serif": return sansFam;
            case "serif": return serifFam;
            case "monospace": return monoFam;
            case "cursive": return cursiveFam;
            case "fantasy": return fantasyFam;
            case "system-ui": return systemFam;
            default: return familyName;
        }
    }

    private shared(Typeface) createTypefaceLogFont(const(ENUMLOGFONTEX)* lf) {
        synchronized(this) {
            auto tf = tfCache.find!((Typeface tf) {
                auto gdiTf = cast(GdiTypeface)tf;
                if (!gdiTf) return false;
                return gdiTf.gdiFullName == lf.elfFullName;
            });
            if (tf) return cast(shared(Typeface))tf;
        }

        auto dc = CreateCompatibleDC(null);
        scope(exit) DeleteDC(dc);

        auto font = enforce(CreateFontIndirect(&lf.elfLogFont),
                "DGT: Could not create GDI font");

        auto previous = SelectObject(dc, font);
        scope(exit) SelectObject(dc, previous);

        const len = GetFontData(dc, 0, 0, null, 0);
        enforce(len != GDI_ERROR, "Could not get font data");

        auto buf = new ubyte[len];
        GetFontData(dc, 0, 0, cast(LPVOID)buf.ptr, len);

        auto ftFace = openFaceFromMemory(buf, 0);

        auto tf = new GdiTypeface(font, ftFace, buf, lf);
        synchronized(this) {
            tfCache.add(tf);
        }
        return cast(shared)tf;
    }

    private void initGenericFamilies() {

        void doFam(ref string font, immutable(string[]) fonts, ref int score, string fam) {
            import std.algorithm : find, min;
            import std.uni : sicmp;
            if (score == 0) return;
            auto f = fonts.find!(f => sicmp(fam, f) == 0);
            if (!f.empty) {
                const s = cast(int)fonts.length - cast(int)f.length;
                if (s < score) {
                    score = s;
                    font = fam;
                }
            }
        }
        int sansScore = int.max;
        int serifScore = int.max;
        int monoScore = int.max;
        int cursScore = int.max;
        int fantaScore = int.max;
        int systemScore = int.max;

        foreach (const i; 0 .. familyCount) {
            string f = family(i);
            doFam(sansFam, sansFonts, sansScore, f);
            doFam(serifFam, serifFonts, serifScore, f);
            doFam(monoFam, monoFonts, monoScore, f);
            doFam(cursiveFam, cursiveFonts, cursScore, f);
            doFam(fantasyFam, fantasyFonts, fantaScore, f);
            doFam(systemFam, systemUiFonts, systemScore, f);
        }
    }
}

private:

bool isValidEnumLogfont(const(LOGFONT)*lf) {
    if (!lf) return false;
    if (!lf.lfFaceName[0]) return false;
    if (lf.lfFaceName[0] == '@') return false;
    return lf.lfCharSet == ANSI_CHARSET;
}

extern(Windows)
int enumFontLibProc(const(LOGFONT)* lf, const(TEXTMETRIC)* lpntme,
                    DWORD FontType, LPARAM lParam)
{
    if (isValidEnumLogfont(lf)) {
        auto fl = cast(GdiFontLibrary)(cast(void*)lParam);
        fl.fonts ~= *(cast(const(ENUMLOGFONTEX)*)lf);
    }
    return 1;
}

extern(Windows)
int enumStyleSetProc(const(LOGFONT)* lf, const(TEXTMETRIC)* lpntme,
                    DWORD FontType, LPARAM lParam)
{
    if (isValidEnumLogfont(lf)) {
        auto fl = cast(GdiFamilyStyleSet)(cast(void*)lParam);
        fl.fonts ~= *(cast(const(ENUMLOGFONTEX)*)lf);
    }
    return 1;
}

void fillLogFontName(LOGFONT* lf, string familyName) {
    import std.conv : to;
    wstring fn = familyName.to!wstring;
    if (fn.length >= LF_FACESIZE) {
        fn = fn[0 .. LF_FACESIZE-1];
    }
    lf.lfFaceName[0 .. fn.length] = fn;
    lf.lfFaceName[fn.length] = 0;
}

FontStyle logFontToStyle(const(LOGFONT)* lf) {
    return FontStyle(
        cast(FontWeight)lf.lfWeight,
        lf.lfItalic ? FontSlant.italic : FontSlant.normal,
        FontWidth.normal
    );
}


private class GdiTypeface : FtTypeface
{
    this(HFONT hf, FT_Face ftFace, const(ubyte)[] faceData, const(ENUMLOGFONTEX)* lf) {
        super(ftFace, faceData);
        this.hf = hf;
        import std.conv : to;
        gdiFullName[] = lf.elfFullName[];
    }

    override void dispose() {
        super.dispose();
        DeleteObject(hf);
    }

    HFONT hf;
    WCHAR[LF_FULLFACESIZE] gdiFullName;
}

class GdiFamilyStyleSet : FamilyStyleSet {

    private string familyName;
    private ENUMLOGFONTEX[] fonts;

    this(string familyName) {
        this.familyName = familyName;
        auto dc = CreateCompatibleDC(null);
        scope(exit) DeleteDC(dc);
        LOGFONT lf;
        lf.lfCharSet = DEFAULT_CHARSET;
        fillLogFontName(&lf, familyName);
        EnumFontFamiliesEx(dc, &lf, &enumStyleSetProc, cast(LPARAM)(cast(void*)this), 0);
    }

    override void dispose() {
    }

    override @property size_t styleCount() {
        return fonts.length;
    }

    override FontStyle style(in size_t index) {
        return logFontToStyle(&fonts[index].elfLogFont);
    }

    override shared(Typeface) createTypeface(in size_t index) {
        return (cast(GdiFontLibrary)FontLibrary.get).createTypefaceLogFont(&fonts[index]);
    }

    override shared(Typeface) matchStyle(in FontStyle style) {
        return matchStyleCSS3(style);
    }
}

immutable sansFonts = [
    "sans-serif", "segoe", "tahoma", "verdana", "arial", "ms sans serif"
];
immutable serifFonts = [
    "serif", "georgia", "times new roman", "times",
    "dejavu serif", "droid serif"       // these two ones for wine support
];
immutable monoFonts = [
    "monospace", "courier", "consolas", "lucida console", "courier new"
];
immutable cursiveFonts = [
    "cursive", "segoe script", "lucida handwriting", "brush script mt", "z003"
];
immutable fantasyFonts = [
    "fantasy", "comic sans ms", "papyrus"
];
immutable systemUiFonts = [
    "system-ui", "segoe ui", "tahoma", "system"
];