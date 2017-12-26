/// Text node module
module dgt.scene.text;

import dgt.core.color;
import dgt.core.paint;
import dgt.css.style;
import dgt.font.style;
import dgt.scene.node;
import dgt.scene.style;
import dgt.text.layout;

class TextNode : Node {

    this() {
        _layout = new TextLayout;

        addShorthandStyleSupport(this, FontMetaProperty.instance);
        _fontFamily = addStyleSupport(this, FontFamilyMetaProperty.instance);
        _fontWeight = addStyleSupport(this, FontWeightMetaProperty.instance);
        _fontSlant = addStyleSupport(this, FontSlantMetaProperty.instance);
        _fontSize = addStyleSupport(this, FontSizeMetaProperty.instance);

        _fontFamily.onChange += &resetStyle;
        _fontWeight.onChange += &resetStyle;
        _fontSlant.onChange += &resetStyle;
        _fontSize.onChange += &resetStyle;
    }

    @property string text () const { return _text; }
    @property void text (string text)
    {
        _text = text;
        _layout.clearItems();
    }

    @property Color color() const { return _color; }
    @property void color(in Color color)
    {
        _color = color;
    }
    override @property string cssType()
    {
        return "text";
    }

    @property string[] fontFamily()
    {
        return _fontFamily.value;
    }
    @property StyleProperty!(string[]) fontFamilyProperty()
    {
        return _fontFamily;
    }

    @property FontWeight fontWeight()
    {
        return _fontWeight.value;
    }
    @property StyleProperty!FontWeight fontWeightProperty()
    {
        return _fontWeight;
    }

    @property FontSlant fontSlant()
    {
        return _fontSlant.value;
    }
    @property StyleProperty!FontSlant fontSlantProperty()
    {
        return _fontSlant;
    }

    @property int fontSize()
    {
        return _fontSize.value;
    }
    @property StyleProperty!int fontSizeProperty()
    {
        return _fontSize;
    }


    private void resetStyle()
    {
        _layout.clearItems();
        invalidate();
    }

    private void ensureLayout()
    {
        if (_layout.empty && _text.length) {
            immutable p = new ColorPaint(_color);
            const fs = FontStyle(cast(FontWeight)fontWeight, fontSlant);
            const ts = TextStyle(fontSize, fontFamily[0], fs, p); // fixme family fallback

            _layout.addItem(TextItem(_text, ts));
            _layout.layout();
            _metrics = _layout.metrics;
        }
        else if (!_text.length) {
            _layout.clearItems();
        }
    }

    private string _text;
    private Color _color;
    private TextLayout _layout;
    private TextMetrics _metrics;
    private StyleProperty!(string[])    _fontFamily;
    private StyleProperty!FontWeight    _fontWeight;
    private StyleProperty!FontSlant     _fontSlant;
    private StyleProperty!int           _fontSize;
}
