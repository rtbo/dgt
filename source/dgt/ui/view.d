module dgt.ui.view;

import dgt.core.geometry;
import dgt.core.tree;
import dgt.css.style;
import gfx.math.mat;
import gfx.math.transform;
import dgt.render.framegraph;
import dgt.ui;
import dgt.ui.event;
import dgt.ui.layout;

import std.exception;
import std.experimental.logger;

/// Base class for all views in the user interface
class View : StyleElement, TreeNode!View
{

    this() { }

    /// The UI this view is attached to.
    @property UserInterface ui()
    {
        return root._ui;
    }

    /// The root of this user interface
    final override @property View root()
    {
        if (!_parent) return this;
        View p = _parent;
        while (p._parent) p = p._parent;
        return p;
    }

    /// This view's parent.
    final override @property View parent()
    {
        return _parent;
    }

    /// This view's previous sibling.
    final override @property View prevSibling()
    {
        return _prevSibling;
    }

    /// This view's next sibling.
    final override @property View nextSibling()
    {
        return _nextSibling;
    }

    /// Whether this view has children.
    final @property bool hasChildren() const
    {
        return _firstChild !is null;
    }

    /// The number of children this view has.
    final @property size_t childCount() const
    {
        return _childCount;
    }

    /// This view's first child.
    final override @property View firstChild()
    {
        return _firstChild;
    }

    /// This view's last child.
    final override @property View lastChild()
    {
        return _lastChild;
    }

    /// A bidirectional range of this view's children
    final @property auto children()
    {
        return siblingRange!View(_firstChild, _lastChild);
    }

    /// Appends the given view to this view children list.
    final protected void appendChild(View view)
    {
        enforce(view && !view._parent, "View.appendChild: invalid child or child already parented");
        view._parent = this;

        if (!hasChildren) {
            _firstChild = view;
            _lastChild = view;
        }
        else {
            _lastChild._nextSibling = view;
            view._prevSibling = _lastChild;
            _lastChild = view;
        }
        ++_childCount;
    }

    /// Prepend the given view to this view children list.
    final protected void prependChild(View view)
    {
        enforce(view && !view._parent, "View.appendChild: invalid child or child already parented");
        view._parent = this;

        if (!hasChildren) {
            _firstChild = view;
            _lastChild = view;
        }
        else {
            _firstChild._prevSibling = view;
            view._nextSibling = _firstChild;
            _firstChild = view;
        }
        ++_childCount;
    }

    /// Insert the given view in this view children list, just before the given
    /// child.
    final protected void insertChildBefore(View view, View child)
    {
        enforce(view && !view._parent && child._parent is this,
                "View.insertChildBefore: invalid view or child");
        view._parent = this;

        if (child is _firstChild) {
            _firstChild = view;
        }
        else {
            auto prev = child._prevSibling;
            prev._nextSibling = view;
            view._prevSibling = prev;
        }
        child._prevSibling = view;
        view._nextSibling = child;
        ++_childCount;
    }

    /// Removes the given view from this view children list.
    final protected void removeChild(View child)
    {
        enforce(child && child._parent is this, "View.removeChild: invalid child");

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


    /// Invalidate the view rendering. This triggers rendering.
    final void invalidate()
    {
        dirty(Dirty.render);
    }

    /// Request a layout pass
    final void requestLayoutPass()
    {
        dirty(Dirty.layout);
    }

    /// Request a style pass
    final void requestStylePass()
    {
        dirty(Dirty.style);
    }

    /// The dirtyState of this view.
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

        auto ui = this.ui;

        if (flags & Dirty.styleMask) {
            if (flags & Dirty.style && ui)
                ui.requestPass(UIPass.style);
            if (parent) parent.dirty(Dirty.childrenStyle);
        }
        if (flags & Dirty.layoutMask) {
            if (flags & Dirty.layout && ui)
                ui.requestPass(UIPass.layout);
            if (parent) parent.dirty(Dirty.childrenLayout);
        }
        if (flags & Dirty.renderMask) {
            if (flags & Dirty.render && ui)
                ui.requestPass(UIPass.render);
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
    package(dgt.ui) void recursClean(in Dirty flags)
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


    /// The padding of the view, that is, how much empty space is required
    /// around the content.
    /// Padding is always within the view's rect.
    final @property IPadding padding() const
    {
        return _padding;
    }

    /// ditto
    final @property void padding(in IPadding padding)
    {
        _padding = padding;
    }

    /// Ask this view to measure itself by assigning the measurement property.
    void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        measurement = ISize(widthSpec.size, heightSpec.size);
    }

    /// Size set by the view during measure phase
    final @property ISize measurement() const
    {
        return _measurement;
    }

    /// ditto
    final protected @property void measurement(in ISize sz)
    {
        _measurement = sz;
    }

    /// Ask the view to layout itself in the given rect
    /// The default implementation assign the rect property.
    void layout(in IRect rect)
    {
        this.rect = rect;
    }
    /// The position of the view relative to its parent.
    /// Does not account transforms on this view.
    /// This pos is the one of the rect property and is used in layout calculations.
    final @property IPoint pos() const
    {
        return _rect.point;
    }
    /// ditto
    final @property void pos(in IPoint pos)
    {
        if (pos != _rect.point) {
            _rect.point = pos;
            // _rect.point is included in parent and ui transforms
            dirty(Dirty.transformMask);
        }
    }
    /// The size of the view
    final @property ISize size()
    {
        return _rect.size;
    }
    /// ditto
    final @property void size(in ISize size)
    {
        _rect.size = size;
    }
    /// The 'logical' rect of the view.
    /// This is expressed in parent coordinates, and do not take into account
    /// the transform applied to this view.
    /// Actual bounds may differ due to use of borders, shadows or transform.
    /// This rect is the one used in layout calculations.
    final @property IRect rect()
    {
        return _rect;
    }
    /// ditto
    final @property void rect(in IRect rect)
    {
        if (rect != _rect) {
            _rect = rect;
            // _rect.point is included in parent and ui transforms
            dirty(Dirty.transformMask);
        }
    }

    /// Rect in local coordinates
    final @property IRect localRect()
    {
        return IRect(0, 0, size);
    }

    /// Position of this view as seen by parent, considering also
    /// the transform of this view.
    final @property IPoint parentPos()
    {
        return mapToParent(ivec(0, 0));
    }

    /// The rect of this view, as seen by parent, taking into account
    /// transform. A rect is always axis aligned, so in case of rotation,
    /// the bounding rect is returned.
    final @property IRect parentRect()
    {
        return mapToParent(localRect);
    }

    /// Position of this view as seen by ui, considering
    /// the whole transform chain.
    final @property IPoint uiPos()
    {
        return mapToUI(ivec(0, 0));
    }

    /// The rect of this view, as seen by ui, taking into account
    /// the whole transform chain. A rect is always axis aligned, so in case of rotation,
    /// the bounding rect is returned.
    final @property IRect uiRect()
    {
        return mapToUI(localRect);
    }

    @property Layout.Params layoutParams()
    {
        return _layoutParams;
    }
    @property void layoutParams(Layout.Params params)
    {
        _layoutParams = params;
    }



    /// Whether this view has a transform set. (Other than identity)
    final @property bool hasTransform() const { return _hasTransform; }

    /// The transform affecting this view and its children.
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

    /// Transform that maps view coordinates to parent coordinates
    /// This includes the layout positioning within the parent and the animation transform.
    final @property FMat4 transformToParent()
    {
        if (isDirty(Dirty.transformToParent)) {
            if (_hasTransform) {
                _transformToParent = transform.translate(fvec(pos, 0));
            }
            else {
                _transformToParent = translation(fvec(pos, 0));
                // this is cheap, let's do it now.
                _transformFromParent = translation(fvec(-pos, 0));
                clean(Dirty.transformFromParent);
            }
            clean(Dirty.transformToParent);
        }
        return _transformToParent;
    }

    /// Transform that maps parent coordinates to view coordinates
    final @property FMat4 transformFromParent()
    {
        import gfx.math.inverse : inverse;

        if (isDirty(Dirty.transformFromParent)) {
            if (_hasTransform) {
                _transformFromParent = inverse(transformToParent);
            }
            else {
                _transformFromParent = translation(fvec(-pos, 0));
                // this is cheap, let's do it now.
                _transformToParent = translation(fvec(pos, 0));
                clean(Dirty.transformToParent);
            }
            clean(Dirty.transformFromParent);
        }
        return _transformFromParent;
    }

    /// Transform that maps view coordinates to ui coordinates
    final @property FMat4 transformToUI()
    {
        if (isDirty(Dirty.transformToUI)) {
            _transformToUI = parent ?
                    parent.transformToUI * transformToParent :
                    transformToParent;
            clean(Dirty.transformToUI);
        }
        return _transformToUI;
    }

    /// Transform that maps ui coordinates to view coordinates
    final @property FMat4 transformFromUI()
    {
        import gfx.math.inverse : inverse;

        if (isDirty(Dirty.transformFromUI)) {
            _transformFromUI = inverse(transformToUI);
            clean(Dirty.transformFromUI);
        }
        return _transformFromUI;
    }

    /// Map a point from ui coordinates to this view coordinates
    final IPoint mapFromUI(in IPoint pos)
    {
        import std.math : round;

        const p = fvec(pos, 0).transform(transformFromUI).xy;
        return IPoint(cast(int)round(p.x), cast(int)round(p.y));
    }

    /// Map a point from this view coordinates to ui coordinates
    final IPoint mapToUI(in IPoint pos)
    {
        import std.math : round;

        const p = fvec(pos, 0).transform(transformToUI).xy;
        return IPoint(cast(int)round(p.x), cast(int)round(p.y));
    }

    /// Map a point from parent coordinates to this view coordinates
    final IPoint mapFromParent(in IPoint pos)
    {
        import std.math : round;

        const p = fvec(pos, 0).transform(transformFromParent).xy;
        return IPoint(cast(int)round(p.x), cast(int)round(p.y));
    }

    /// Map a point from this view coordinates to parent coordinates
    final IPoint mapToParent(in IPoint pos)
    {
        import std.math : round;

        const p = fvec(pos, 0).transform(transformToParent).xy;
        return IPoint(cast(int)round(p.x), cast(int)round(p.y));
    }

    /// Map a point from the other view coordinates to this view coordinates
    final IPoint mapFromView(View view, in IPoint pos)
    {
        const uip = view.mapToUI(pos);
        return mapFromUI(uip);
    }

    /// Map a point from this view coordinates to the other view coordinates
    final IPoint mapToView(View view, in IPoint pos)
    {
        const uip = mapToUI(pos);
        return view.mapFromUI(uip);
    }

    /// Map a rect from ui coordinates to this view coordinates
    final IRect mapFromUI(in IRect rect)
    {
        const frect = (cast(FRect)rect).transformBounds(transformFromUI);
        return roundRect(frect);
    }

    /// Map a rect from this view coordinates to ui coordinates
    final IRect mapToUI(in IRect rect)
    {
        const frect = (cast(FRect)rect).transformBounds(transformToUI);
        return roundRect(frect);
    }

    /// Map a rect from parent coordinates to this view coordinates
    final IRect mapFromParent(in IRect rect)
    {
        const frect = (cast(FRect)rect).transformBounds(transformFromParent);
        return roundRect(frect);
    }

    /// Map a rect from this view coordinates to parent coordinates
    final IRect mapToParent(in IRect rect)
    {
        const frect = (cast(FRect)rect).transformBounds(transformToParent);
        return roundRect(frect);
    }

    /// Map a rect from the other view coordinates to this view coordinates
    final IRect mapFromView(View view, in IRect rect)
    {
        const frect = (cast(FRect)rect).transformBounds(
            view.transformToUI * transformFromUI
        );
        return roundRect(frect);
    }

    /// Map a rect from this view coordinates to the other view coordinates
    final IRect mapToView(View view, in IRect rect)
    {
        const frect = (cast(FRect)rect).transformBounds(
            transformToUI * view.transformFromUI
        );
        return roundRect(frect);
    }

    /// Get a view at position given by pos.
    View viewAtPos(in IVec2 pos)
    {
        if (localRect.contains(pos)) {
            foreach (c; children) {
                const cp = c.mapFromParent(pos);
                auto res = c.viewAtPos(cp);
                if (res) return res;
            }
            return this;
        }
        else {
            return null;
        }
    }

    /// Recursively append views that are located at pos from root to end target.
    void viewsAtPos(in IVec2 pos, ref View[] nodes)
    {
        if (localRect.contains(pos)) {
            nodes ~= this;
            foreach (c; children) {
                const cp = c.mapFromParent(pos);
                c.viewsAtPos(cp, nodes);
            }
        }
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

    /// Remove an installed event filter.
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

    /// Called when mouse interacts with this view.
    protected void mouseDownEvent(MouseEvent ev) {}
    /// ditto
    protected void mouseUpEvent(MouseEvent ev) {}
    /// ditto
    protected void mouseDragEvent(MouseEvent ev) {}
    /// ditto
    protected void mouseEnterEvent(MouseEvent ev)
    {
        if (_hoverSensitive) {
            addPseudoState(PseudoState.hover);
        }
    }
    /// ditto
    protected void mouseLeaveEvent(MouseEvent ev)
    {
        if (_hoverSensitive) {
            remPseudoState(PseudoState.hover);
        }
    }
    /// ditto
    protected void mouseMoveEvent(MouseEvent ev) {

    }
    /// ditto
    protected void mouseClickEvent(MouseEvent ev) {}
    /// ditto
    protected void mouseDblClickEvent(MouseEvent ev) {}

    /// Chain an event until its final target, giving each parent in the chain
    /// the opportunity to filter it, or to handle it after its children if
    /// the event hasn't been consumed by any of them.
    /// Returns: the view that has consumed the event, or null.
    final View chainEvent(Event event)
    {
        // fiter phase
        if (filterEvent(event)) return this;

        // chaining phase
        if (event.viewChain.length) {
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
                mouseDownEvent(mev);
                break;
            case EventType.mouseUp:
                mouseUpEvent(mev);
                break;
            case EventType.mouseDrag:
                mouseDragEvent(mev);
                break;
            case EventType.mouseMove:
                mouseMoveEvent(mev);
                break;
            case EventType.mouseEnter:
                mouseEnterEvent(mev);
                break;
            case EventType.mouseLeave:
                mouseLeaveEvent(mev);
                break;
            case EventType.mouseClick:
                mouseClickEvent(mev);
                break;
            case EventType.mouseDblClick:
                mouseDblClickEvent(mev);
                break;
            default:
                break;
            }
        }
        return event.consumed;
    }

    // StyleElement implementation

    final override @property StyleElement styleParent() {
        return _parent ? cast(StyleElement)_parent : cast(StyleElement)_ui;
    }
    final override @property StyleElement styleRoot() {
        return ui;
    }
    final override @property StyleElement stylePrevSibling() {
        return _prevSibling;
    }
    final override @property StyleElement styleNextSibling() {
        return _nextSibling;
    }
    final override @property StyleElement styleFirstChild() {
        return _firstChild;
    }
    final override @property StyleElement styleLastChild() {
        return _lastChild;
    }


    override @property string inlineCSS() { return _inlineCSS; }
    /// Set the inline CSS
    @property void inlineCSS(string css)
    {
        if (css != _inlineCSS) {
            _inlineCSS = css;
            requestStylePass();
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
            requestStylePass();
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
            requestStylePass();
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
            requestStylePass();
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
        requestStylePass();
    }
    /// ditto
    final void remPseudoState(in PseudoState flags)
    {
        pseudoState = _pseudoState & (~flags);
        requestStylePass();
    }

    /// Flag that causes PseudoState.hover to be set when the cursor hovers the view
    final bool hoverSensitive() { return _hoverSensitive; }
    /// ditto
    final void hoverSensitive(in bool hs)
    {
        if (!_hoverSensitive == hs) {
            _hoverSensitive = hs;
            // requestStylePass(); ??
        }
    }

    override @property FSize viewportSize()
    {
        auto ui = this.ui;
        return ui ? cast(FSize)ui.size : FSize(0, 0);
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


    immutable(FGNode) render(FrameContext fc) {
        import std.algorithm : filter, map;
        import std.array : array;
        return new immutable FGGroupNode (
            children
                .map!(c => c.transformRender(fc))
                .filter!(n => n !is null)
                .array
        );
    }

    version(dgtActivateWireframe) {
        import dgt.core.color : Color;
        /// the wireframe color to use if version(dgtActivateWireframe) is applied.
        static Color wireframeColor = Color.black;
    }

    final immutable(FGNode) transformRender(FrameContext fc)
    {
        immutable fgn = render(fc);
        immutable transformed = fgn ?
            new immutable FGTransformNode( transformToParent, fgn ) :
            null;


        version(dgtActivateWireframe) {
            import dgt.core.color : Color;
            import dgt.core.paint : ColorPaint;
            import gfx.foundation.typecons : some;

            const r = rect;
            const wr = FRect(r.left-0.5, r.top-0.5, r.width+1, r.height+1);

            immutable wireframe = new immutable FGRectNode(
                wr, 0, null, some(RectBorder(wireframeColor.asVec, 1))
            );
            if (transformed) {
                return new immutable FGGroupNode([ transformed, wireframe ]);
            }
            else {
                return wireframe;
            }
        }
        else {
            return transformed;
        }
    }

    /// Get the name of this view, or its id if name is not set.
    /// For debug purpose only.
    @property string name() {
        return _name.length ? _name : _id;
    }

    /// Set the name of this view.
    /// For debug purpose only.
    @property void name(string value) {
        _name = value;
    }

    /// Bit flags that describe what in a view needs update
    enum Dirty
    {
        /// nothing is dirty
        clean               = 0,

        /// A style pass is needed
        styleMask           = style | childrenStyle,
        /// Style has changed for this view.
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
        transformToUI    = 0x0400,
        /// ditto
        transformFromUI  = 0x0800,

        /// A layout pass is needed
        layoutMask          = layout | childrenLayout,
        /// layout was changed
        layout              = 0x1000,
        /// One or more descendant have dirty layout
        childrenLayout      = 0x2000,

        /// All bits set
        all                 = styleMask | renderMask | transformMask | layoutMask
    }

    private static struct MaskedFilter
    {
        EventFilter filter;
        uint mask;
    }


    invariant()
    {
        assert(!_firstChild || _firstChild._parent is this);
        assert(!_lastChild || _lastChild._parent is this);
        assert(!_firstChild || _firstChild._prevSibling is null);
        assert(!_lastChild || _lastChild._nextSibling is null);

        assert(_childCount != 0 || (_firstChild is null && _lastChild is null));
        assert(_childCount == 0 || (_firstChild !is null && _lastChild !is null));
        assert(_childCount != 1 || (_firstChild is _lastChild));
        assert((_firstChild is null) == (_lastChild is null));

        assert(!_prevSibling || _prevSibling._nextSibling is this);
        assert(!_nextSibling || _nextSibling._prevSibling is this);

        assert(!(_parent && _ui)); // only root can hold the ui ref
    }


    // ui
    package(dgt.ui) UserInterface _ui;
    private View _parent;
    private View _prevSibling;
    private View _nextSibling;
    private View _firstChild;
    private View _lastChild;
    private size_t _childCount;

    // dirty state
    private Dirty _dirtyState = Dirty.layoutMask | Dirty.styleMask | Dirty.renderMask;

    // layout
    private IPadding        _padding;
    private ISize           _measurement;
    private IRect           _rect;
    private Layout.Params   _layoutParams;

    // transform
    private FMat4 _transform            = FMat4.identity;
    private FMat4 _transformToParent      = FMat4.identity;
    private FMat4 _transformFromParent   = FMat4.identity;
    private FMat4 _transformToUI       = FMat4.identity;
    private FMat4 _transformFromUI    = FMat4.identity;
    private bool _hasTransform;

    // style
    private string _css;
    private string _inlineCSS;
    private string _id;
    private string _cssClass;
    private PseudoState _pseudoState;
    private bool _hoverSensitive;
    // style properties
    package(dgt.ui) IStyleMetaProperty[]        _styleMetaProperties;
    package(dgt.ui) IStyleProperty[string]      _styleProperties;

    // events
    private MaskedFilter[] _evFilters;

    // debug
    private string _name;
}

/// Testing ui relationship
unittest
{
    import std.algorithm : equal;

    auto root = new View;
    auto c1 = new View;
    auto c2 = new View;
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
    import gfx.math.approx : approxUlp, approxUlpAndAbs;

    auto root = new View;
    auto child1 = new View;
    auto subchild = new View;
    auto child2 = new View;

    root.rect = FRect(0, 0, 100, 100);
    child1.rect = FRect(20, 20, 60, 40);
    subchild.rect = FRect(5, 5, 40, 25);
    child2.rect = FRect(10, 80, 90, 10);

    root.appendChild(child1);
    root.appendChild(child2);
    child1.appendChild(subchild);

    immutable p = fvec(10, 10);

    assert(approxUlp(child1.mapFromParent(p),           fvec(-10, -10)));
    assert(approxUlp(child1.mapFromUI(p),               fvec(-10, -10)));
    assert(approxUlp(child1.mapToParent(p),             fvec( 30,  30)));
    assert(approxUlp(child1.mapToUI(p),                 fvec( 30,  30)));

    assert(approxUlp(child2.mapFromParent(p),           fvec(  0, -70)));
    assert(approxUlp(child2.mapFromUI(p),               fvec(  0, -70)));
    assert(approxUlp(child2.mapToParent(p),             fvec( 20,  90)));
    assert(approxUlp(child2.mapToUI(p),                 fvec( 20,  90)));

    assert(approxUlp(subchild.mapFromParent(p),         fvec(  5,   5)));
    assert(approxUlp(subchild.mapFromUI(p),             fvec(-15, -15)));
    assert(approxUlp(subchild.mapToParent(p),           fvec( 15,  15)));
    assert(approxUlp(subchild.mapToUI(p),               fvec( 35,  35)));

    assert(approxUlp(subchild.mapToView(child2, p),     fvec( 25,  -45)));
    assert(approxUlp(subchild.mapFromView(child2, p),   fvec( -5,  65)));
}
