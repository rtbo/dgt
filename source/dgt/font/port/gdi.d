module dgt.font.port.gdi;

version(Windows):

import core.sys.windows.windows;
import core.sys.windows.wingdi;

import dgt.font.library;

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
        EnumFontFamiliesEx(dc, &lf, &initFontLibProc, cast(LPARAM)(cast(void*)this), 0);
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
        return null;
    }
}

private:

extern(Windows)
int initFontLibProc(const(LOGFONT)* lf, const(TEXTMETRIC)* lpntme,
                    DWORD FontType, LPARAM lParam)
{
    if (!lf || lf.lfFaceName[0]=='@') {
        return 1;
    }
    if (lf.lfCharSet != ANSI_CHARSET) {
        return 1;
    }
    auto fl = cast(GdiFontLibrary)(cast(void*)lParam);
    fl.fonts ~= *(cast(const(ENUMLOGFONTEX)*)lf);
    return 1;
}
