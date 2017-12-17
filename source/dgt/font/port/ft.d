module dgt.font.port.ft;

import derelict.freetype.ft;

import dgt : Subsystem;
import dgt.core.rc;
import dgt.font.style;
import dgt.font.typeface;

import std.exception;
import std.experimental.logger;
import std.typecons : Nullable;
import std.uni : CodepointSet;

// for other modules to import without having to deal with derelict
alias FT_Face = derelict.freetype.ft.FT_Face;

class FtTypeface : Typeface
{
    this(FT_Face face) {
        _face = face;
    }

    override void dispose() {
        FT_Done_Face(_face);
    }

    override @property string family() {
        import std.string : fromStringz;
        return fromStringz(_face.family_name).idup;
    }

    override @property FontStyle style() {
        const flags = _face.style_flags;
        const slant = flags & FT_STYLE_FLAG_ITALIC ? FontSlant.italic : FontSlant.normal;
        const weight = flags & FT_STYLE_FLAG_BOLD ? FontWeight.bold : FontWeight.normal;
        return FontStyle(weight, slant, FontWidth.normal);
    }

    final override @property CodepointSet coverage() {
        if (_coverage.isNull) {
            _coverage = ftFaceToCoverage(_face);
        }
        return _coverage;
    }

    override GlyphId[] glyphsForString(in string text) {
        return [];
    }

    protected CodepointSet buildCoverage() {
        return ftFaceToCoverage(_face);
    }

    private FT_Face _face;
    protected Nullable!CodepointSet _coverage;
}

FT_Face openFaceFromMemory(const(ubyte)[] data, int faceIndex) {
    FT_Open_Args args;
    args.flags = FT_OPEN_MEMORY;
    args.memory_base = data.ptr;
    args.memory_size = data.length;
    FT_Face face;
    enforce(FT_Open_Face(gFtLib, &args, faceIndex, &face) == 0,
            "Freetype cannot open font from memorty");
    return face;
}

FT_Face openFaceFromFile(in string filename, int faceIndex) {
    import std.string : toStringz;
    char[] fn = filename.dup ~ '\0';
    FT_Open_Args args;
    args.flags = FT_OPEN_PATHNAME;
    args.pathname = fn.ptr;
    FT_Face face;
    enforce(FT_Open_Face(gFtLib, &args, faceIndex, &face) == 0,
            "Freetype cannot open font from file: "~filename
    );
    return face;
}

CodepointSet ftFaceToCoverage(FT_Face face) {
    import std.uni : isControl;
    CodepointSet coverage;
    FT_UInt glyph;
    dchar c = cast(dchar)FT_Get_First_Char(face, &glyph);
    while (glyph != 0) {
        bool skip = false;
        if (isControl(c)) {
            const FT_Int loadFlags =   FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH |
                                        FT_LOAD_NO_SCALE |
                                        FT_LOAD_NO_HINTING;
            if (FT_Load_Glyph(face, glyph, loadFlags) ||
                (face.glyph.format == FT_GLYPH_FORMAT_OUTLINE &&
                face.glyph.outline.n_contours == 0)) {
                skip = true;
            }
        }

        if (!skip) {
            coverage.add(c, c+1);
        }

        c = cast(dchar)FT_Get_Next_Char(face, c, &glyph);
    }
    return coverage;
}

private:

shared static this() {
    import dgt : registerSubsystem;
    registerSubsystem(new FtSubsystem);
}

__gshared FT_Library gFtLib = null;

class FtSubsystem : Subsystem {
    override @property bool running() const {
        return gFtLib !is null;
    }
    override void initialize() {
        DerelictFT.load();
        enforce(FT_Init_FreeType(&gFtLib) == 0);
    }
    override void finalize() {
        FT_Done_FreeType(gFtLib);
        gFtLib = null;
    }
}
