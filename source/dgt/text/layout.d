module dgt.text.layout;

import dgt.core.paint;
import dgt.core.rc;
import dgt.font.style;
import dgt.font.typeface;
import dgt.math.vec : fvec, FVec2;
import dgt.text.shaping : GlyphInfo;

struct TextStyle
{
    this (float size, string family, FontStyle style, Paint fill) {
        import std.typecons : rebindable;
        this.size = size;
        this.family = family;
        this.style = style;
        this.fill = rebindable(fill);
    }
    float size;
    string family;
    FontStyle style;
    RPaint fill;
}

struct TextItem
{
    string text;
    TextStyle style;
}

/// Metrics of text drawn to screen
struct TextMetrics
{
    /// Offset of the text bounding box to the pen start position.
    /// Bounding box origin is top-left
    /// Positive in x means that pen start position is right of the bounding box origin.
    /// Positive in y means that pen start position is lower than the bounding box origin.
    FVec2 bearing;
    /// Size of the text bounding box
    FVec2 size;
    /// Advance equals (pen end position - pen start position)
    /// Pen end position can be the start position of another text concatenated
    /// to the one those metrics refer to.
    FVec2 advance;

    invariant()
    {
        assert(advance.x == 0 || advance.y == 0);
    }

    /// True if this refers to an horizontal text metrics
    @property bool horizontal() const
    {
        return advance.y == 0;
    }

    /// True if this refers to a vertical text metrics
    @property bool vertical() const
    {
        return advance.x == 0;
    }
}

struct TextShape {
    TextStyle style;
    immutable(GlyphInfo)[] glyphs;
}

class TextLayout
{
    /// clear the item list
    void clearItems()
    out {
        assert(_items.length == 0);
    }
    body {
        _items = null;
    }

    /// Checks whether the layout contains items
    @property bool empty() const {
        return _items.length == 0;
    }

    /// Add an item to the item list
    void addItem(in TextItem item) {
        _items ~= item;
        _layoutDirty = true;
    }

    /// reset the item at index ind to the provided item
    void resetItem(in TextItem item, size_t ind)
    in {
        assert(ind <= _items.length);
    }
    body {
        _items[ind] = item;
        _layoutDirty = true;
    }

    @property const(TextItem)[] items() const {
        return _items;
    }

    /// Layout the different items into text shapes
    void layout() {
        if (!_layoutDirty) return;
        _layoutDirty = false;
        _shapes = [];
        foreach (const ref item; _items) {
            auto stf = getTypeface(item.style).rc;
            synchronized(stf.obj) {
                auto tf = cast(Typeface)stf.obj;
                auto sc = tf.makeScalingContext(item.style.size).rc;
                auto shaper = sc.makeTextShapingContext().rc;
                _shapes ~= TextShape(item.style, shaper.shapeText(item.text));
            }
        }
    }

    @property immutable(TextShape)[] shapes() const {
        return _shapes;
    }

    @property TextMetrics metrics() {
        import std.algorithm : min, max;
        import std.math : round;

        layout();

        // FIXME: vertical
        float bearingX;
        float width;
        float top = 0;
        float bottom =0;
        auto advance = fvec(0, 0);

        foreach (TextShape ts; _shapes)
        {
            auto stf = getTypeface(ts.style).rc;
            synchronized(stf.obj) {
                auto tf = cast(Typeface)stf.obj;
                auto sc = tf.makeScalingContext(ts.style.size).rc;
                foreach (i, GlyphInfo gi; ts.glyphs)
                {
                    const gm = sc.glyphMetrics(gi.index);
                    if (i == 0)
                    {
                        bearingX = -gm.horBearing.x;
                        width = -gm.horBearing.x;
                    }
                    if (i == ts.glyphs.length-1)
                    {
                        // width = total advance wo last char       +
                        //         horizontal bearing of last char  +
                        //         width of last char               -
                        //         horizontal bearing of first char
                        width += (advance.x + gm.horBearing.x + gm.size.x);
                    }
                    top = max(top, gm.horBearing.y);
                    bottom = min(bottom, gm.horBearing.y - gm.size.y);
                    advance += gi.advance;
                }
            }
        }
        return TextMetrics(
            fvec(bearingX, top),
            fvec(width, top-bottom),
            advance
        );
    }

    private TextItem[] _items;
    private immutable(TextShape)[] _shapes;
    private bool _layoutDirty;
}

private shared(Typeface) getTypeface(in TextStyle style) {
    import dgt.font.library : FontLibrary;
    return FontLibrary.get.matchFamilyStyle(style.family, style.style);
}
