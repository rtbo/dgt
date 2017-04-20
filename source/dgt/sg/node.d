/// Scene graph module
module dgt.sg.node;

import dgt.sg.render.node;
import dgt.geometry;
import dgt.math;
import dgt.image;
import dgt.application;

import std.exception;
import std.range;
import std.typecons;

/// A node for a 2D scene-graph
class SgNode
{
    this() {}

    /// Whether this node has children.
    @property bool hasChildren() const
    {
        return _firstChild !is null;
    }

    /// The number of children this node has.
    @property size_t childCount() const
    {
        return _childCount;
    }

    /// This node's parent.
    @property inout(SgNode) parent() inout
    {
        return _parent;
    }

    /// This node's first child.
    @property inout(SgNode) firstChild() inout
    {
        return _firstChild;
    }

    /// This node's last child.
    @property inout(SgNode) lastChild() inout
    {
        return _lastChild;
    }

    /// This node's previous sibling.
    @property inout(SgNode) prevSibling() inout
    {
        return _prevSibling;
    }

    /// This node's next sibling.
    @property inout(SgNode) nextSibling() inout
    {
        return nextSibling;
    }

    /// A bidirectional range of this nodes children
    @property auto children()
    {
        return SgSiblingNodeRange!SgNode(_firstChild, _lastChild);
    }

    /// A bidirectional range of this nodes children
    @property auto children() const
    {
        return SgSiblingNodeRange!(const(SgNode))(_firstChild, _lastChild);
    }

    /// Appends the given node to this node children list.
    void appendChild(SgNode node)
    {
        enforce(node && !node._parent);
        node._parent = this;

        if (!hasChildren) {
            _firstChild = node;
            _lastChild = node;
        }
        else {
            _lastChild._nextSibling = node;
            node._prevSibling = _lastChild;
            _lastChild = node;
        }
        ++_childCount;
    }

    /// Prepend the given node to this node children list.
    void prependChild(SgNode node)
    {
        enforce(node && !node._parent);
        node._parent = this;

        if (!hasChildren) {
            _firstChild = node;
            _lastChild = node;
        }
        else {
            _firstChild._prevSibling = node;
            node._nextSibling = _firstChild;
            _firstChild = node;
        }
        ++_childCount;
    }

    /// Insert the given node in this node children list, just before the given
    /// child.
    void insertChildBefore(SgNode node, SgNode child)
    {
        enforce(node && !node._parent && child._parent is this);
        node._parent = this;

        if (child is _firstChild) {
            _firstChild = node;
        }
        else {
            auto prev = child._prevSibling;
            prev._nextSibling = node;
            node._prevSibling = prev;
        }
        child._prevSibling = node;
        node._nextSibling = child;
        ++_childCount;
    }

    /// Removes the given node from this node children list.
    void removeChild(SgNode child)
    {
        enforce(child && child._parent is this);

        child._parent = null;

        if (_childCount == 1) {
            _firstChild = null;
            _lastChild = null;
        }
        else if (child is _firstChild) {
            _firstChild = child._nextSibling;
            _firstChild._prevSibling = null;
        }
        else if (child is _lastChild) {
            _lastChild = child._prevSibling;
            _lastChild._nextSibling = null;
        }
        else {
            auto prev = child._prevSibling;
            auto next = child._nextSibling;
            prev._nextSibling = next;
            next._prevSibling = prev;
        }
        --_childCount;
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
        immutable childrenNode = collectChildrenRenderNode();
        immutable localNode = collectLocalRenderNode();
        immutable toBeTransformed =
            (childrenNode && localNode) ? new immutable GroupRenderNode(
                [localNode, childrenNode]
            ) :
            (localNode ? localNode :
            (childrenNode ? childrenNode : null));

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
    /// Local means already transformed and without children.
    protected immutable(RenderNode) collectLocalRenderNode()
    {
        return null;
    }

    /// Collect a node grouping the children together.
    protected immutable(RenderNode) collectChildrenRenderNode()
    {
        import std.algorithm : map, filter;
        import std.array : array;
        if (!_childCount) return null;
        else return new immutable(GroupRenderNode)(
            childrenBounds,
            children.map!(c => c.collectRenderNode())
                    .filter!(rn => rn !is null)
                    .array()
        );
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

    protected string toStringInternal(size_t indent)
    {
        import std.array : array;
        import std.format : format;
        import std.range : repeat;
        auto indentStr = repeat(' ', indent*4).array;
        string res;
        res = format("%s%s { %(%-(%s:%), %) ", indentStr, typeName, properties);
        if (hasChildren) {
            res ~= format("[\n");
            size_t ind=0;
            foreach(c; children) {
                res ~= c.toStringInternal(indent+1);
                if (ind != _childCount-1) {
                    res ~= ",\n";
                }
                ++ind;
            }
            res ~= format("\n%s]", indentStr);
        }
        res ~= "}";
        return res;
    }

    override string toString()
    {
        return toStringInternal(0);
    }


    invariant()
    {
        assert(!_firstChild || _firstChild.parent is this);
        assert(!_lastChild || _lastChild.parent is this);
        assert(!_firstChild || _firstChild._prevSibling is null);
        assert(!_lastChild || _lastChild._nextSibling is null);

        assert(_childCount != 0 || (_firstChild is null && _lastChild is null));
        assert(_childCount == 0 || (_firstChild !is null && _lastChild !is null));
        assert(_childCount != 1 || (_firstChild is _lastChild));
        assert((_firstChild is null) == (_lastChild is null));

        assert(!_prevSibling || _prevSibling._nextSibling is this);
        assert(!_nextSibling || _nextSibling._prevSibling is this);
    }

    // graph
    private SgNode _parent;

    private size_t _childCount;
    private SgNode _firstChild;
    private SgNode _lastChild;

    private SgNode _prevSibling;
    private SgNode _nextSibling;

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

private:

/// Bidirectional range that traverses a sibling node list
struct SgSiblingNodeRange(NodeT)
{
    Rebindable!NodeT _first;
    Rebindable!NodeT _last;

    this (NodeT first, NodeT last)
    {
        _first = first;
        _last = last;
    }

    @property bool empty() { return _first is null; }
    @property NodeT front() { return _first; }
    void popFront() {
        if (_first is _last) {
            _first = null;
            _last = null;
        }
        else {
            _first = _first._nextSibling;
        }
    }

    @property auto save()
    {
        return SgSiblingNodeRange(_first, _last);
    }

    @property NodeT back() { return _last; }
    void popBack() {
        if (_first is _last) {
            _first = null;
            _last = null;
        }
        else {
            _last = _last._prevSibling;
        }
    }
}

static assert (isBidirectionalRange!(SgSiblingNodeRange!SgNode));
static assert (isBidirectionalRange!(SgSiblingNodeRange!(const(SgNode))));


unittest
{
    import std.algorithm : equal;

    auto root = new SgNode;
    auto c1 = new SgNode;
    auto c2 = new SgNode;
    root.name = "root";
    c1.name = "c1";
    c2.name = "c2";
    root.appendChild(c1);
    root.appendChild(c2);

    assert(c1.parent is root);
    assert(c2.parent is root);
    assert(root.firstChild is c1);
    assert(root.lastChild is c2);

    string[] names;
    foreach(c; root.children) {
        names ~= c.name;
    }
    assert(equal(names, ["c1", "c2"]));
}
