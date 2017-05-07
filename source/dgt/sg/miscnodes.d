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

    @property FRect rect() const { return FRect(pos, _size); }
    @property void rect(in FRect rect)
    {
        _size = rect.size;
        pos = rect.point;
    }

    override protected FRect computeBounds()
    {
        return rect;
    }

    override protected immutable(RenderNode) collectRenderNode()
    {
        return new immutable RectFillRenderNode(_color, rect);
    }

    private FVec4 _color;
    private FSize _size;
}


class SgImage : SgNode
{
    this() {}

    @property inout(Image) image() inout { return _image; }
    @property void image(Image image)
    {
        _image = image;
        _immutImg = null;
        _size = cast(FSize)image.size;
        dirtyBounds();
    }
    @property void image(immutable(Image) image)
    {
        _image = null;
        _immutImg = image;
        _size = cast(FSize)image.size;
        dirtyBounds();
    }

    protected override FRect computeBounds()
    {
        return FRect(pos, _size);
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


    private FSize _size;
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
        dirtyBounds();
    }

    @property FontRequest font() const { return _font; }
    @property void font(FontRequest font)
    {
        _font = font;
        _renderNode = null;
        _layout = null;
        dirtyBounds();
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

    override protected FRect computeBounds()
    {
        ensureLayout();
        immutable topLeft = pos - cast(FVec2)_metrics.bearing;
        immutable size = cast(FVec2)_metrics.size;
        return FRect(topLeft, FSize(size));
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
            _layout = new TextLayout(_text, TextFormat.plain, _font);
            _layout.layout();
            _layout.prepareGlyphRuns();
            _metrics = _layout.metrics;
        }
    }

    private string _text;
    private FontRequest _font;
    private FVec4 _color;
    private TextLayout _layout;
    private TextMetrics _metrics;
    private Rebindable!(immutable(TextRenderNode)) _renderNode;
}
