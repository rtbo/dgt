/// A few misc nodes
module dgt.sg.miscnodes;

import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.render.node;
import dgt.sg.node;
import dgt.text.fontcache;
import dgt.text.layout;

import std.typecons;
import std.experimental.logger;

class SgColorRect : SgNode
{
    this() {}

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

    private FVec4 _color;
}


class SgImage : SgNode
{
    this() {}

    final @property immutable(Image) image()
    {
        return _img;
    }

    final @property void image(immutable(Image) image)
    {
        _img = image;
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


    private Rebindable!(immutable(Image)) _img;
    private RenderCacheCookie _rcc;
}


class SgText : SgNode
{
    this()
    {
        _color = fvec(0, 0, 0 ,1);
    }

    @property string text () const { return _text; }
    @property void text (string text)
    {
        _text = text;
        _renderNode = null;
        _layout = null;
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
