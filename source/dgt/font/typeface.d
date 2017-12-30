module dgt.font.typeface;

import dgt.core.image;
import dgt.core.rc;
import dgt.font.style;
import dgt.math.vec : FVec2, IVec2;
import dgt.text.shaping;

import std.uni;

alias GlyphId = ushort;

abstract class Typeface : AtomicRefCounted {
    mixin(atomicRcCode);

    this() {
        _id = nextFontId();
    }

    abstract override void dispose();

    final @property size_t id() {
        return _id;
    }

    abstract @property string family();
    abstract @property FontStyle style();

    abstract @property CodepointSet coverage();
    abstract GlyphId[] glyphsForString(in string text);

    abstract ScalingContext makeScalingContext(in float pixelSize);

    private size_t _id;

    private static size_t nextFontId() {
        import core.atomic : atomicOp;
        static shared size_t fontId = 0;
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

    @property Image img() {
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

    import std.typecons : Nullable;

    private GlyphId _glyphId;
    package(dgt.font) Image _img;
    package(dgt.font) FVec2 _bearing;
    package(dgt.font) Nullable!GlyphMetrics _metrics;
    package(dgt.font) bool _isWhitespace;
    // TODO: store outline here

    package(dgt) Object rendererData;
}

interface ScalingContext : AtomicRefCounted {

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

    TextShapingContext makeTextShapingContext();
}

interface OutlineAccumulator {
    void moveTo(in FVec2 to);
    void lineTo(in FVec2 to);
    void conicTo(in FVec2 control, in FVec2 to);
    void cubicTo(in FVec2 control1, in FVec2 control2, in FVec2 to);
}
