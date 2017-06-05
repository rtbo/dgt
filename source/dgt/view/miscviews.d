/// A few misc nodes
module dgt.view.miscviews;

import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.sg.node;
import dgt.sg.rect;
import dgt.text.fontcache;
import dgt.text.layout;
import dgt.view.layout;
import dgt.view.style;
import dgt.view.view;

import std.experimental.logger;
import std.typecons;

class ColorRect : View
{
    this()
    {
        sgHasContent = true;
    }

    @property float radius()
    {
        return _radius;
    }
    @property void radius(in float radius)
    {
        _radius = radius;
        invalidate();
    }

    @property FVec4 fillColor()
    {
        return _fillColor;
    }
    @property void fillColor(in FVec4 fillCol)
    {
        _fillColor = fillCol;
        invalidate();
    }

    @property FVec4 strokeColor()
    {
        return _strokeColor;
    }
    @property void strokeColor(in FVec4 strokeCol)
    {
        _strokeColor = strokeCol;
        invalidate();
    }

    @property float strokeWidth()
    {
        return _strokeWidth;
    }
    @property void strokeWidth(in float width)
    {
        _strokeWidth = width;
        invalidate();
    }

    override @property string cssType()
    {
        return "rect";
    }

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        measurement = size;
    }

    override SGNode sgUpdateContent(SGNode previous)
    {
        auto rn = cast(SGRectNode)previous;
        if (!rn) rn = new SGRectNode;
        rn.rect = localRect;
        rn.fillColor = fillColor;
        rn.strokeColor = strokeColor;
        rn.strokeWidth = strokeWidth;
        rn.radius = radius;
        return rn;
    }

    private float _radius = 0f;
    private FVec4 _fillColor;
    private FVec4 _strokeColor;
    private float _strokeWidth;
}


class ImageView : View
{
    this() {}

    final @property immutable(Image) image()
    {
        return _img;
    }

    final @property void image(immutable(Image) image)
    {
        _img = image;
        sgHasContent = _img !is null;
        invalidate();
    }

    override @property string cssType()
    {
        return "img";
    }

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        if (_img) {
            measurement = cast(FSize)_img.size;
        }
        else {
            super.measure(widthSpec, heightSpec);
        }
    }

    override SGNode sgUpdateContent(SGNode previous)
    {
        if (_img) {
            auto imgN = cast(SGImageNode)previous;
            if (!imgN) imgN = new SGImageNode;
            imgN.topLeft = fvec(0, 0);
            imgN.image = _img;
            return imgN;
        }
        else {
            return null;
        }
    }


    private Rebindable!(immutable(Image)) _img;
}


class TextView : View
{
    this()
    {
        super();
        _color = fvec(0, 0, 0 ,1);
        style.onChange += &resetStyle;
    }

    @property string text () const { return _text; }
    @property void text (string text)
    {
        _text = text;
        _layout = null;
        sgHasContent = _text.length != 0;
    }

    @property FVec4 color() const { return _color; }
    @property void color(in FVec4 color)
    {
        _color = color;
    }

    @property TextMetrics metrics()
    {
        ensureLayout();
        return _metrics;
    }

    private void resetStyle(string)
    {
        _layout = null;
        invalidate();
    }

    override @property string cssType()
    {
        return "text";
    }

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        ensureLayout();
        if (_layout) {
            measurement = FSize(cast(FVec2)metrics.size);
        }
        else {
            super.measure(widthSpec, heightSpec);
        }
    }

    override SGNode sgUpdateContent(SGNode previous)
    {
        if (text.length) {
            ensureLayout();
            auto tn = cast(SGTextNode)previous;
            if (!tn) tn = new SGTextNode;
            tn.glyphs = _layout.render();
            tn.pos = cast(FVec2)_metrics.bearing;
            tn.color = _color;
            return tn;
        }
        else {
            return null;
        }
    }

    private void ensureLayout()
    {
        if (!_layout && _text.length) {
            _layout = new TextLayout(_text, TextFormat.plain, style);
            _layout.layout();
            _layout.prepareGlyphRuns();
            _metrics = _layout.metrics;
        }
        else if (!_text.length) {
            _layout = null;
        }
    }

    private string _text;
    private FVec4 _color;
    private TextLayout _layout;
    private TextMetrics _metrics;
}
