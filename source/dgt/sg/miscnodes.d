/// A few misc nodes
module dgt.sg.miscnodes;

import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.render.node;
import dgt.sg.node;
import dgt.text.fontcache;
import dgt.text.layout;

import gfx.foundation.rc;

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

    @property FRect rect() const { return _rect; }
    @property void rect(in FRect rect)
    {
        _rect = rect;
        dirtyBounds();
    }

    override protected FRect computeBounds()
    {
        return _rect;
    }

    override protected immutable(RenderNode) collectRenderNode()
    {
        return new immutable ColorRenderNode(_color, bounds);
    }

    private FVec4 _color;
    private FRect _rect;
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

    @property FPoint topLeft() const { return _topLeft; }
    @property void topLeft(in FPoint topLeft)
    {
        _topLeft = topLeft;
        dirtyBounds();
    }

    protected override FRect computeBounds()
    {
        return FRect(_topLeft, _size);
    }

    override protected immutable(RenderNode) collectRenderNode()
    {
        if (_image && !_immutImg) _immutImg = _image.idup;

        if (_immutImg) {
            return new immutable ImageRenderNode (
                _topLeft, _immutImg, _rcc.collectCookie(dynamic)
            );
        }
        else {
            return null;
        }
    }


    private FPoint _topLeft;
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
        _layout.unload();
        dirtyBounds();
    }

    @property FontRequest font() const { return _font; }
    @property void font(FontRequest font)
    {
        _font = font;
        _renderNode = null;
        _layout.unload();
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
        immutable topLeft = cast(FVec2)(-_metrics.bearing);
        immutable size = cast(FVec2)_metrics.size;
        return FRect(topLeft, FSize(size));
    }

    override protected immutable(RenderNode) collectRenderNode()
    {
        if (!_renderNode) {
            ensureLayout();
            _renderNode = new immutable(TextRenderNode)(
                _layout.render(), _color
            );
        }
        return _renderNode;
    }

    override void disposeResources()
    {
        _layout.unload();
        _renderNode = null;
    }

    private void ensureLayout()
    {
        if (!_layout) {
            _layout = makeRc!TextLayout(_text, TextFormat.plain, _font);
            _layout.layout();
            _layout.prepareGlyphRuns();
            _metrics = _layout.metrics;
        }
    }

    private string _text;
    private FontRequest _font;
    private FVec4 _color;
    private Rc!TextLayout _layout;
    private TextMetrics _metrics;
    private Rebindable!(immutable(TextRenderNode)) _renderNode;
}
