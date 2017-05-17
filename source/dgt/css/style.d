/// CSS Style
module dgt.css.style;

import dgt.css.color;
import dgt.sg.node;

class Style
{
    this(SgNode node)
    {
        _node = node;
    }

    @property SgNode node()
    {
        return _node;
    }
    @property Style parent()
    {
        auto p = _node.parent;
        return p ? p.style : null;
    }
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
    /// Standards: https://www.w3.org/TR/css-fonts-3/#propdef-font-weight
    @property int fontWeight()
    {
        return _fontWeight;
    }
    /// ditto
    @property void fontWeight(int val)
    {
        _fontWeight = val;
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

    SgNode _node;
    Color _backgroundColor;
    string[] _fontFamily;
    int _fontWeight;
    int _fontSize;
    Color _textColor;
}
