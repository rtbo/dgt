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

    /// The bounds of this nodes in local node coordinates.
    @property FRect bounds() const { return _bounds; }

    /// The bounds of the children of this node in local coordinates.
    @property FRect childrenBounds() const { return _childrenBounds; }

    /// The bounds of this nodes in global screen coordinates
    @property FRect screenBounds() const { return _screenBounds; }

    /// The transform affecting this node and its children.
    /// Define the transform from parent coordinates to local coordinates.
    @property FMat4 transform() const { return _transform; }

    /// ditto
    @property void transform(in FMat4 transform)
    {
        _transform = transform;
        _hasTransform = transform != FMat4.identity;
    }

    /// Whether this node has a transform set. (Other than identity)
    @property bool hasTransform() const { return _hasTransform; }

    /// Whether this node is dynamic.
    /// Dynamic basically means animated. That is, the rendering data can vary
    /// about every frame.
    /// This flag mainly impact caching policy.
    @property bool dynamic() const { return _dynamic; }

    /// ditto
    @property void dynamic(bool dynamic)
    {
        _dynamic = dynamic;
    }

    /// Collect the render node for this node.
    immutable(RenderNode) collectRenderNode()
    {
        immutable toBeTransformed = collectLocalRenderNode();
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
    abstract immutable(RenderNode) collectLocalRenderNode();

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

    string typeName() const
    {
        return "SgNode";
    }

    string[2][] properties() const
    {
        import std.format : format;
        string[2][] props;
        if (name.length) {
            props ~= ["name", format("'%s'", name)];
        }
        props ~= ["bounds", format("%s", _bounds)];
        return props;
    }

    override string toString()
    {
        import std.array : array;
        import std.format : format;
        import std.range : repeat;
        auto indent = repeat(' ', level*4).array;
        return format("%s%s { %(%-(%s:%), %) }", indent, typeName, properties);
    }

    // graph
    package SgParent _parent;

    package SgNode _prevSibling;
    package SgNode _nextSibling;

    // bounds
    private FRect _bounds;
    private FRect _screenBounds;
    private FRect _childrenBounds;

    // transform
    private FMat4 _transform = FMat4.identity;
    private bool _hasTransform;

    // cache policy
    private bool _dynamic=false;

    // debug info
    private string _name;
}



class SgColorRectNode : SgNode
{
    this() {}

    @property FVec4 color() const { return _color; }
    @property void color(in FVec4 color)
    {
        _color = color;
    }

    @property FRect rect() const { return _bounds; }
    @property void rect(in FRect rect)
    {
        _bounds = rect;
    }

    override protected immutable(RenderNode) collectLocalRenderNode()
    {
        return new immutable ColorRenderNode(_color, bounds);
    }

    override string typeName() const
    {
        return "SgColorRectNode";
    }

    private FVec4 _color;
}


class SgImageNode : SgNode
{
    this() {}

    @property inout(Image) image() inout { return _image; }
    @property void image(Image image) {
        _image = image;
        _immutImg = null;
    }
    @property void image(immutable(Image) image)
    {
        _image = null;
        _immutImg = image;
    }

    @property FPoint topLeft() const { return _topLeft; }
    @property void topLeft(in FPoint topLeft)
    {
        _topLeft = topLeft;
    }

    override protected immutable(RenderNode) collectLocalRenderNode()
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

    override string typeName() const
    {
        return "SgImageNode";
    }


    private Image _image;
    private FPoint _topLeft;
    private Rebindable!(immutable(Image)) _immutImg;
    private RenderCacheCookie _rcc;
}


class SgTextNode : SgNode
{
    this() {}

    @property string text () const { return _text; }
    @property void text (string text)
    {
        _text = text;
        _renderNode = null;
    }

    @property FontRequest font() const { return _font; }
    @property void font(FontRequest font)
    {
        _font = font;
        _renderNode = null;
    }

    @property FVec4 color() const { return _color; }
    @property void color(in FVec4 color)
    {
        _color = color;
        _renderNode = null;
    }

    override protected immutable(RenderNode) collectLocalRenderNode()
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
