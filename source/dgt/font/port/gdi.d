module dgt.font.port.gdi;

version(Windows):

import core.sys.windows.windows;
import core.sys.windows.wingdi;

import dgt.font.library;
import dgt.font.style;
import dgt.font.typeface;

import std.string;

import std.stdio;

class GdiFontLibrary : FontLibrary
{
    private ENUMLOGFONTEX[] fonts;

    this() {
        auto dc = CreateCompatibleDC(null);
        scope(exit) DeleteDC(dc);
        LOGFONT lf;
        lf.lfCharSet = DEFAULT_CHARSET;
        lf.lfFaceName[] = 0;
        EnumFontFamiliesEx(dc, &lf, &enumFontLibProc, cast(LPARAM)(cast(void*)this), 0);
    }

    override void dispose() {
    }

    override @property size_t familyCount() {
        return fonts.length;
    }
    override string family(in size_t index) {
        import std.conv : to;
        return fonts[index].elfLogFont.lfFaceName.ptr.to!string;
    }
    override FamilyStyleSet matchFamily(in string family) {
        return new GdiFamilyStyleSet(family);
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

    override Typeface createTypeface(in size_t index) {
        return null;
    }

    override Typeface matchStyle(in FontStyle style) {
        return null;
    }
}
