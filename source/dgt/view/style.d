/// Node style module
module dgt.view.style;

import dgt.css.color;
import dgt.view.layout;
import dgt.view.view;


/// Font style as defined by the CSS specification
enum FontStyle
{
    normal,
    italic,
    oblique,
}

/// Bit flags that describe the pseudo state of a node.
/// Several states can be active at the same time (e.g. disabled and checked).
/// Pseudo state style can be specified by using corresponding
/// css pseudo-class selectors.
enum PseudoState
{
    // default state
    def             = 0,

    // UI state
    uiMask          = 0x0f,
    checked         = 0x01,
    disabled        = 0x02,
    indeterminate   = 0x04,

    // dynamic state
    dynMask         = 0xf0,
    active          = 0x10,
    hover           = 0x20,
    focus           = 0x40,
}

/// The style class groups all properties affecting visual appearance of nodes.
/// It is populated during the CSS pass.
class Style
{
    this(View node)
    {
        _node = node;
    }

    /// The node associated with this style.
    @property View node()
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

    @property Layout.Params layoutParams()
    {
        return _layoutParams;
    }

    @property void layoutParams(Layout.Params params)
    {
        _layoutParams = params;
    }

private:
    View _node;

    Color _backgroundColor;

    string[] _fontFamily;
    int _fontWeight;
    FontStyle _fontStyle;
    int _fontSize;

    Layout.Params _layoutParams;
}
