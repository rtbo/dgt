module dgt.scene.node;

import dgt.core.geometry;
import dgt.core.tree;
import dgt.css.style;
import dgt.math.mat : FMat4, inverse;
import dgt.math.transform : transform, translate, translation;
import dgt.scene.scene;

import std.algorithm : map;
import std.exception : enforce;

/// Base class for all nodes in the scene graph.
class Node : StyleElement {
    /// The scene this node is attached to.
    @property Scene scene()
    {
        return root._scene;
    }

    /// The root of this scene graph
    override @property Node root()
    {
        if (!_parent) return this;
        Node p = _parent;
        while (p._parent) p = p._parent;
        return p;
    }

    /// This node's parent.
    override @property Node parent()
    {
        return _parent;
    }

    /// This node's previous sibling.
    override @property Node prevSibling()
    {
        return _prevSibling;
    }

    /// This node's next sibling.
    override @property Node nextSibling()
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
    override @property Node firstChild()
    {
        return _firstChild;
    }

    /// This node's last child.
    override @property Node lastChild()
    {
        return _lastChild;
    }

    /// A bidirectional range of this node's children
    @property auto children()
    {
        return siblingRange!Node(_firstChild, _lastChild);
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


    /// Invalidate the node rendering. This triggers rendering.
    final void invalidate()
    {
        dirty(Dirty.render);
    }

    /// The dirtyState of this node.
    final @property Dirty dirtyState()
    {
        return _dirtyState;
    }
    /// Set the passed flag dirty
    final void dirty(in Dirty flags)
    {
        _dirtyState |= flags;

        enum mask = Dirty.styleMask | Dirty.layoutMask | Dirty.renderMask;
        if ((flags & mask) == Dirty.clean) return;

        auto sc = scene;

        if (flags & Dirty.styleMask) {
            if (flags & Dirty.style && sc)
                sc.requestPass(ScenePass.style);
            if (parent) parent.dirty(Dirty.childrenStyle);
        }
        if (flags & Dirty.layoutMask) {
            if (flags & Dirty.layout && sc)
                sc.requestPass(ScenePass.layout);
            if (parent) parent.dirty(Dirty.childrenLayout);
        }
        if (flags & Dirty.renderMask) {
            if (flags & Dirty.render && sc)
                sc.requestPass(ScenePass.render);
            if (parent) parent.dirty(Dirty.childrenRender);
        }
    }
    /// Reset some dirty flags
    final void clean(in Dirty flags)
    {
        _dirtyState &= ~flags;

        if (!parent) return;

        if ((flags & Dirty.render && !isDirty(Dirty.childrenRender)) ||
                (flags & Dirty.childrenRender && !isDirty(Dirty.childrenRender))) {
            parent.clean(Dirty.childrenRender);
        }
    }
    package(dgt) void recursClean(in Dirty flags)
    {
        _dirtyState &= ~flags;
        import std.algorithm : each;
        children.each!(c => c.recursClean(flags));
    }
    /// Checks whether one of the passed flags is dirty
    final bool isDirty(in Dirty flags)
    {
        return (_dirtyState & flags) != Dirty.clean;
    }
    /// Checks whether all of the passed flag are dirty
    final bool areDirty(in Dirty flags)
    {
        return (_dirtyState & flags) == flags;
    }


    /// Return the bounds of this node in parent coordinates.
    /// The transform this node does not affect the bounds.
    final @property FRect bounds() {
        if (hasPrivDirty(PrivDirty.bounds)) {
            _bounds = computeBounds();
        }
        return _bounds;
    }

    /// The bounds of this node in parent coordinates, with the transform applied.
    final @property FRect boundsAfterTransform() {
        const b = bounds;
        if (_hasTransform) {
            return transformBounds(b, _transform);
        }
        else {
            return b;
        }
    }

    /// Mark the bounds dirty to trigger recomputation.
    void dirtyBounds() {
        privDirty(PrivDirty.bounds);
        dirty(Dirty.transformMask);
    }

    /// Subclass can inherit this to compute their bounds.
    /// Calculation must not take into account the bounds of this node.
    /// Default implementation compute the extents of all children bounds after
    /// their respective transform. If this node has no children, FRect.init is returned.
    FRect computeBounds() {
        return computeRectsExtents(children.map!(c => c.boundsAfterTransform));
    }


    /// Whether this node has a transform set. (Other than identity)
    final @property bool hasTransform() const { return _hasTransform; }

    /// The transform affecting this node and its children.
    /// The transform does not affect the bounds nor layout, but affects rendering.
    /// It should be used for animation mainly.
    final @property FMat4 transform() const { return _transform; }

    /// ditto
    final @property void transform(in FMat4 transform)
    {
        _transform = transform;
        _hasTransform = transform != FMat4.identity;
        dirty(Dirty.transformMask | Dirty.render);
    }

    /// Transform that maps node coordinates to parent coordinates
    final @property FMat4 transformToParent()
    {
        if (isDirty(Dirty.transformToParent)) {
            const pos = bounds.topLeft;
            if (_hasTransform) {
                _transformToParent = transform.translate(fvec(pos, 0));
            }
            else {
                _transformToParent = translation!float(fvec(pos, 0));
                // this is cheap, let's do it now.
                _transformFromParent = translation!float(fvec(-pos, 0));
                clean(Dirty.transformFromParent);
            }
            clean(Dirty.transformToParent);
        }
        return _transformToParent;
    }

    /// Transform that maps parent coordinates to node coordinates
    final @property FMat4 transformFromParent()
    {
        if (isDirty(Dirty.transformFromParent)) {
            if (_hasTransform) {
                _transformFromParent = inverse(transformToParent);
            }
            else {
                const pos = bounds.topLeft;
                _transformFromParent = translation!float(fvec(-pos, 0));
                // this is cheap, let's do it now.
                _transformToParent = translation!float(fvec(pos, 0));
                clean(Dirty.transformToParent);
            }
            clean(Dirty.transformFromParent);
        }
        return _transformFromParent;
    }

    /// Transform that maps node coordinates to scene coordinates
    final @property FMat4 transformToScene()
    {
        if (isDirty(Dirty.transformToScene)) {
            _transformToScene = parent ?
                    parent.transformToScene * transformToParent :
                    transformToParent;
            clean(Dirty.transformToScene);
        }
        return _transformToScene;
    }

    /// Transform that maps scene coordinates to node coordinates
    final @property FMat4 transformFromScene()
    {
        if (isDirty(Dirty.transformFromScene)) {
            _transformFromScene = inverse(transformToScene);
            clean(Dirty.transformFromScene);
        }
        return _transformFromScene;
    }

    /// Map a point from scene coordinates to this node coordinates
    final FPoint mapFromScene(in FPoint pos)
    {
        return fvec(pos, 0).transform(transformFromScene).xy;
    }

    /// Map a point from this node coordinates to scene coordinates
    final FPoint mapToScene(in FPoint pos)
    {
        return fvec(pos, 0).transform(transformToScene).xy;
    }

    /// Map a point from parent coordinates to this node coordinates
    final FPoint mapFromParent(in FPoint pos)
    {
        return fvec(pos, 0).transform(transformFromParent).xy;
    }

    /// Map a point from this node coordinates to parent coordinates
    final FPoint mapToParent(in FPoint pos)
    {
        return fvec(pos, 0).transform(transformToParent).xy;
    }

    /// Map a point from the other node coordinates to this node coordinates
    final FPoint mapFromNode(Node node, in FPoint pos)
    {
        immutable sp = node.mapToScene(pos);
        return mapFromScene(sp);
    }

    /// Map a point from this node coordinates to the other node coordinates
    final FPoint mapToNode(Node node, in FPoint pos)
    {
        immutable sp = mapToScene(pos);
        return node.mapFromScene(sp);
    }

    /// Map a point from scene coordinates to this node coordinates
    final FRect mapFromScene(in FRect rect)
    {
        return rect.transformBounds(transformFromScene);
    }

    /// Map a point from this node coordinates to scene coordinates
    final FRect mapToScene(in FRect rect)
    {
        return rect.transformBounds(transformToScene);
    }

    /// Map a point from parent coordinates to this node coordinates
    final FRect mapFromParent(in FRect rect)
    {
        return rect.transformBounds(transformFromParent);
    }

    /// Map a point from this node coordinates to parent coordinates
    final FRect mapToParent(in FRect rect)
    {
        return rect.transformBounds(transformToParent);
    }

    /// Map a point from the other node coordinates to this node coordinates
    final FRect mapFromNode(Node node, in FRect rect)
    {
        return rect.transformBounds(
            node.transformToScene * transformFromScene
        );
    }

    /// Map a point from this node coordinates to the other node coordinates
    final FRect mapToNode(Node node, in FRect rect)
    {
        return rect.transformBounds(
            transformToScene * node.transformFromScene
        );
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

    /// The id of this node.
    /// Used in CSS '#' selector, and for debug printing if name is not set.
    override final @property string id() { return _id; }
    /// ditto
    final @property void id(in string id)
    {
        if (id != _id) {
            _id = id;
        }
    }

    /// The CSS class of this node.
    /// Used in CSS '.' selector.
    override final @property string cssClass() { return _cssClass; }
    /// ditto
    final @property void cssClass(in string cssClass)
    {
        if (cssClass != _cssClass) {
            _cssClass = cssClass;
        }
    }

    /// A pseudo state of the node.
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

    /// Flag that causes PseudoState.hover to be set when the cursor hovers the node
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

    override @property IStyleMetaProperty[] styleMetaProperties()
    {
        return _styleMetaProperties;
    }

    override IStyleProperty styleProperty(string name) {
        auto sp = name in _styleProperties;
        return sp ? *sp : null;
    }

    override @property bool isStyleDirty() {
        return isDirty(Dirty.style);
    }

    override @property bool hasChildrenStyleDirty() {
        return isDirty(Dirty.childrenStyle);
    }

    /// Get the name of this node, or its id if name is not set.
    /// For debug purpose only.
    @property string name() {
        return _name.length ? _name : _id;
    }

    /// Set the name of this node.
    /// For debug purpose only.
    @property void name(string value) {
        _name = value;
    }

    /// Bit flags that describe what in a node needs update
    enum Dirty
    {
        /// nothing is dirty
        clean               = 0,

        /// A style pass is needed
        styleMask           = style | childrenStyle,
        /// Style has changed for this node.
        /// This includes: id, class, pseudo-class and of course rules.
        style               = 0x0010,
        /// One children or descendant has its style dirty.
        childrenStyle       = 0x0020,

        /// A render pass is needed
        renderMask          = render | childrenRender,
        /// Content is dirty
        render              = 0x0040,
        /// One or more descendant have dirty content
        childrenRender      = 0x0080,

        /// transform was changed
        transformMask       = 0x0f00,
        /// ditto
        transformToParent   = 0x0100,
        /// ditto
        transformFromParent = 0x0200,
        /// ditto
        transformToScene    = 0x0400,
        /// ditto
        transformFromScene  = 0x0800,

        /// A layout pass is needed
        layoutMask          = layout | childrenLayout,
        /// layout was changed
        layout              = 0x1000,
        /// One or more descendant have dirty layout
        childrenLayout      = 0x2000,

        /// All bits set
        all                 = 0xffff_ffff,
    }

    private enum PrivDirty {
        clean = 0,
        bounds = 1,
        all = 0xffff_ffff
    }

    private void privDirty(in PrivDirty flags) {
        _privDirty |= flags;
    }
    private void privClean(in PrivDirty flags) {
        _privDirty &= (~flags);
    }
    private bool hasPrivDirty(in PrivDirty flags) {
        return (_privDirty & flags) != PrivDirty.clean;
    }
    private bool arePrivDirty(in PrivDirty flags) {
        return (_privDirty & flags) == flags;
    }


    package(dgt.scene) Scene _scene;

    private Node _parent;
    private Node _prevSibling;
    private Node _nextSibling;
    private Node _firstChild;
    private Node _lastChild;
    private size_t _childCount;

    // dirty state
    private Dirty _dirtyState;
    private PrivDirty  _privDirty;

    // bounds
    private FRect  _bounds;

    // transform
    private FMat4 _transform            = FMat4.identity;
    private FMat4 _transformToParent      = FMat4.identity;
    private FMat4 _transformFromParent   = FMat4.identity;
    private FMat4 _transformToScene       = FMat4.identity;
    private FMat4 _transformFromScene    = FMat4.identity;
    private bool _hasTransform;

    // style
    private string _css;
    private string _inlineCSS;
    private string _id;
    private string _cssClass;
    private PseudoState _pseudoState;
    private bool _hoverSensitive;
    // style properties
    package(dgt.scene) IStyleMetaProperty[]        _styleMetaProperties;
    package(dgt.scene) IStyleProperty[string]      _styleProperties;

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

version(unittest) {
    class TestRectNode : Node {
        @property FRect rect() {
            return _rect;
        }
        @property void rect(in FRect value) {
            _rect = value;
            dirtyBounds();
        }
        override FRect computeBounds() {
            return _rect;
        }

        private FRect _rect;
    }
}

/// Testing coordinates transforms
unittest {
    import dgt.math.approx : approxUlp, approxUlpAndAbs;

    auto root = new TestRectNode;
    auto child1 = new TestRectNode;
    auto subchild = new TestRectNode;
    auto child2 = new TestRectNode;

    root.rect = FRect(0, 0, 100, 100);
    child1.rect = FRect(20, 20, 60, 40);
    subchild.rect = FRect(5, 5, 40, 25);
    child2.rect = FRect(10, 80, 90, 10);

    root.appendChild(child1);
    root.appendChild(child2);
    child1.appendChild(subchild);

    immutable p = fvec(10, 10);

    assert(approxUlp(child1.mapFromParent(p),   fvec(-10, -10)));
    assert(approxUlp(child1.mapFromScene(p),    fvec(-10, -10)));
    assert(approxUlp(child1.mapToParent(p),     fvec( 30,  30)));
    assert(approxUlp(child1.mapToScene(p),      fvec( 30,  30)));

    assert(approxUlp(child2.mapFromParent(p),   fvec(  0, -70)));
    assert(approxUlp(child2.mapFromScene(p),    fvec(  0, -70)));
    assert(approxUlp(child2.mapToParent(p),     fvec( 20,  90)));
    assert(approxUlp(child2.mapToScene(p),      fvec( 20,  90)));

    assert(approxUlp(subchild.mapFromParent(p), fvec(  5,   5)));
    assert(approxUlp(subchild.mapFromScene(p),  fvec(-15, -15)));
    assert(approxUlp(subchild.mapToParent(p),   fvec( 15,  15)));
    assert(approxUlp(subchild.mapToScene(p),    fvec( 35,  35)));

    assert(approxUlp(subchild.mapToNode(child2, p),     fvec( 25,  -45)));
    assert(approxUlp(subchild.mapFromNode(child2, p),   fvec( -5,  65)));
}
