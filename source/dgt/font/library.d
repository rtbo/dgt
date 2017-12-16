module dgt.font.library;

import dgt.core.rc;
import dgt.font.style;
import dgt.font.typeface;


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

    Typeface matchFamilyStyle(in string family, in FontStyle style)
    {
        return matchFamily(family).matchStyle(style);
    }
}

/// a collection of font style for a given family
abstract class FamilyStyleSet : RefCounted {
    mixin(rcCode);

    abstract void dispose();

    abstract @property size_t styleCount();

    abstract FontStyle style(in size_t index);

    abstract Typeface createTypeface(in size_t index);

    abstract Typeface matchStyle(in FontStyle style);

protected:

    Typeface matchStyleCSS3(in FontStyle style) {
        import std.algorithm : map, maxIndex;
        import std.range : iota;

        const count = styleCount;
        if (!count) return null;

        const index = iota(count)
            .map!(i => this.style(i).css3MatchingScore(style))
            .maxIndex;
        return createTypeface(index);
    }
}


class TypefaceCache : Disposable {

    this() {}

    override void dispose() {
        release(_typefaces);
    }

    void add(Typeface tf) {
        _typefaces ~= tf.rc;
    }

    private Typeface[] _typefaces;
}

Typeface find (alias pred)(TypefaceCache tfCache) {
    foreach(tf; tfCache._typefaces) {
        if (pred(tf)) return tf;
    }
    return null;
}

