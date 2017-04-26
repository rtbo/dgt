module dgt.sg.parent;

import dgt.geometry;
import dgt.sg.node;
import dgt.render.node;
import dgt.window;

import std.exception;
import std.range;
import std.typecons;

class SgParent : SgNode
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

    /// A bidirectional range of this node's children
    @property auto children()
    {
        return SgSiblingNodeRange!SgNode(_firstChild, _lastChild);
    }

    /// ditto
    @property auto children() const
    {
        return SgSiblingNodeRange!(const(SgNode))(_firstChild, _lastChild);
    }

    /// Appends the given node to this node children list.
    protected void appendChild(SgNode node)
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
    protected void prependChild(SgNode node)
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
    protected void insertChildBefore(SgNode node, SgNode child)
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
    protected void removeChild(SgNode child)
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
        child.disposeResources();
        --_childCount;
    }

    override protected FRect computeBounds()
    {
        import std.algorithm : map;
        return computeRectsExtents(
            children.map!(c => c.transformedBounds)
        );
    }

    override protected FRect computeTransformedBounds()
    {
        import std.algorithm : map;
        if (!hasTransform) return computeBounds();
        immutable tr = transform;
        return computeRectsExtents(
            children.map!(c => transformBounds(c.transformedBounds, tr))
        );
    }

    override immutable(RenderNode) collectRenderNode()
    {
        import std.algorithm : filter, map;
        import std.array : array;
        if (!_childCount) return null;
        else return new immutable(GroupRenderNode)(
            bounds,
            children.map!(c => c.collectTransformedRenderNode())
                    .filter!(rn => rn !is null)
                    .array()
        );
    }

    override void disposeResources()
    {
        import std.algorithm : each;
        children.each!(c => c.disposeResources());
    }

    override string toString()
    {
        import std.array : array;
        import std.format : format;
        import std.range : repeat;
        auto indent = repeat(' ', level*4).array;
        string res = format("%s%s { %(%-(%s:%), %) ", indent, this.className, properties);
        if (hasChildren) {
            res ~= format("[\n");
            size_t ind=0;
            foreach(c; children) {
                res ~= c.toString();
                if (ind != _childCount-1) {
                    res ~= ",\n";
                }
                ++ind;
            }
            res ~= format("\n%s]", indent);
        }
        res ~= "}";
        return res;
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

        assert(!(_parent && _window)); // only root can hold the window ref
    }

    package(dgt) Window _window;
    private size_t _childCount;
    private SgNode _firstChild;
    private SgNode _lastChild;
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

    auto root = new SgGroup;
    auto c1 = new SgGroup;
    auto c2 = new SgGroup;
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
