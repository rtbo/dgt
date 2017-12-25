module dgt.text.layout;

import dgt.core.paint;
import dgt.font.style;
import dgt.math.vec : FVec2;

struct TextStyle
{
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


class TextLayout
{
    void clear() {
        _items = [];
    }

    void addItem(in TextItem item) {
        _items ~= item;
    }

    void layout() {

    }

    private TextItem[] _items;
}
