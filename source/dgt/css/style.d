/// CSS Style
module dgt.css.style;

import dgt.css.color;
import dgt.css.value;
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

    @property Length fontSize()
    {
        return _fontSize;
    }
    @property void fontSize(Length l)
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
    Length _fontSize;
    Color _textColor;
}
