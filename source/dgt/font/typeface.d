module dgt.font.typeface;

import dgt.core.rc;
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
}
