/// Scene graph module
module dgt.sg.node;

import dgt.event;
import dgt.geometry;
import dgt.math;
import dgt.render;
import dgt.render.node;
import dgt.sg.style;
import dgt.window;

import std.exception;
import std.experimental.logger;
import std.range;
import std.typecons;

/// A node for a 2D scene-graph
class SgNode
{
    /// builds a new node
    this()
    {
        _onMouseDown        = new Handler!MouseEvent;
        _onMouseUp          = new Handler!MouseEvent;
        _onMouseDrag        = new Handler!MouseEvent;
        _onMouseMove        = new Handler!MouseEvent;
        _onMouseEnter       = new Handler!MouseEvent;
        _onMouseLeave       = new Handler!MouseEvent;
        _onMouseClick       = new Handler!MouseEvent;
        _onMouseDblClick    = new Handler!MouseEvent;
        _style = new Style(this);
    }

    /// The window this node is attached to.
    @property Window window()
    {
        return root._window;
    }

    /// The root of this scene graph
    @property SgNode root()
    {
        if (!_parent) return cast(SgNode)this;
        SgNode p = _parent;
        while (p._parent) p = p._parent;
        return p;
    }

    /// Whether this node is root
    @property bool isRoot() const
    {
        return _parent is null;
    }

    /// This node's parent.
    @property inout(SgNode) parent() inout
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
        --_childCount;
    }

    /// Invalidate the node content. This triggers rendering.
    final void invalidate()
    {
        if (window) window.invalidate(cast(IRect)sceneRect);
    }

    /// The dirtyState of this node;
    final @property DirtyFlags dirtyState()
    {
        return _dirtyState;
    }
    /// Set the passed flag dirty
    final void dirty(in DirtyFlags flags)
    {
        _dirtyState |= flags;
        if (flags & DirtyFlags.styleMask) {
            if (window) window.requestStylePass();
            invalidate();
        }
    }
    /// Reset some dirty flags
    final void clean(in DirtyFlags flags = DirtyFlags.all)
    {
        _dirtyState &= ~flags;
    }
    /// Checks whether one of the passed flags is dirty
    final bool isDirty(in DirtyFlags flags)
    {
        return (_dirtyState & flags) != DirtyFlags.clean;
    }
    /// Checks whether all of the passed flag are dirty
    final bool areDirty(in DirtyFlags flags)
    {
        return (_dirtyState & flags) == flags;
    }

    /// The position of the node relative to its parent.
    final @property FPoint pos() const
    {
        return _rect.point;
    }
    /// ditto
    final @property void pos(in FPoint pos)
    {
        if (pos != _rect.point) {
            _rect.point = pos;
            // _rect.point is included in parent and scene transforms
            dirty(DirtyFlags.transformMask);
        }
    }
    /// The size of the node
    final @property FSize size()
    {
        return _rect.size;
    }
    /// ditto
    final @property void size(in FSize size)
    {
        _rect.size = size;
    }
    /// The 'logical' rect of the node.
    /// This is expressed in parent coordinates, and do not take into account
    /// the transform applied to this node.
    /// Actual bounds may differ due to use of borders, shadows or transform.
    /// This rect is the one used in layout calculations.
    final @property FRect rect()
    {
        return _rect;
    }
    /// ditto
    final @property void rect(in FRect rect)
    {
        if (rect != _rect) {
            _rect = rect;
            // _rect.point is included in parent and scene transforms
            dirty(DirtyFlags.transformMask);
        }
    }

    /// Rect in local coordinates
    final @property FRect localRect()
    {
        return FRect(0, 0, size);
    }

    /// Position of this node as seen by parent, considering also
    /// the transform of this node.
    final @property FPoint parentPos()
    {
        return mapToParent(fvec(0, 0));
    }

    /// The rect of this node, as seen by parent, taking into account
    /// transform. A rect is always axis aligned, so in case of rotation,
    /// the bounding rect is returned.
    final @property FRect parentRect()
    {
        return mapToParent(localRect);
    }

    /// Position of this node as seen by scene, considering
    /// the whole transform chain.
    final @property FPoint scenePos()
    {
        return mapToScene(fvec(0, 0));
    }

    /// The rect of this node, as seen by scene, taking into account
    /// the whole transform chain. A rect is always axis aligned, so in case of rotation,
    /// the bounding rect is returned.
    final @property FRect sceneRect()
    {
        return mapToScene(localRect);
    }

    /// Whether this node has a transform set. (Other than identity)
    final @property bool hasTransform() const { return _hasTransform; }

    /// The transform affecting this node and its children.
    /// The transform does not affect the layout, but affects rendering.
    /// It should be used for animation mainly.
    final @property FMat4 transform() const { return _transform; }

    /// ditto
    final @property void transform(in FMat4 transform)
    {
        _transform = transform;
        _hasTransform = transform != FMat4.identity;
        dirty(DirtyFlags.transformMask);
    }

    final @property FMat4 parentTransform()
    {
        if (isDirty(DirtyFlags.transformParent)) {
            _parentTransform = _hasTransform ?
                    transform.translate(fvec(pos, 0)) :
                    translation!float(fvec(pos, 0));
            clean(DirtyFlags.transformParent);
        }
        return _parentTransform;
    }

    final @property FMat4 parentTransformInv()
    {
        if (isDirty(DirtyFlags.transformParentInv)) {
            _parentTransformInv = inverse(parentTransform);
            clean(DirtyFlags.transformParentInv);
        }
        return _parentTransformInv;
    }

    final @property FMat4 sceneTransform()
    {
        if (isDirty(DirtyFlags.transformScene)) {
            _sceneTransform = parent ?
                    parent.sceneTransform * parentTransform :
                    parentTransform;
            clean(DirtyFlags.transformScene);
        }
        return _sceneTransform;
    }

    final @property FMat4 sceneTransformInv()
    {
        if (isDirty(DirtyFlags.transformSceneInv)) {
            _sceneTransformInv = inverse(sceneTransform);
            clean(DirtyFlags.transformSceneInv);
        }
        return _sceneTransformInv;
    }

    /// Map a point from scene coordinates to this node coordinates
    final FPoint mapFromScene(in FPoint pos)
    {
        return fvec(pos, 0).transform(sceneTransformInv).xy;
    }

    /// Map a point from this node coordinates to scene coordinates
    final FPoint mapToScene(in FPoint pos)
    {
        return fvec(pos, 0).transform(sceneTransform).xy;
    }

    /// Map a point from parent coordinates to this node coordinates
    final FPoint mapFromParent(in FPoint pos)
    {
        return fvec(pos, 0).transform(parentTransformInv).xy;
    }

    /// Map a point from this node coordinates to parent coordinates
    final FPoint mapToParent(in FPoint pos)
    {
        return fvec(pos, 0).transform(parentTransform).xy;
    }

    /// Map a point from the other node coordinates to this node coordinates
    final FPoint mapFromNode(SgNode node, in FPoint pos)
    {
        immutable sp = node.mapToScene(pos);
        return mapFromScene(sp);
    }

    /// Map a point from this node coordinates to the other node coordinates
    final FPoint mapToNode(SgNode node, in FPoint pos)
    {
        immutable sp = mapToScene(pos);
        return node.mapFromScene(sp);
    }

    /// Map a point from scene coordinates to this node coordinates
    final FRect mapFromScene(in FRect rect)
    {
        return rect.transformBounds(sceneTransformInv);
    }

    /// Map a point from this node coordinates to scene coordinates
    final FRect mapToScene(in FRect rect)
    {
        return rect.transformBounds(sceneTransform);
    }

    /// Map a point from parent coordinates to this node coordinates
    final FRect mapFromParent(in FRect rect)
    {
        return rect.transformBounds(parentTransformInv);
    }

    /// Map a point from this node coordinates to parent coordinates
    final FRect mapToParent(in FRect rect)
    {
        return rect.transformBounds(parentTransform);
    }

    /// Map a point from the other node coordinates to this node coordinates
    final FRect mapFromNode(SgNode node, in FRect rect)
    {
        return rect.transformBounds(
            node.sceneTransform * sceneTransformInv
        );
    }

    /// Map a point from this node coordinates to the other node coordinates
    final FRect mapToNode(SgNode node, in FRect rect)
    {
        return rect.transformBounds(
            sceneTransform * node.sceneTransformInv
        );
    }

    /// Get a node at position given by pos.
    SgNode nodeAtPos(in FVec2 pos)
    {
        if (localRect.contains(pos)) {
            foreach (c; children) {
                immutable cp = c.mapFromParent(pos);
                auto res = c.nodeAtPos(cp);
                if (res) return res;
            }
            return this;
        }
        else {
            return null;
        }
    }

    /// Recursively append nodes that are located at pos from root to end target.
    void nodesAtPos(in FVec2 pos, ref SgNode[] nodes)
    {
        if (localRect.contains(pos)) {
            nodes ~= this;
            foreach (c; children) {
                immutable cp = c.mapFromParent(pos);
                c.nodesAtPos(cp, nodes);
            }
        }
    }

    /// The Style object attached to this node
    @property Style style()
    {
        return _style;
    }

    /// A CSS formatted style attached to this node.
    /// It can be either rules with a selector, or only declarations.
    /// In the latter case, a single * selector is implied
    /// (if '{' is not found in the passed string, it is assumed to be only declarations).
    /// The rules attached here are scoped to this node and its children.
    @property string cssStyle() { return _cssStyle; }
    /// ditto
    @property void cssStyle(string css)
    {
        import std.algorithm : canFind;
        if (!css.canFind("{")) {
            css = "*{"~css~"}";
        }
        if (css != _cssStyle) {
            _cssStyle = css;
            dirty(DirtyFlags.css);
        }
    }

    /// The type used in css type selector.
    /// e.g. in the following style rule, "label" is the CSS type:
    /// `label { font-family: serif; }`
    @property string cssType() { return null; }

    /// The id of this node.
    /// Used in CSS '#' selector, and for debug printing if name is not set.
    final @property string id() { return _id; }
    /// ditto
    final @property void id(in string id)
    {
        if (id != _id) {
            _id = id;
            dirty(DirtyFlags.css);
        }
    }

    /// The CSS class of this node.
    /// Used in CSS '.' selector.
    final @property string cssClass() { return _cssClass; }
    /// ditto
    final @property void cssClass(in string cssClass)
    {
        if (cssClass != _cssClass) {
            _cssClass = cssClass;
            dirty(DirtyFlags.css);
        }
    }

    /// A pseudo state of the node.
    final @property PseudoState pseudoState() { return _pseudoState; }
    /// ditto
    final @property void pseudoState(in PseudoState state)
    {
        if (state != _pseudoState) {
            _pseudoState = state;
            dirty(DirtyFlags.dynStyle);
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
    final void hoverSensitive(in bool hs) { _hoverSensitive = hs; }

    /// Give possibility to filter any event passing by
    /// To effectively filter an event, the filter delegate must consume it.
    /// Params:
    ///     filter  =   a filter delegate
    ///     mask    =   a bitwise mask that will be used to test if a filter
    ///                 applies to a given event type
    /// Returns: the filter given as parameter. Can be used for later uninstall.
    final EventFilter addEventFilter(EventFilter filter, EventType mask=EventType.allMask)
    {
        _evFilters ~= MaskedFilter(filter, mask);
        return filter;
    }

    /// Remove an install event filter.
    final void removeEventFilter(EventFilter filter)
    {
        import std.algorithm : remove;
        _evFilters = _evFilters.remove!(f => f.filter is filter);
    }

    /// Remove installed event filters whose mask have an intersection with given mask.
    final void removeEventFilters(EventType mask)
    {
        import std.algorithm : remove;
        _evFilters = _evFilters.remove!(f => (f.mask & cast(uint)mask) != 0);
    }

    /// Activated when user clicks on this node
    final @property void onMouseDown(Slot!MouseEvent slot)
    {
        _onMouseDown.set(slot);
    }
    /// ditto
    final protected @property Handler!MouseEvent onMouseDown()
    {
        return _onMouseDown;
    }
    /// ditto
    final @property void onMouseUp(Slot!MouseEvent slot)
    {
        _onMouseUp.set(slot);
    }
    /// ditto
    final protected @property Handler!MouseEvent onMouseUp()
    {
        return _onMouseUp;
    }
    /// ditto
    final @property void onMouseDrag(Slot!MouseEvent slot)
    {
        _onMouseDrag.set(slot);
    }
    /// ditto
    final protected @property Handler!MouseEvent onMouseDrag()
    {
        return _onMouseDrag;
    }
    /// ditto
    final @property void onMouseMove(Slot!MouseEvent slot)
    {
        _onMouseMove.set(slot);
    }
    /// ditto
    final protected @property Handler!MouseEvent onMouseMove()
    {
        return _onMouseMove;
    }
    /// ditto
    final @property void onMouseEnter(Slot!MouseEvent slot)
    {
        _onMouseEnter.set(slot);
    }
    /// ditto
    final protected @property Handler!MouseEvent onMouseEnter()
    {
        return _onMouseEnter;
    }
    /// ditto
    final @property void onMouseLeave(Slot!MouseEvent slot)
    {
        _onMouseLeave.set(slot);
    }
    /// ditto
    final protected @property Handler!MouseEvent onMouseLeave()
    {
        return _onMouseLeave;
    }
    /// ditto
    final @property void onMouseClick(Slot!MouseEvent slot)
    {
        _onMouseClick.set(slot);
    }
    /// ditto
    final protected @property Handler!MouseEvent onMouseClick()
    {
        return _onMouseClick;
    }
    /// ditto
    final @property void onMouseDblClick(Slot!MouseEvent slot)
    {
        _onMouseDblClick.set(slot);
    }
    /// ditto
    final protected @property Handler!MouseEvent onMouseDblClick()
    {
        return _onMouseDblClick;
    }

    /// Chain an event until its final target, giving each parent in the chain
    /// the opportunity to filter it, or to handle it after its children if
    /// the event hasn't been consumed by any of them.
    /// Returns: the node that has consumed the event, or null.
    final SgNode chainEvent(Event event)
    {
        // fiter phase
        if (filterEvent(event)) return this;

        // chaining phase
        if (event.nodeChain.length) {
            auto res = event.chainToNext();
            if (res) return res;
        }

        // bubbling phase
        if (handleEvent(event)) return this;
        else return null;
    }

    final protected bool filterEvent(Event event)
    {
        immutable type = event.type;
        foreach (ref f; _evFilters) {
            if (f.mask & type) {
                f.filter(event);
                if (event.consumed) return true;
            }
        }
        return false;
    }

    final protected bool handleEvent(Event event)
    {
        immutable et = event.type;
        if (et & EventType.mouseMask) {
            auto mev = cast(MouseEvent)event;
            switch (et) {
            case EventType.mouseDown:
                onMouseDown.fire(mev);
                break;
            case EventType.mouseUp:
                onMouseUp.fire(mev);
                break;
            case EventType.mouseDrag:
                onMouseDrag.fire(mev);
                break;
            case EventType.mouseMove:
                onMouseMove.fire(mev);
                break;
            case EventType.mouseEnter:
                if (_hoverSensitive) {
                    addPseudoState(PseudoState.hover);
                }
                onMouseEnter.fire(mev);
                break;
            case EventType.mouseLeave:
                onMouseLeave.fire(mev);
                if (_hoverSensitive) {
                    remPseudoState(PseudoState.hover);
                }
                break;
            case EventType.mouseClick:
                onMouseClick.fire(mev);
                break;
            case EventType.mouseDblClick:
                onMouseDblClick.fire(mev);
                break;
            default:
                break;
            }
        }
        return event.consumed;
    }


    /// Whether this node is dynamic.
    /// Dynamic basically means that the rendering data can vary
    /// about every frame. Whether the transform changes at every frame
    /// or not should not influence this flag.
    /// This flag mainly impacts caching policy.
    @property bool dynamic() const { return _dynamic; }

    /// ditto
    @property void dynamic(bool dynamic)
    {
        _dynamic = dynamic;
    }

    /// background render node in local coordinates
    immutable(RenderNode) backgroundRenderNode()
    {
        immutable col = style.backgroundColor;
        if (col.argb & 0xff000000) {
            return new immutable RectFillRenderNode(col.asVec, localRect);
        }
        else {
            return null;
        }
    }

    /// Collect the render node for this node, in local coordinates.
    /// It is responsibility of the parent to transform this render node into the
    /// parent coordinates.
    /// Returns: A render for this node, expressed in local coordinates.
    immutable(RenderNode) collectRenderNode()
    {
        import std.algorithm : map;
        import std.array : array;
        import std.typecons : rebindable;

        if (hasChildren) {
            immutable nodes = children .map!((SgNode c) {
                immutable bg = c.backgroundRenderNode();
                immutable cn = c.collectRenderNode();

                immutable RenderNode rn = bg ?
                    new immutable GroupRenderNode(bg.bounds, [bg, cn]) :
                    cn;

                return new immutable TransformRenderNode(
                    c.parentTransform, rn
                );
            }).array();
            return new immutable GroupRenderNode(
                localRect, nodes
            );
        }
        else {
            return null;
        }
    }

    @property uint level() const
    {
        Rebindable!(const(SgNode)) p = parent;
        uint lev=0;
        while (p !is null) {
            ++lev;
            p = p.parent;
        }
        return lev;
    }

    @property string name() const
    {
        return _name.length ? _name : _id;
    }
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
        props ~= ["rect", format("%s", rect)];
        return props;
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

    private static struct MaskedFilter
    {
        EventFilter filter;
        uint mask;
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

    // graph
    package(dgt) Window _window;

    private SgNode _parent;

    private SgNode _prevSibling;
    private SgNode _nextSibling;

    private size_t _childCount;
    private SgNode _firstChild;
    private SgNode _lastChild;

    // dirty state
    private DirtyFlags _dirtyState;

    // bounds
    private FRect  _rect;

    // transform
    private FMat4 _transform            = FMat4.identity;
    private FMat4 _parentTransform      = FMat4.identity;
    private FMat4 _parentTransformInv   = FMat4.identity;
    private FMat4 _sceneTransform       = FMat4.identity;
    private FMat4 _sceneTransformInv    = FMat4.identity;
    private bool _hasTransform;

    // style
    private Style _style;
    private string _cssStyle;
    private string _id;
    private string _cssClass;
    private PseudoState _pseudoState;
    private bool _hoverSensitive;

    // events
    private MaskedFilter[] _evFilters;
    private Handler!MouseEvent _onMouseDown;
    private Handler!MouseEvent _onMouseUp;
    private Handler!MouseEvent _onMouseMove;
    private Handler!MouseEvent _onMouseDrag;
    private Handler!MouseEvent _onMouseEnter;
    private Handler!MouseEvent _onMouseLeave;
    private Handler!MouseEvent _onMouseClick;
    private Handler!MouseEvent _onMouseDblClick;

    // cache policy
    private bool _dynamic=false;

    // debug info
    private string _name; // id will be used if name is empty
}


/// Bit flags that describe what in a node needs update
enum DirtyFlags
{
    /// nothing is dirty
    clean       = 0,

    /// transform were changed
    transformMask       = 0x000f,
    /// ditto
    transformParent     = 0x0001,
    /// ditto
    transformParentInv  = 0x0002,
    /// ditto
    transformScene      = 0x0004,
    /// ditto
    transformSceneInv   = 0x0008,

    /// A style pass is needed
    styleMask           = 0x0300,
    /// Dynamic pseudo class has to be enabled/disabled.
    dynStyle            = 0x0100,
    /// A css string has been updated/set/reset.
    css                 = 0x0200,

    /// All bits set
    all                 = 0xffff_ffff,
}

/// Testing scene graph relationship
unittest
{
    import dgt.widget.group : Group;
    import std.algorithm : equal;

    auto root = new Group;
    auto c1 = new Group;
    auto c2 = new Group;
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

/// Testing coordinates transforms
unittest {
    import dgt.math.approx : approxUlp, approxUlpAndAbs;
    import dgt.widget.group : Group;

    auto root = new Group;
    auto child1 = new Group;
    auto subchild = new Group;
    auto child2 = new Group;

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

/// The runtime class name of obj.
@property string className(Object obj)
{
    import std.algorithm : splitter;
    return typeid(obj).toString().splitter('.').back;
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
