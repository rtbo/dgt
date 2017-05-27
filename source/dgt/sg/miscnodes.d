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

    final @property inout(Image) image() inout { return _image; }
    final @property void image(Image image)
    {
        _image = image;
        _immutImg = null;
        size = cast(FSize)image.size;
    }
    final @property void image(immutable(Image) image)
    {
        _image = null;
        _immutImg = image;
        size = cast(FSize)image.size;
    }

    override @property string cssType()
    {
        return "image";
    }

    override @property FRect localBounds()
    {
        return FRect(0, 0, cast(FSize)_image.size);
    }

    override protected immutable(RenderNode) collectRenderNode()
    {
        if (_image && !_immutImg) _immutImg = _image.idup;

        if (_immutImg) {
            return new immutable ImageRenderNode (
                pos, _immutImg, _rcc.collectCookie(dynamic)
            );
        }
        else {
            return null;
        }
    }


    private Image _image;
    private Rebindable!(immutable(Image)) _immutImg;
    private RenderCacheCookie _rcc;
}


class SgText : SgNode
{
    this() {}

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

    override @property FRect localBounds()
    {
        ensureLayout();
        immutable topLeft = -cast(FVec2)_metrics.bearing;
        immutable size = cast(FVec2)_metrics.size;
        return FRect(topLeft, FSize(size));
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
                _layout.render(), pos, _color
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
