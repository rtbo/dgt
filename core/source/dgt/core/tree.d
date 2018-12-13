/// Module that provide generic tree interface and utils
module dgt.core.tree;

interface TreeNode(NodeT) {
    /// The parent of this node, or null if this node is the root.
    @property NodeT parent();
    /// Whether this node is the root of the tree.
    final @property bool isRoot() {
        return parent is null;
    }
    /// The root of the tree
    @property NodeT root();
    /// Get the next sibling of this node.
    @property NodeT prevSibling();
    /// Get the previous sibling of this node.
    @property NodeT nextSibling();
    /// Get the first child of this node.
    @property NodeT firstChild();
    /// Get the last child of this node.
    @property NodeT lastChild();
}

auto treeChildren(NodeT)(NodeT node) {
    return siblingRange(node.firstChild, node.lastChild);
}

auto siblingRange(NodeT)(NodeT first, NodeT last) {
    return SiblingNodeRange!NodeT(first, last);
}

private:

/// Bidirectional range that traverses a sibling node list
struct SiblingNodeRange(NodeT)
{
    import std.typecons : Rebindable;

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
            _first = _first.nextSibling;
        }
    }

    @property auto save()
    {
        return SiblingNodeRange!NodeT(_first, _last);
    }

    @property NodeT back() { return _last; }
    void popBack() {
        if (_first is _last) {
            _first = null;
            _last = null;
        }
        else {
            _last = _last.prevSibling;
        }
    }
}
