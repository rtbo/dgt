module dgt.font.library;

import dgt.font.style;
import dgt.font.typeface;
import gfx.foundation.rc;


/// system font library
class FontLibrary : RefCounted {
    mixin (rcCode);

    static Rc!FontLibrary create() {
        Rc!FontLibrary fl;
        version(linux) {
            import dgt.font.port.fc : FcFontLibrary;
            fl = new FcFontLibrary;
        }
        else version(Windows) {
            import dgt.font.port.gdi : GdiFontLibrary;
            fl = new GdiFontLibrary;
        }
        else {
            static assert(false, "unsupported platform");
        }
        return fl;
    }

    abstract void dispose();
    abstract @property size_t familyCount();
    abstract string family(in size_t index);
    abstract FamilyStyleSet matchFamily(in string family);
    // abstract FontSet matchFamilyStyle(in string family, in FontStyle style);
}

/// a set of font that match a request
interface FontSet : RefCounted {
    @property size_t fontCount();
    @property Typeface createFace(in size_t index);
}

/// a collection of font style for a given family
abstract class FamilyStyleSet : RefCounted {
    mixin(rcCode);

    abstract void dispose();

    abstract @property size_t length();
    abstract FontStyle style(in size_t index);
    abstract Typeface createTypeface(in size_t index);

    Typeface matchStyle(in FontStyle style) {
        return null;
    }
}
