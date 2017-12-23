module dgt.font.typeface;

import dgt.core.rc;
import dgt.math.vec : FVec2;
import dgt.font.style;

import std.uni;

alias GlyphId = ushort;

abstract class Typeface : RefCounted {
    mixin(rcCode);
    abstract void dispose();

    abstract @property string family();
    abstract @property FontStyle style();

    abstract @property CodepointSet coverage();
    abstract GlyphId[] glyphsForString(in string text);

    abstract void getOutline(in GlyphId glyphId, OutlineAccumulator oa);
}

interface OutlineAccumulator {
    void moveTo(in FVec2 to);
    void lineTo(in FVec2 to);
    void conicTo(in FVec2 control, in FVec2 to);
    void cubicTo(in FVec2 control1, in FVec2 control2, in FVec2 to);
}
