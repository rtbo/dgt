module dgt.text.shaping;

import dgt.core.rc;
import dgt.font.typeface;
import dgt.math.vec;

/// Per glyph info issued from the text shaper
struct GlyphInfo
{
    GlyphId index;
    FVec2 advance;
    FVec2 offset;
}

interface TextShapingContext : RefCounted {
    immutable(GlyphInfo)[] shapeText(in string text);
}
