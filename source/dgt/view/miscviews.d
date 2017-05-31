/// A few misc nodes
module dgt.view.miscviews;

import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.render.node;
import dgt.sg.node;
import dgt.text.fontcache;
import dgt.text.layout;
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

    @property FVec4 color() const { return _color; }
    @property void color(in FVec4 color)
    {
        _color = color;
    }

    override @property string cssType()
    {
        return "rect";
    }

    override protected immutable(RenderNode) collectRenderNode()
    {
        return new immutable RectFillRenderNode(_color, rect);
    }

    override SGNode sgUpdateContent(SGNode previous)
    {
        auto rfn = cast(SGRectFillNode)previous;
        if (!rfn) rfn = new SGRectFillNode;
        rfn.rect = localRect;
        rfn.color = color;
        return rfn;
    }

    private FVec4 _color;
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

    override protected immutable(RenderNode) collectRenderNode()
    {
        if (_img) {
            return new immutable ImageRenderNode (
                pos, _img, _rcc.collectCookie(dynamic)
            );
        }
        else {
            return null;
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
    private RenderCacheCookie _rcc;
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
        _renderNode = null;
        _layout = null;
        sgHasContent = _text.length != 0;
    }

    @property FVec4 color() const { return _color; }
    @property void color(in FVec4 color)
    {
        _color = color;
        _renderNode = null;
    }

    @property TextMetrics metrics()
    {
        ensureLayout();
        return _metrics;
    }

    private void resetStyle(string)
    {
        _renderNode = null;
        _layout = null;
        invalidate();
    }

    override @property string cssType()
    {
        return "text";
    }

    override protected immutable(RenderNode) collectRenderNode()
    {
        if (!_renderNode) {
            ensureLayout();
            _renderNode = new immutable(TextRenderNode)(
                _layout.render(), cast(FVec2)_metrics.bearing, _color
            );
        }
        return _renderNode;
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
        if (!_layout) {
            _layout = new TextLayout(_text, TextFormat.plain, style);
            _layout.layout();
            _layout.prepareGlyphRuns();
            _metrics = _layout.metrics;
        }
    }

    private string _text;
    private FVec4 _color;
    private TextLayout _layout;
    private TextMetrics _metrics;
    private Rebindable!(immutable(TextRenderNode)) _renderNode;
}
