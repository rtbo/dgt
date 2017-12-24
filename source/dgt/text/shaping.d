module dgt.text.shaping;

import dgt.core.rc;
import dgt.font.typeface;
import dgt.math.vec;

/// Per glyph info issued from the text shaper
struct GlyphInfo
{
    GlyphId index;
    FVec2 advance;
    IVec2 offset;
}

alias TextShape = immutable(GlyphInfo)[];

interface TextShapingContext : RefCounted {
    @property ScalingContext scalingContext();
    TextShape shapeText(in string text);
}
