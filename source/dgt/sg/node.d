/// Scene graph module
module dgt.sg.node;

import dgt.application;
import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.sg.parent;
import dgt.sg.render.node;
import dgt.text.fontcache;
import dgt.text.layout;

import gfx.foundation.rc;

import std.exception;
import std.typecons;

/// A node for a 2D scene-graph
abstract class SgNode
{
    this() {}

    /// This node's parent.
    @property inout(SgParent) parent() inout
    {
        return _parent;
    }

    /// This node's previous sibling.
    @property inout(SgNode) prevSibling() inout
    {
        return _prevSibling;
    }

    /// This node's next sibling.
    @property inout(SgNode) nextSibling() inout
    {
        return _nextSibling;
    }

    /// The transformedBounds of this nodes in local node coordinates.
    @property FRect bounds()
    {
        if (_bounds.dirty) _bounds = computeBounds();
        return _bounds;
    }

    /// The transformedBounds of this nodes after its transformation is applied.
    @property FRect transformedBounds()
    {
        if (_transformedBounds.dirty) _transformedBounds = computeTransformedBounds();
        return _transformedBounds;
    }

    abstract protected FRect computeBounds();
    protected FRect computeTransformedBounds()
    {
        immutable b = bounds;
        return _hasTransform ? transformBounds(b, _transform) : b;
    }

    /// Marks transformedBounds as dirty, meaning they need to be re-computed.
    void dirtyBounds()
    {
        _bounds.dirty = true;
        _transformedBounds.dirty = true;
        if (_parent) _parent.dirtyBounds();
    }

    /// The transform affecting this node and its children.
    /// Define the transform from parent coordinates to local coordinates.
    @property FMat4 transform() const { return _transform; }

    /// ditto
    @property void transform(in FMat4 transform)
    {
        _transform = transform;
        _hasTransform = transform != FMat4.identity;
        _transformedBounds.dirty = true;
        if (_parent) _parent.dirtyBounds();
    }

    /// Whether this node has a transform set. (Other than identity)
    @property bool hasTransform() const { return _hasTransform; }

    /// Whether this node is dynamic.
    /// Dynamic basically means that the rendering data can vary
    /// about every frame. Whether the transform changes at every frame
    /// or not should not influence this flag.
    /// This flag mainly impact caching policy.
    @property bool dynamic() const { return _dynamic; }

    /// ditto
    @property void dynamic(bool dynamic)
    {
        _dynamic = dynamic;
    }

    /// Collect the render node for this node.
    immutable(RenderNode) collectTransformedRenderNode()
    {
        immutable toBeTransformed = collectRenderNode();
        if (!toBeTransformed) return null;
        else if (hasTransform) {
            return new immutable TransformRenderNode(
                _transform, toBeTransformed
            );
        }
        else {
            return toBeTransformed;
        }
    }

    /// Collect the local render node for this node.
    /// Local means unaltered by the transform.
    abstract immutable(RenderNode) collectRenderNode();

    @property uint level() const
    {
        Rebindable!(const(SgParent)) p = parent;
        uint lev=0;
        while (p !is null) {
            ++lev;
            p = p.parent;
        }
        return lev;
    }

    @property string name() const { return _name; }
    @property void name(string name)
    {
        _name = name;
    }

    string[2][] properties() const
    {
        import std.format : format;
        string[2][] props;
        if (name.length) {
            props ~= ["name", format("'%s'", name)];
        }
        props ~= ["transformedBounds", format("%s", _transformedBounds.val)];
        return props;
    }

    override string toString()
    {
        import std.array : array;
        import std.format : format;
        import std.range : repeat;
        auto indent = repeat(' ', level*4).array;
        return format("%s%s { %(%-(%s:%), %) }", indent, this.classinfo.name, properties);
    }

    // graph
    package SgParent _parent;

    package SgNode _prevSibling;
    package SgNode _nextSibling;

    // transformedBounds
    private Lazy!FRect _bounds;
    private Lazy!FRect _transformedBounds;

    // transform
    private FMat4 _transform = FMat4.identity;
    private bool _hasTransform;

    // cache policy
    private bool _dynamic=false;

    // debug info
    private string _name;
}

struct Lazy(T)
{
    T val;
    bool dirty = true;

    void opAssign(T val)
    {
        this.val = val;
        dirty = false;
    }

    alias val this;
}


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
        dirtyBounds();
    }

    @property FontRequest font() const { return _font; }
    @property void font(FontRequest font)
    {
        _font = font;
        _renderNode = null;
        dirtyBounds();
    }

    @property FVec4 color() const { return _color; }
    @property void color(in FVec4 color)
    {
        _color = color;
        _renderNode = null;
    }

    override protected FRect computeBounds()
    {
        auto layout = makeRc!TextLayout(text, TextFormat.plain, _font);
        layout.layout();
        immutable metrics = layout.metrics;
        immutable topLeft = cast(FVec2)(-metrics.bearing);
        immutable size = cast(FVec2)metrics.size;
        return FRect(topLeft, FSize(size));
    }

    override protected immutable(RenderNode) collectRenderNode()
    {
        if (!_renderNode) {
            auto layout = makeRc!TextLayout(text, TextFormat.plain, _font);
            layout.layout();
            layout.prepareGlyphRuns();
            _renderNode = new immutable(TextRenderNode)(
                layout.render(), _color
            );
        }
        return _renderNode;
    }

    private string _text;
    private FontRequest _font;
    private FVec4 _color;
    Rebindable!(immutable(TextRenderNode)) _renderNode;
}


struct RenderCacheCookie
{
    ulong cookie;

    ulong collectCookie(in bool dynamic)
    {
        if (!dynamic && !cookie) {
            cookie = Application.instance.nextRenderCacheCookie();
        }
        else if (dynamic && cookie) {
            Application.instance.deleteRenderCache(cookie);
            cookie = 0;
        }
        return cookie;
    }
    void dirty(in bool dynamic)
    {
        if (cookie) {
            Application.instance.deleteRenderCache(cookie);
            cookie = 0;
        }
    }
}
