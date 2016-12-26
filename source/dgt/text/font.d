module dgt.text.font;

import dgt.text.fontcache;
import dgt.resource;
import dgt.util;

/// Font size (expressed in pts or px)
struct FontSize
{
    /// Unit of the size value
    enum Unit
    {
        pts,
        px
    }

    Unit unit;
    double value;

    /// Returns a FontSize with value expressed in pts
    static FontSize pts(double pts)
    {
        return FontSize(Unit.pts, pts);
    }
    /// Returns a FontSize with value expressed in px
    static FontSize px(double px)
    {
        return FontSize(Unit.px, px);
    }
}

/// Font style as defined by the CSS specification
enum FontStyle
{
    normal,
    italic,
    oblique,
}

/// Font weight as defined by the CSS specification.
/// An integer is typically expected for the weight. Either a value of this enum
/// or a number between 100 and 900 can be provided in place.
enum FontWeight : int
{
    normal = 400,
    bold = 700,
}

/// Font variant as defined by the CSS specification.
/// Unsupported at the moment.
enum FontVariant
{
    normal,
    smallCaps,
}

/// An actual font that hold font information and will lazily load glyph into memory
class Font : RefCounted
{
    mixin(rcCode);

    this(in FontResult res)
    {
        _filename = res.filename;
        _faceIndex = res.faceIndex;
        _family = res.family;
        _size = res.size;
        _weight = res.weight;
        _style = res.style;
        _foundry = res.foundry;
    }

    override void dispose()
    {
    }


    mixin ReadOnlyValueProperty!("filename", string);
    mixin ReadOnlyValueProperty!("faceIndex", int);
    mixin ReadOnlyValueProperty!("family", string);
    mixin ReadOnlyValueProperty!("size", FontSize);
    mixin ReadOnlyValueProperty!("weight", int);
    mixin ReadOnlyValueProperty!("style", FontStyle);
    mixin ReadOnlyValueProperty!("foundry", string);

}
