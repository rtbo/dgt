module dgt.font.port.ft;

import derelict.freetype.ft;

import dgt.core.rc;
import dgt.font.typeface;

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


package(dgt.font):

FT_Library gFtLib;

void initializeFreetype() {
    DerelictFT.load();
    FT_New_Library(null, &gFtLib);
}

void finalizeFreetype() {
    FT_Done_FreeType(gFtLib);
    gFtLib = null;
}

private:

