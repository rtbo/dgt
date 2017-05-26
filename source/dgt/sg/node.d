/// Scene graph module
module dgt.sg.node;

import dgt.event;
import dgt.geometry;
import dgt.math;
import dgt.render;
import dgt.render.node;
import dgt.sg.parent;
import dgt.sg.style;
import dgt.window;

import std.exception;
import std.experimental.logger;
import std.typecons;

/// Bit flags that describe what in a node needs update
enum DirtyFlags
{
    /// nothing is dirty
    clean       = 0,
    /// A style pass is needed
    styleMask   = 0x1000,
    /// Dynamic pseudo class has to be enabled/disabled.
    dynStyle    = 0x0100 | styleMask,
    /// A css string has been updated/set/reset.
    css         = 0x0200 | styleMask,

    /// All bits set
    all         = 0xffff_ffff,
}


/// A node for a 2D scene-graph
abstract class SgNode
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

    /// Invalidate the node content. This triggers rendering.
    final void invalidate()
    {
        if (window) window.invalidate(cast(IRect)sceneBounds);
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

    /// The position of the node relative to its parent.
    @property FPoint pos() const
    {
        return _pos;
    }
    /// ditto
    @property void pos(in FPoint pos)
    {
        _pos = pos;
        dirtyBounds();
    }

    /// Get a node at position given by pos.
    SgNode nodeAtPos(in FVec2 pos)
    {
        if (FRect(0f, 0f, bounds.size).contains(pos)) {
            return this;
        }
        else {
            return null;
        }
    }

    /// Recursively append nodes that are located at pos from root to end target.
    void nodesAtPos(in FVec2 pos, ref SgNode[] nodes)
    {
        if (FRect(0f, 0f, bounds.size).contains(pos)) {
            nodes ~= this;
        }
    }

    /// The bounds of this nodes in parent node coordinates.
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

    /// Position of this node in scene coordinates
    @property FPoint scenePos()
    {
        auto point = pos;
        auto p = parent;
        while (p) {
            point += p.pos;
            p = p.parent;
        }
        return point;
    }

    /// Bounds of this node in scene coordinates
    @property FRect sceneBounds()
    {
        return FRect(scenePos, bounds.size);
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
                onMouseEnter.fire(mev);
                break;
            case EventType.mouseLeave:
                onMouseLeave.fire(mev);
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

    /// Collect transformed render node for this node
    immutable(RenderNode) collectTransformedRenderNode()
    {
        immutable toBeTransformed = collectRenderNode();
        if (!toBeTransformed) return null;

        FMat4 tr = translation!float(fvec(pos, 0));
        if (hasTransform) {
            tr = tr * transform;
        }

        immutable transformedNode = new immutable(TransformRenderNode)(
            tr, toBeTransformed
        );

        immutable bg = backgroundRenderNode();

        debug(nodeFrame) {
            immutable fn = new immutable RectStrokeRenderNode(
                fvec(0, 0, 0, 1), bounds
            );
            immutable nodes = bg ? [
                bg, transformedNode, fn
            ] : [
                transformedNode, fn
            ];
            return new immutable(GroupRenderNode) (
                bounds, nodes
            );
        }
        else {
            return bg ?
                new immutable GroupRenderNode(bounds, [bg, transformedNode]) :
                transformedNode;
        }
    }

    immutable(RenderNode) backgroundRenderNode()
    {
        auto col = style.backgroundColor;
        if (col.argb & 0xff000000) {
            return new immutable RectFillRenderNode(col.asVec, bounds);
        }
        else {
            return null;
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

    private static struct MaskedFilter
    {
        EventFilter filter;
        uint mask;
    }

    // graph
    package SgParent _parent;

    package SgNode _prevSibling;
    package SgNode _nextSibling;

    // dirty state
    private DirtyFlags _dirtyState;

    // bounds
    private FPoint      _pos;
    private Lazy!FRect  _bounds;
    private Lazy!FRect  _transformedBounds;

    // transform
    private FMat4 _transform = FMat4.identity;
    private bool _hasTransform;

    // style
    private Style _style;
    private string _cssStyle;
    private string _id;
    private string _cssClass;
    private PseudoState _pseudoState;

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

/// The runtime class name of obj.
@property string className(Object obj)
{
    import std.algorithm : splitter;
    return typeid(obj).toString().splitter('.').back;
}
