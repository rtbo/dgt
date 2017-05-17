/// CSS Style
module dgt.css.style;

import dgt.css.color;
import dgt.sg.node;


/// Font style as defined by the CSS specification
enum FontStyle
{
    normal,
    italic,
    oblique,
}

/// The style class groups all properties affecting visual appearance of nodes.
/// It is populated during the CSS pass.
class Style
{
    this(SgNode node)
    {
        _node = node;
    }

    /// The node associated with this style.
    @property SgNode node()
    {
        return _node;
    }
    /// The style of the parent `node`.
    @property Style parent()
    {
        auto p = _node.parent;
        return p ? p.style : null;
    }
    /// The style of the root of `node`.
    @property Style root()
    {
        return _node.root.style;
    }

    @property Color backgroundColor()
    {
        return _backgroundColor;
    }
    @property void backgroundColor(in Color color)
    {
        _backgroundColor = color;
    }

    @property string[] fontFamily()
    {
        return _fontFamily;
    }
    @property void fontFamily(string[] family)
    {
        _fontFamily = family;
    }

    /// Font weight as described by the CSS specification
    /// This is the integer from 100 to 900.
    /// Standards: $(LINK https://www.w3.org/TR/css-fonts-3/#propdef-font-weight)
    @property int fontWeight()
    {
        return _fontWeight;
    }
    /// ditto
    @property void fontWeight(in int val)
    {
        _fontWeight = val;
    }

    @property FontStyle fontStyle()
    {
        return _fontStyle;
    }
    @property void fontStyle(in FontStyle val)
    {
        _fontStyle = val;
    }

    /// Size of the EM box in pixels
    @property int fontSize()
    {
        return _fontSize;
    }
    /// ditto
    @property void fontSize(int l)
    {
        _fontSize = l;
    }

    @property Color textColor()
    {
        return _textColor;
    }

private:
    SgNode _node;
    Color _backgroundColor;
    string[] _fontFamily;
    int _fontWeight;
    FontStyle _fontStyle;
    int _fontSize;
    Color _textColor;
}
