/// Scene graph module
module dgt.sg.node;

import dgt.geometry;
import dgt.math;
import dgt.render;
import dgt.render.node;
import dgt.sg.layout;
import dgt.sg.parent;
import dgt.window;

import std.exception;
import std.experimental.logger;
import std.typecons;

/// A node for a 2D scene-graph
abstract class SgNode
{
    /// builds a new node
    this() {}

    /// The window this node is attached to.
    @property Window window()
    {
        return root._window;
    }

    /// The root of this scene graph
    @property SgParent root()
    {
        if (!_parent) return cast(SgParent)this;
        SgParent p = _parent;
        while (p._parent) p = p._parent;
        return p;
    }

    /// Whether this node is root
    @property bool isRoot() const
    {
        return _parent is null;
    }

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

    /// The layout parameters of this node
    @property inout(SgLayout.Params) layoutParams() inout
    {
        return _layoutParams;
    }

    /// ditto
    @property void layoutParams(SgLayout.Params params)
    {
        _layoutParams = params;
    }

    /// The padding of the node, that is, how much empty space is required
    /// around the content.
    /// Padding is always within the node's rect.
    @property FPadding padding() const
    {
        return _padding;
    }

    /// ditto
    @property void padding(in FPadding padding)
    {
        _padding = padding;
    }

    /// Ask this node to measure itself by assigning the measurement property.
    void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        measurement = FSize(widthSpec.size, heightSpec.size);
    }

    /// Size set by the node during measure phase
    final @property FSize measurement() const
    {
        return _measurement;
    }

    final protected @property void measurement(in FSize sz)
    {
        _measurement = sz;
    }

    /// Ask the node to layout itself in the given rect
    void layout(in FRect rect)
    {
        layoutRect = rect;
    }

    /// Rect set by the node during layout phase.
    final @property FRect layoutRect() const
    {
        return _layoutRect;
    }

    final protected @property layoutRect(in FRect rect)
    {
        _layoutRect = rect;
    }


    /// The bounds of this nodes in local node coordinates.
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
    /// The transform does not affect the layout, but affects rendering.
    /// It should be used for animation mainly.
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
        else if (hasTransform || _layoutRect.point != FPoint(0f, 0f)) {
            FMat4 tr = translation!float(fvec(_layoutRect.point, 0));
            if (hasTransform) {
                tr = tr * _transform;
            }
            return new immutable TransformRenderNode(
                tr, toBeTransformed
            );
        }
        else {
            return toBeTransformed;
        }
    }

    /// Collect the local render node for this node.
    /// Local means unaltered by the transform.
    abstract immutable(RenderNode) collectRenderNode();

    /// Requires node to dispose any resource that it would keep.
    /// This is called at termination, or when a node is removed from the graph.
    /// Allows to have resource collection that is determined and indenpendent from GC.
    /// It does not need to be called by application.
    void disposeResources() {}

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

    string[2][] properties()
    {
        import std.format : format;
        string[2][] props;
        if (name.length) {
            props ~= ["name", format("'%s'", name)];
        }
        props ~= ["transformedBounds", format("%s", transformedBounds)];
        return props;
    }

    override string toString()
    {
        import std.array : array;
        import std.format : format;
        import std.range : repeat;
        auto indent = repeat(' ', level*4).array;
        return format("%s%s { %(%-(%s:%), %) }", indent, this.className, properties);
    }

    // graph
    package SgParent _parent;

    package SgNode _prevSibling;
    package SgNode _nextSibling;

    // layout
    private FPadding        _padding;
    private SgLayout.Params _layoutParams;
    private FSize           _measurement;
    private FRect           _layoutRect;

    // bounds
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


struct RenderCacheCookie
{
    ulong cookie;

    ulong collectCookie(in bool dynamic)
    {
        if (!dynamic && !cookie) {
            cookie = RenderThread.instance.nextCacheCookie();
        }
        else if (dynamic && cookie) {
            RenderThread.instance.deleteCache(cookie);
            cookie = 0;
        }
        return cookie;
    }
    void dirty(in bool dynamic)
    {
        if (cookie) {
            RenderThread.instance.deleteCache(cookie);
            cookie = 0;
        }
    }
}

package @property string className(Object obj)
{
    import std.algorithm : splitter;
    return typeid(obj).toString().splitter('.').back;
}
