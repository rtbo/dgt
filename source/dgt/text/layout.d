module dgt.text.layout;

import dgt.core.paint;
import dgt.core.rc;
import dgt.core.sync;
import dgt.font.style;
import dgt.font.typeface;
import dgt.math.vec : fvec, FVec2;
import dgt.text.shaping : GlyphInfo;

import std.exception : enforce;

struct TextItem
{
    string text;
    string[] families;
    FontStyle style;
    float size;
    Paint fill;
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

alias ShapeId = uint;

struct TextShape {
    ShapeId id;
    FontId fontId;
    float size;
    immutable(GlyphInfo)[] glyphs;

    static ShapeId nextId() {
        import core.atomic : atomicOp;
        static shared ShapeId cur=0;
        return atomicOp!"+="(cur, 1);
    }
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
    void addItem(TextItem item) {
        _items ~= item;
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
            import dgt.font.library : FontLibrary;
            import std.format : format;
            auto tf = FontLibrary.get.css3FontMatch(item.families, item.style, item.text);
            enforce(tf, format("could not match any font for [%s, %s, %s]", item.families, item.style, item.text));
            tf.synchronize!((Typeface tf) {
                auto sc = tf.getScalingContext(item.size).rc;
                auto shaper = sc.getTextShapingContext().rc;
                _shapes ~= TextShape(TextShape.nextId(), tf.id, item.size, shaper.shapeText(item.text));
            });
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
            import dgt.font.library : FontLibrary;
            auto tf = FontLibrary.get.getById(ts.fontId);
            assert(tf);
            tf.synchronize!((Typeface tf) {
                auto sc = tf.getScalingContext(ts.size).rc;
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
            });
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
