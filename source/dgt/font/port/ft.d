module dgt.font.port.ft;

import derelict.freetype.ft;

import dgt : Subsystem;
import dgt.core.rc;
import dgt.font.typeface;

import std.exception;
import std.experimental.logger;

// for other modules to import without having to deal with derelict
alias FT_Face = derelict.freetype.ft.FT_Face;

abstract class FtTypeface : Typeface
{
    this(FT_Face face) {
        _face = face;
    }

    override void dispose() {
        FT_Done_Face(_face);
    }

    private FT_Face _face;
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

