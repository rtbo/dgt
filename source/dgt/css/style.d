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

    /// Size in pixels
    @property int fontSize()
    {
        return _fontSize;
    }
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
    int _fontSize;
    Color _textColor;
}
