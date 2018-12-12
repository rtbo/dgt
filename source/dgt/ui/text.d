/// Text node module
module dgt.ui.text;

import dgt.core.color;
import dgt.core.geometry;
import dgt.core.paint;
import dgt.css.style;
import dgt.font.style;
import dgt.render.framegraph;
import dgt.text.layout;
import dgt.style.support;
import dgt.ui.layout;
import dgt.ui.view;

class TextView : View {

    this() {
        _layout = new TextLayout;

        fss.initialize(this);
        fss.fontFamily.onChange += &styleReset;
        fss.fontWeight.onChange += &styleReset;
        fss.fontSlant.onChange += &styleReset;
        fss.fontSize.onChange += &styleReset;
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
        return fss.fontFamily.value;
    }
    @property StyleProperty!(string[]) fontFamilyProperty()
    {
        return fss.fontFamily;
    }

    @property FontWeight fontWeight()
    {
        return fss.fontWeight.value;
    }
    @property StyleProperty!FontWeight fontWeightProperty()
    {
        return fss.fontWeight;
    }

    @property FontSlant fontSlant()
    {
        return fss.fontSlant.value;
    }
    @property StyleProperty!FontSlant fontSlantProperty()
    {
        return fss.fontSlant;
    }

    @property int fontSize()
    {
        return fss.fontSize.value;
    }
    @property StyleProperty!int fontSizeProperty()
    {
        return fss.fontSize;
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

    override immutable(FGNode) frame(FrameContext fc)
    {
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
    private FontStyleSupport fss;
}
