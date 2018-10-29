module dgt.font.library;

import dgt.core.rc;
import dgt.font.style;
import dgt.font.typeface;


/// system font library
class FontLibrary : AtomicRefCounted {

    mixin(atomicRcCode);

    static FontLibrary get() {
        return _instance;
    }

    override abstract void dispose();

    abstract shared(Typeface) getById(in FontId fontId);

    abstract shared(Typeface) css3FontMatch(in string[] families, in FontStyle style, in string text);

    /// Search and get the family installed on the system
    abstract @property size_t familyCount();
    /// ditto
    abstract string family(in size_t index);
    /// ditto
    FamilyStyleSet createStyleSet(in size_t index) {
        return matchFamily(family(index));
    }

    /// Returns a style set matching the given family.
    /// If the family is not generic (see https://developer.mozilla.org/en-US/docs/Web/CSS/font-family),
    /// and the font is not found, returns null.
    abstract FamilyStyleSet matchFamily(in string family);

    /// Returns a typeface matching family and style
    shared(Typeface) matchFamilyStyle(in string family, in FontStyle style)
    {
        auto fss = matchFamily(family).rc;
        return fss.matchStyle(style);
    }

    abstract Typeface createFromMemory(const(ubyte)[] data, int faceIndex=0);
    abstract Typeface createFromFile(in string path, int faceIndex=0);
}

/// a collection of font style for a given family
abstract class FamilyStyleSet : AtomicRefCounted {
    mixin(atomicRcCode);

    abstract void dispose();

    abstract @property size_t styleCount();

    abstract FontStyle style(in size_t index);

    abstract shared(Typeface) createTypeface(in size_t index);

    abstract shared(Typeface) matchStyle(in FontStyle style);

protected:

    shared(Typeface) matchStyleCSS3(in FontStyle style) {
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
        releaseArr(_typefaces);
    }

    void add(Typeface tf) {
        tf.retain();
        _typefaces ~= tf;
    }

    private Typeface[] _typefaces;
}

Typeface find (alias pred)(TypefaceCache tfCache) {
    foreach(tf; tfCache._typefaces) {
        if (pred(tf)) return tf;
    }
    return null;
}


private:

import dgt : registerSubsystem, Subsystem;

__gshared FontLibrary _instance;

class FLSubsystem : Subsystem
{
    override @property string name() const
    {
        return "Font Library";
    }
    override @property bool running() const {
        return _instance !is null;
    }
    override @property int priority() const {
        return int.max - 10;
    }
    override void initialize() {
        version(linux) {
            import dgt.font.port.fc : FcFontLibrary;
            _instance = new FcFontLibrary;
        }
        else version(Windows) {
            import dgt.font.port.gdi : GdiFontLibrary;
            _instance = new GdiFontLibrary;
        }
        else {
            static assert(false, "unsupported platform");
        }
        _instance.retain();
    }
    override void finalize() {
        _instance.release();
        _instance = null;
    }
}

shared static this() {
    registerSubsystem(new FLSubsystem);
}
