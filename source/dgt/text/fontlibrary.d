module dgt.text.fontlibrary;

import dgt.text.fontstyle;
import dgt.text.typeface;
import gfx.foundation.rc;

/// a collection of font style for a given family
abstract class FamilyStyleSet : RefCounted {
    abstract @property size_t length();
    abstract FontStyle style(size_t index);
    abstract Typeface createTypeface(size_t index);

    Typeface matchStyle(FontStyle style) {
        return null;
    }
}

/// system font library
class FontLibrary : Disposable {
    abstract @property size_t length();
    abstract string family(size_t index);
    abstract FamilyStyleSet matchFamily(string family);
}
