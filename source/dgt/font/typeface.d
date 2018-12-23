module dgt.font.typeface;

import dgt.gfx.image;
import dgt.font.style;
import dgt.text.shaping;

import gfx.core.rc;
import gfx.math.vec : FVec2, IVec2;

import std.uni;

alias FontId = ushort;
alias GlyphId = ushort;

/// A font typeface.
/// Typefaces are not scaled to any particular size. To actually have some scaling
/// and rendering done, a ScalingContext must be obtained.
/// Typefaces are obtained from the FontLibrary instance as shared objects.
/// They must be locked (synchronized) during use.
abstract class Typeface : AtomicRefCounted
{
    this() {
        _id = nextFontId();
    }

    final @property FontId id() const {
        return _id;
    }

    final @property FontId id() shared {
        return _id;
    }

    abstract @property string family();
    abstract @property FontStyle style();

    abstract @property CodepointSet coverage();

    /// Get a scaling context from the cache, or create it if not available
    abstract ScalingContext getScalingContext(in float pixelSize);

    private immutable FontId _id;

    private static FontId nextFontId() {
        import core.atomic : atomicOp;
        static shared FontId fontId = 0;
        immutable fid = atomicOp!"+="(fontId, 1);
        return fid;
    }
}

/// Glyph metrics (all in px).
struct GlyphMetrics
{
    /// The size of the glyph
    FVec2 size;
    /// Bearing for horizontal layout
    FVec2 horBearing;
    /// Advance for horizontal layout
    float horAdvance;
    /// Bearing for vertical layout
    FVec2 verBearing;
    /// Advance for vertical layout
    float verAdvance;
}

final class Glyph {

    this (GlyphId glyphId) {
        _glyphId = glyphId;
    }

    @property GlyphId glyphId() {
        return _glyphId;
    }

    @property immutable(Image) img() {
        return _img;
    }

    @property FVec2 bearing() {
        return _bearing;
    }

    @property GlyphMetrics metrics() {
        // scalers are responsible to ensure metrics is set before
        // exposing any glyph out
        return _metrics;
    }

    @property bool isWhitespace() {
        return _isWhitespace;
    }

    import std.typecons : Nullable, Rebindable;

    private GlyphId _glyphId;
    package(dgt.font) Rebindable!(immutable(Image)) _img;
    package(dgt.font) FVec2 _bearing;
    package(dgt.font) Nullable!GlyphMetrics _metrics;
    package(dgt.font) bool _isWhitespace;
    // TODO: store outline here

    package(dgt) Object rendererData;
}

/// A scaling context is the facility that will scale and render glyphs to a
/// requested size. They generally share some data with the parent typeface
/// and therefore should be used while the typeface is locked.
interface ScalingContext : IAtomicRefCounted
{
    @property float pixelSize();

    void getOutline(in GlyphId glyphId, OutlineAccumulator oa);

    /// Render the glyph corresponding of the glyphId and returns it in a Glyph object.
    /// Returns
    ///  - null if the glyph is not found.
    ///  - a valid Glyph with null img member if the glyph is found but is a whitespace.
    ///    Glyph.isWhitespace returns true in such case.
    ///  - a valid Glyph rasterized in the img member otherwise.
    Glyph renderGlyph(in GlyphId glyphId);

    /// Compute the metrics of a glyph
    GlyphMetrics glyphMetrics(in GlyphId glyph);

    TextShapingContext getTextShapingContext();
}

interface OutlineAccumulator {
    void moveTo(in FVec2 to);
    void lineTo(in FVec2 to);
    void conicTo(in FVec2 control, in FVec2 to);
    void cubicTo(in FVec2 control1, in FVec2 control2, in FVec2 to);
}
