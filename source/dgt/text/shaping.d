module dgt.text.shaping;

import dgt.font.typeface;
import gfx.core.rc;
import gfx.math.vec;

/// Per glyph info issued from the text shaper
struct GlyphInfo
{
    GlyphId index;
    FVec2 advance;
    FVec2 offset;
}

interface TextShapingContext : IAtomicRefCounted
{
    immutable(GlyphInfo)[] shapeText(in string text);
}
