module dgt.font.port.fc;

version(linux):

import dgt.bindings.fontconfig;
import dgt.bindings.fontconfig.load : loadFontconfigSymbols;

import dgt.font.library;

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

    override void dispose() {
        FcConfigDestroy(config);
        FcFini();
    }

    override @property size_t length() {
        return families.length;
    }
    override string family(size_t index) {
        return families[index];
    }
    override FamilyStyleSet matchFamily(string family) {
        return null;
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

