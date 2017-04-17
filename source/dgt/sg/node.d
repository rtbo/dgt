module dgt.sg.node;

import dgt.sg.rendernode;
import dgt.geometry;
import dgt.math;

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

    abstract immutable(RenderNode) collectRenderNode();

    protected immutable(RenderNode) collectChildrenRenderNodes()
    {
        import std.algorithm : map;
        import std.array : array;
        if (!_childCount) return null;
        else return new immutable(GroupRenderNode)(
            childrenBounds,
            children.map!(c => c.collectRenderNode())
                    .array()
        );
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

    private SgNode _parent;

    private size_t _childCount;
    private SgNode _firstChild;
    private SgNode _lastChild;

    private SgNode _prevSibling;
    private SgNode _nextSibling;

    FRect _bounds;
    FRect _screenBounds;
    FRect _childrenBounds;

    FMat4 _transform = FMat4.identity;
    bool _hasTransform;
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

    @property bool empty() { return _first !is null; }
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
