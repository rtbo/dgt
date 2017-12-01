module dgt.scene.node;

import dgt.core.geometry;
import dgt.css.style;
import dgt.scene.scene;

import std.exception : enforce;

class Node : StyleElement {
    /// The scene this node is attached to.
    @property Scene scene()
    {
        return root._scene;
    }

    /// The root of this scene graph
    @property Node root()
    {
        if (!_parent) return this;
        Node p = _parent;
        while (p._parent) p = p._parent;
        return p;
    }

    /// Whether this node is root
    @property bool isRoot() const
    {
        return _parent is null;
    }

    /// This node's parent.
    @property Node parent()
    {
        return _parent;
    }

    /// This node's previous sibling.
    @property Node prevSibling()
    {
        return _prevSibling;
    }

    /// This node's next sibling.
    @property Node nextSibling()
    {
        return _nextSibling;
    }

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
    @property inout(Node) firstChild() inout
    {
        return _firstChild;
    }

    /// This node's last child.
    @property inout(Node) lastChild() inout
    {
        return _lastChild;
    }

    /// A bidirectional range of this node's children
    @property auto children()
    {
        return SgSiblingNodeRange!Node(_firstChild, _lastChild);
    }

    /// ditto
    @property auto children() const
    {
        return SgSiblingNodeRange!(const(Node))(_firstChild, _lastChild);
    }

    /// Appends the given node to this node children list.
    protected void appendChild(Node node)
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
    protected void prependChild(Node node)
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
    protected void insertChildBefore(Node node, Node child)
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
    protected void removeChild(Node child)
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
    override @property string inlineCSS() { return _inlineCSS; }
    /// Set the inline CSS
    @property void inlineCSS(string css)
    {
        if (css != _inlineCSS) {
            _inlineCSS = css;
        }
    }

    override @property string css() { return _css; }
    /// Set the CSS stylesheet.
    /// Can be set without surrounding rules, in such case, the declarations
    /// are surrdounding by a universal selector.
    @property void css(string css)
    {
        import std.algorithm : canFind;
        if (!css.canFind('{')) {
            css = "*{"~css~"}";
        }
        if (css != _css) {
            _css = css;
        }
    }

    /// The type used in css type selector.
    /// e.g. in the following style rule, "label" is the CSS type:
    /// `label { font-family: serif; }`
    override @property string cssType() { return null; }

    /// The id of this view.
    /// Used in CSS '#' selector, and for debug printing if name is not set.
    override final @property string id() { return _id; }
    /// ditto
    final @property void id(in string id)
    {
        if (id != _id) {
            _id = id;
        }
    }

    /// The CSS class of this view.
    /// Used in CSS '.' selector.
    override final @property string cssClass() { return _cssClass; }
    /// ditto
    final @property void cssClass(in string cssClass)
    {
        if (cssClass != _cssClass) {
            _cssClass = cssClass;
        }
    }

    /// A pseudo state of the view.
    override final @property PseudoState pseudoState() { return _pseudoState; }
    /// ditto
    final @property void pseudoState(in PseudoState state)
    {
        if (state != _pseudoState) {
            _pseudoState = state;
        }
    }
    /// ditto
    final void addPseudoState(in PseudoState flags)
    {
        pseudoState = _pseudoState | flags;
    }
    /// ditto
    final void remPseudoState(in PseudoState flags)
    {
        pseudoState = _pseudoState & (~flags);
    }

    /// Flag that causes PseudoState.hover to be set when the cursor hovers the view
    final bool hoverSensitive() { return _hoverSensitive; }
    /// ditto
    final void hoverSensitive(in bool hs)
    {
        if (!_hoverSensitive == hs) {
            _hoverSensitive = hs;
        }
    }

    override @property FSize viewportSize()
    {
        auto sc = scene;
        return sc ? cast(FSize)sc.size : FSize(0, 0);
    }

    override @property float dpi()
    {
        // FIXME: get actual dpi
        return 96f;
    }

    @property IStyleMetaProperty[] styleMetaProperties()
    {
        return _styleMetaProperties;
    }

    IStyleProperty styleProperty(string name) {
        auto sp = name in _styleProperties;
        return sp ? *sp : null;
    }

    @property string name() {
        return _name.length ? _name : _id;
    }

    @property void name(string value) {
        _name = value;
    }

    private Scene _scene;

    private Node _parent;
    private Node _prevSibling;
    private Node _nextSibling;
    private Node _firstChild;
    private Node _lastChild;
    private size_t _childCount;

    // style
    private string _css;
    private string _inlineCSS;
    private string _id;
    private string _cssClass;
    private PseudoState _pseudoState;
    private bool _hoverSensitive;
    // style properties
    private IStyleMetaProperty[]        _styleMetaProperties;
    private IStyleProperty[string]      _styleProperties;

    // debug
    private string _name;
}


/// Testing scene graph relationship
unittest
{
    import std.algorithm : equal;

    auto root = new Node;
    auto c1 = new Node;
    auto c2 = new Node;
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


private:

/// Bidirectional range that traverses a sibling view list
struct SgSiblingNodeRange(NodeT)
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

import std.range : isBidirectionalRange;

static assert (isBidirectionalRange!(SgSiblingNodeRange!Node));
static assert (isBidirectionalRange!(SgSiblingNodeRange!(const(Node))));
