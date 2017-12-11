module dgt.text.port.fc;

import dgt.bindings.fontconfig;
import dgt.bindings.fontconfig.load : loadFontconfigSymbols;

import dgt.text.fontlibrary;

import std.string;

shared static this() {
    loadFontconfigSymbols();
}

class FcFontLibrary : FontLibrary
{
    private FcConfig *config;
    private string[] families;

    this() {
        config = FcInitLoadConfigAndFonts();
        families = getFamilies(config);
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

