module dgt.font.typeface;

import dgt.core.image;
import dgt.core.rc;
import dgt.font.style;
import dgt.math.vec : FVec2, IVec2;
import dgt.text.shaping;

import std.uni;

alias GlyphId = ushort;

abstract class Typeface : RefCounted {
    mixin(rcCode);

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

    abstract ScalingContext makeScalingContext(in int pixelSize);

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


interface ScalingContext : RefCounted {
    @property Typeface typeface();
    @property int pixelSize();

    void getOutline(in GlyphId glyphId, OutlineAccumulator oa);

    /// Render the glyph into the given output with bottom left starting at offset.
    /// The bearing (relative to offset, not to bottom left of image) is returned as an output parameter.
    void renderGlyph(in GlyphId glyphId, Image output, in IVec2 offset, out IVec2 bearing)
    in {
        // FIXME assert with actual metrics
        assert(output.width >= pixelSize+offset.x);
        assert(output.height >= pixelSize+offset.y);
        assert(output.format == ImageFormat.a8);
    }

    /// Render the glyph in a new allocated image.
    /// The bearing relative to bottom left of image is returned as an output parameter.
    Image renderGlyph(in GlyphId glyphId, out IVec2 bearing)
    out(img) {
        assert(img.format == ImageFormat.a8);
    }

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
