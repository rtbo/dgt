/// Text node module
module dgt.ui.text;

import dgt.core.color;
import dgt.core.geometry;
import dgt.core.paint;
import dgt.css.style;
import dgt.font.style;
import dgt.render.framegraph;
import dgt.text.layout;
import dgt.ui.layout;
import dgt.ui.style;
import dgt.ui.view;

class TextView : View {

    this() {
        _layout = new TextLayout;

        addShorthandStyleSupport(this, FontMetaProperty.instance);
        _fontFamily = addStyleSupport(this, FontFamilyMetaProperty.instance);
        _fontWeight = addStyleSupport(this, FontWeightMetaProperty.instance);
        _fontSlant = addStyleSupport(this, FontSlantMetaProperty.instance);
        _fontSize = addStyleSupport(this, FontSizeMetaProperty.instance);

        _fontFamily.onChange += &styleReset;
        _fontWeight.onChange += &styleReset;
        _fontSlant.onChange += &styleReset;
        _fontSize.onChange += &styleReset;
    }

    @property string text () const { return _text; }
    @property void text (string text)
    {
        _text = text;
        _layoutDirty = true;
    }

    @property Color color() const { return _color; }
    @property void color(in Color color)
    {
        _color = color;
    }

    @property TextMetrics metrics()
    {
        ensureLayout();
        return _metrics;
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

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        if (_text.length) {
            measurement = FSize(cast(FVec2)metrics.size);
        }
        else {
            super.measure(widthSpec, heightSpec);
        }
    }

    override immutable(FGNode) render(FrameContext fc) {
        ensureLayout();
        return new immutable(FGTextNode) (
            _layout.metrics.bearing,
            _layout.shapes,
            _color.asVec,
        );
    }

    private void styleReset()
    {
        _layoutDirty = true;
        invalidate();
    }

    private void ensureLayout()
    {
        if (_layoutDirty && _text.length) {
            immutable p = new immutable ColorPaint(_color);
            const fs = FontStyle(cast(FontWeight)fontWeight, fontSlant);

            _layout.clearItems();
            // only single item supported at this point
            _layout.addItem(TextItem(_text, fontFamily, fs, fontSize, p));
            _layout.layout();
            _metrics = _layout.metrics;
            _layoutDirty = false;
        }
        else if (!_text.length) {
            _layoutDirty = true;
        }
    }

    private string _text;
    private Color _color = Color.black;
    private TextLayout _layout;
    private TextMetrics _metrics;
    private bool _layoutDirty;
    private StyleProperty!(string[])    _fontFamily;
    private StyleProperty!FontWeight    _fontWeight;
    private StyleProperty!FontSlant     _fontSlant;
    private StyleProperty!int           _fontSize;
}
