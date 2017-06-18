/// View root class module
module dgt.view.view;

import dgt.color;
import dgt.css.properties;
import dgt.css.style;
import dgt.event;
import dgt.geometry;
import dgt.math;
import dgt.paint;
import dgt.sg.node;
import dgt.sg.rect;
import dgt.view.layout;
import dgt.window;

import std.exception;
import std.experimental.logger;
import std.range;
import std.typecons;



auto addStyleSupport(SMP)(View view, SMP metaProp)
if (is(SMP : IStyleMetaProperty) && !SMP.isShorthand)
{
    auto sp = new SMP.Property(view, metaProp);
    view._styleProperties[metaProp.name] = sp;
    if (!metaProp.hasShorthand) view._styleMetaProperties ~= metaProp;
    return sp;
}

void addShorthandStyleSupport(SMP)(View view, SMP metaProp)
if (is(SMP : IStyleMetaProperty) && SMP.isShorthand)
{
    view._styleMetaProperties ~= metaProp;
}

/// View hierarchy root class
class View : StyleElement
{
    /// builds a new view
    this()
    {
        _background = addStyleSupport(this, BackgroundMetaProperty.instance);
        _borderColor = addStyleSupport(this, BorderColorMetaProperty.instance);
        _borderWidth = addStyleSupport(this, BorderWidthMetaProperty.instance);
        _borderRadius = addStyleSupport(this, BorderRadiusMetaProperty.instance);

        _background.onChange += &invalidate;
        _borderColor.onChange += &invalidate;
        _borderWidth.onChange += &invalidate;
        _borderRadius.onChange += &invalidate;

        // whats need to be dirty at start.
        // flags not set here get set one way or another in due time.
        _dirtyState = Dirty.styleMask;
    }

    /// The window this view is attached to.
    @property Window window()
    {
        return root._window;
    }

    /// The root of this scene graph
    @property View root()
    {
        if (!_parent) return cast(View)this;
        View p = _parent;
        while (p._parent) p = p._parent;
        return p;
    }

    /// Whether this view is root
    @property bool isRoot() const
    {
        return _parent is null;
    }

    /// This view's parent.
    @property View parent()
    {
        return _parent;
    }

    /// This view's previous sibling.
    @property View prevSibling()
    {
        return _prevSibling;
    }

    /// This view's next sibling.
    @property View nextSibling()
    {
        return _nextSibling;
    }

    /// Whether this view has children.
    @property bool hasChildren() const
    {
        return _firstChild !is null;
    }

    /// The number of children this view has.
    @property size_t childCount() const
    {
        return _childCount;
    }

    /// This view's first child.
    @property inout(View) firstChild() inout
    {
        return _firstChild;
    }

    /// This view's last child.
    @property inout(View) lastChild() inout
    {
        return _lastChild;
    }

    /// A bidirectional range of this view's children
    @property auto children()
    {
        return SgSiblingNodeRange!View(_firstChild, _lastChild);
    }

    /// ditto
    @property auto children() const
    {
        return SgSiblingNodeRange!(const(View))(_firstChild, _lastChild);
    }

    /// Appends the given view to this view children list.
    protected void appendChild(View view)
    {
        enforce(view && !view._parent);
        view._parent = this;
        view.dirty(Dirty.parented);

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
        dirty(Dirty.childAdded);
    }

    /// Prepend the given view to this view children list.
    protected void prependChild(View view)
    {
        enforce(view && !view._parent);
        view._parent = this;
        view.dirty(Dirty.parented);

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
        dirty(Dirty.childAdded);
    }

    /// Insert the given view in this view children list, just before the given
    /// child.
    protected void insertChildBefore(View view, View child)
    {
        enforce(view && !view._parent && child._parent is this);
        view._parent = this;
        view.dirty(Dirty.parented);

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
        dirty(Dirty.childAdded);
    }

    /// Removes the given view from this view children list.
    protected void removeChild(View child)
    {
        enforce(child && child._parent is this);

        child._parent = null;
        child.dirty(Dirty.parented);

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
        dirty(Dirty.childRemoved);
    }

    /// The padding of the view, that is, how much empty space is required
    /// around the content.
    /// Padding is always within the view's rect.
    @property FPadding padding() const
    {
        return _padding;
    }

    /// ditto
    @property void padding(in FPadding padding)
    {
        _padding = padding;
    }

    /// Ask this view to measure itself by assigning the measurement property.
    void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        measurement = FSize(widthSpec.size, heightSpec.size);
    }

    /// Size set by the view during measure phase
    final @property FSize measurement() const
    {
        return _measurement;
    }

    /// ditto
    final protected @property void measurement(in FSize sz)
    {
        _measurement = sz;
    }

    /// Ask the view to layout itself in the given rect
    /// The default implementation assign the rect property.
    void layout(in FRect rect)
    {
        this.rect = rect;
    }

    /// Invalidate the view content. This triggers rendering.
    final void invalidate()
    {
        dirty(Dirty.content);
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

        if (flags & Dirty.familyMask) {
            if (parent) parent.dirty(Dirty.childrenFamily);
        }
        if (flags & Dirty.styleMask) {
            if (flags & Dirty.style && window)
                window.requestStylePass();
            if (parent) parent.dirty(Dirty.childrenStyle);
        }
        if (flags & Dirty.contentMask)
        {
            if (flags & Dirty.content && window)
                window.invalidate();
            if (parent) parent.dirty(Dirty.childrenContent);
        }
    }
    /// Reset some dirty flags
    final void clean(in Dirty flags)
    {
        _dirtyState &= ~flags;

        if (!parent) return;

        if ((flags & Dirty.closeFamilyMask && !isDirty(Dirty.childrenFamily)) ||
                (flags & Dirty.childrenFamily && !isDirty(Dirty.closeFamilyMask))) {
            parent.clean(Dirty.childrenFamily);
        }

        if ((flags & Dirty.content && !isDirty(Dirty.childrenContent)) ||
                (flags & Dirty.childrenContent && !isDirty(Dirty.content))) {
            parent.clean(Dirty.childrenContent);
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

    /// The position of the view relative to its parent.
    /// Does not account transforms on this view.
    /// This pos is the one of the rect property and is used in layout calculations.
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
            dirty(Dirty.transformMask);
        }
    }
    /// The size of the view
    final @property FSize size()
    {
        return _rect.size;
    }
    /// ditto
    final @property void size(in FSize size)
    {
        _rect.size = size;
    }
    /// The 'logical' rect of the view.
    /// This is expressed in parent coordinates, and do not take into account
    /// the transform applied to this view.
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
            dirty(Dirty.transformMask);
        }
    }

    /// Rect in local coordinates
    final @property FRect localRect()
    {
        return FRect(0, 0, size);
    }

    /// Position of this view as seen by parent, considering also
    /// the transform of this view.
    final @property FPoint parentPos()
    {
        return mapToParent(fvec(0, 0));
    }

    /// The rect of this view, as seen by parent, taking into account
    /// transform. A rect is always axis aligned, so in case of rotation,
    /// the bounding rect is returned.
    final @property FRect parentRect()
    {
        return mapToParent(localRect);
    }

    /// Position of this view as seen by scene, considering
    /// the whole transform chain.
    final @property FPoint scenePos()
    {
        return mapToScene(fvec(0, 0));
    }

    /// The rect of this view, as seen by scene, taking into account
    /// the whole transform chain. A rect is always axis aligned, so in case of rotation,
    /// the bounding rect is returned.
    final @property FRect sceneRect()
    {
        return mapToScene(localRect);
    }

    /// Whether this view has a transform set. (Other than identity)
    final @property bool hasTransform() const { return _hasTransform; }

    /// The transform affecting this view and its children.
    /// The transform does not affect the layout, but affects rendering.
    /// It should be used for animation mainly.
    final @property FMat4 transform() const { return _transform; }

    /// ditto
    final @property void transform(in FMat4 transform)
    {
        _transform = transform;
        _hasTransform = transform != FMat4.identity;
        dirty(Dirty.transformMask);
    }

    /// Transform that maps view coordinates to parent coordinates
    final @property FMat4 transformToParent()
    {
        if (isDirty(Dirty.transformToParent)) {
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

    /// Transform that maps parent coordinates to view coordinates
    final @property FMat4 transformFromParent()
    {
        if (isDirty(Dirty.transformFromParent)) {
            if (_hasTransform) {
                _transformFromParent = inverse(transformToParent);
            }
            else {
                _transformFromParent = translation!float(fvec(-pos, 0));
                // this is cheap, let's do it now.
                _transformToParent = translation!float(fvec(pos, 0));
                clean(Dirty.transformToParent);
            }
            clean(Dirty.transformFromParent);
        }
        return _transformFromParent;
    }

    /// Transform that maps view coordinates to scene coordinates
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

    /// Transform that maps scene coordinates to view coordinates
    final @property FMat4 transformFromScene()
    {
        if (isDirty(Dirty.transformFromScene)) {
            _transformFromScene = inverse(transformToScene);
            clean(Dirty.transformFromScene);
        }
        return _transformFromScene;
    }

    /// Map a point from scene coordinates to this view coordinates
    final FPoint mapFromScene(in FPoint pos)
    {
        return fvec(pos, 0).transform(transformFromScene).xy;
    }

    /// Map a point from this view coordinates to scene coordinates
    final FPoint mapToScene(in FPoint pos)
    {
        return fvec(pos, 0).transform(transformToScene).xy;
    }

    /// Map a point from parent coordinates to this view coordinates
    final FPoint mapFromParent(in FPoint pos)
    {
        return fvec(pos, 0).transform(transformFromParent).xy;
    }

    /// Map a point from this view coordinates to parent coordinates
    final FPoint mapToParent(in FPoint pos)
    {
        return fvec(pos, 0).transform(transformToParent).xy;
    }

    /// Map a point from the other view coordinates to this view coordinates
    final FPoint mapFromNode(View view, in FPoint pos)
    {
        immutable sp = view.mapToScene(pos);
        return mapFromScene(sp);
    }

    /// Map a point from this view coordinates to the other view coordinates
    final FPoint mapToNode(View view, in FPoint pos)
    {
        immutable sp = mapToScene(pos);
        return view.mapFromScene(sp);
    }

    /// Map a point from scene coordinates to this view coordinates
    final FRect mapFromScene(in FRect rect)
    {
        return rect.transformBounds(transformFromScene);
    }

    /// Map a point from this view coordinates to scene coordinates
    final FRect mapToScene(in FRect rect)
    {
        return rect.transformBounds(transformToScene);
    }

    /// Map a point from parent coordinates to this view coordinates
    final FRect mapFromParent(in FRect rect)
    {
        return rect.transformBounds(transformFromParent);
    }

    /// Map a point from this view coordinates to parent coordinates
    final FRect mapToParent(in FRect rect)
    {
        return rect.transformBounds(transformToParent);
    }

    /// Map a point from the other view coordinates to this view coordinates
    final FRect mapFromNode(View view, in FRect rect)
    {
        return rect.transformBounds(
            view.transformToScene * transformFromScene
        );
    }

    /// Map a point from this view coordinates to the other view coordinates
    final FRect mapToNode(View view, in FRect rect)
    {
        return rect.transformBounds(
            transformToScene * view.transformFromScene
        );
    }

    /// Get a view at position given by pos.
    View viewAtPos(in FVec2 pos)
    {
        if (localRect.contains(pos)) {
            foreach (c; children) {
                immutable cp = c.mapFromParent(pos);
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
    void viewsAtPos(in FVec2 pos, ref View[] nodes)
    {
        if (localRect.contains(pos)) {
            nodes ~= this;
            foreach (c; children) {
                immutable cp = c.mapFromParent(pos);
                c.viewsAtPos(cp, nodes);
            }
        }
    }

    override @property string inlineCSS() { return _inlineCSS; }
    /// Set the inline CSS
    @property void inlineCSS(string css)
    {
        if (css != _inlineCSS) {
            _inlineCSS = css;
            dirty(Dirty.style);
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
            dirty(Dirty.style);
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
            dirty(Dirty.style);
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
            dirty(Dirty.style);
        }
    }

    /// A pseudo state of the view.
    override final @property PseudoState pseudoState() { return _pseudoState; }
    /// ditto
    final @property void pseudoState(in PseudoState state)
    {
        if (state != _pseudoState) {
            _pseudoState = state;
            dirty(Dirty.style);
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
            dirty(Dirty.style);
        }
    }

    override @property FSize viewportSize()
    {
        auto win = window;
        return win ? cast(FSize)win.geometry.size : FSize(0, 0);
    }

    override @property float dpi()
    {
        auto win = window;
        // FIXME: return default from platform directly
        return win ? win.screen.dpi : 96f;
    }

    @property IStyleMetaProperty[] styleMetaProperties()
    {
        return _styleMetaProperties;
    }

    IStyleProperty styleProperty(string name) {
        auto sp = name in _styleProperties;
        return sp ? *sp : null;
    }

    @property Paint background()
    {
        return _background.value;
    }
    @property void background(Paint paint)
    {
        _background.setValue(paint);
    }
    @property StyleProperty!Paint backgroundProperty()
    {
        return _background;
    }

    @property Color borderColor()
    {
        return _borderColor.value;
    }
    @property void borderColor(in Color color)
    {
        _borderColor.setValue(color);
    }
    @property StyleProperty!Color borderColorProperty()
    {
        return _borderColor;
    }

    @property int borderWidth()
    {
        return _borderWidth.value;
    }
    @property void borderWidth(in int val)
    {
        _borderWidth.setValue(val);
    }
    @property StyleProperty!int borderWidthProperty()
    {
        return _borderWidth;
    }

    @property float borderRadius()
    {
        return _borderRadius.value;
    }
    @property void borderRadius(in float val)
    {
        _borderRadius.setValue(val);
    }
    @property StyleProperty!float borderRadiusProperty()
    {
        return _borderRadius;
    }

    @property Layout.Params layoutParams()
    {
        return _layoutParams;
    }
    @property void layoutParams(Layout.Params params)
    {
        _layoutParams = params;
    }

    void printStyle(bool recursive=true)
    {
        import std.algorithm : sort;
        import std.array : array;
        import std.range : repeat;
        import std.stdio : writeln;
        auto styles = _styleProperties.values.sort!("a.name < b.name");
        immutable l = repeat(' ', 4*level).array;
        writeln(l, "style properties of ", name, ":");
        foreach (s; styles) {
            writeln(l, s);
        }
        if (recursive) {
            foreach (c; children) {
                c.printStyle(true);
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
    protected void mouseMoveEvent(MouseEvent ev) {}
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


    /// Whether this view is dynamic.
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

    /// Whether this view has background other than transparent
    @property bool hasBackground()
    {
        immutable sCol = borderColor;
        auto paint = background;
        if (sCol.argb & 0xff00_0000) {
            return true;
        }
        if (paint && paint.type == PaintType.color) {
            if ((cast(ColorPaint)paint).color.argb & 0xff00_0000) {
                return true;
            }
        }
        else if (paint) {
            return true;
        }

        return false;
    }

    @property bool sgHasContent()
    {
        return _sgHasContent;
    }

    @property void sgHasContent(bool has)
    {
        _sgHasContent = has;
    }

    /// function called by the renderer, that may reside in a different thread
    /// This is called while the GUI thread is blocked, so fields can be accessed
    /// safely, but no reference to the node should be kept or used outside this
    /// function.
    SGNode sgUpdateContent(SGNode previous)
    {
        return null;
    }

    @property uint level()
    {
        auto p = parent;
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

        assert(!(_parent && _window)); // only root can hold the window ref
    }

    // graph
    package(dgt) Window _window;

    private View _parent;

    private View _prevSibling;
    private View _nextSibling;

    private size_t _childCount;
    private View _firstChild;
    private View _lastChild;

    // layout
    private FPadding        _padding;
    private FSize           _measurement;

    // dirty state
    private Dirty _dirtyState;

    // bounds
    private FRect  _rect;

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
    private IStyleMetaProperty[]        _styleMetaProperties;
    private IStyleProperty[string]      _styleProperties;
    private StyleProperty!Paint         _background;
    private StyleProperty!Color         _borderColor;
    private StyleProperty!int           _borderWidth;
    private StyleProperty!float         _borderRadius;
    private Layout.Params               _layoutParams;

    // events
    private MaskedFilter[] _evFilters;

    // cache policy
    private bool _dynamic=false;

    // debug info
    private string _name; // id will be used if name is empty


    // following fields are reserved to the scenegraph

package(dgt):

    @property SGTransformNode sgNode()
    {
        if (!_sgNode) _sgNode = new SGTransformNode;
        return _sgNode;
    }

    @property SGNode sgBackgroundNode()
    {
        if (hasBackground) {
            if (!_sgBackgroundNode) _sgBackgroundNode = new SGRectNode;
            _sgBackgroundNode.rect = localRect;
            _sgBackgroundNode.fillPaint = background;
            _sgBackgroundNode.strokeColor = borderColor;
            _sgBackgroundNode.strokeWidth = borderWidth;
            _sgBackgroundNode.radius = borderRadius;
        }
        else {
            _sgBackgroundNode = null;
        }
        return _sgBackgroundNode;
    }

    @property SGNode sgContentNode()
    {
        return _sgContentNode;
    }

    @property void sgContentNode(SGNode node)
    {
        _sgContentNode = node;
    }

    @property SGNode sgChildrenNode()
    {
        if (sgBackgroundNode) return sgBackgroundNode;
        else return sgNode;
    }

private:

    SGTransformNode _sgNode;
    SGRectNode _sgBackgroundNode;
    SGNode _sgContentNode;
    bool _sgHasContent;
}


/// Bit flags that describe what in a view needs update
enum Dirty
{
    /// nothing is dirty
    clean               = 0,

    /// Children were added/removed in this node or descendant or parent changed
    familyMask          = 0x000f,
    /// Children were added/removed, or parent changed in this node
    closeFamilyMask     = 0x0007,
    /// Children were added/removed in this node or descendant
    allChildrenMask     = 0x000b,
    /// Child was added/removed
    childMask           = 0x0003,
    /// Child was added
    childAdded          = 0x0001,
    /// Child was removed
    childRemoved        = 0x0002,
    /// Was given to/removed from a parent
    parented            = 0x0004,
    /// One or more descendants have a family change
    childrenFamily      = 0x0008,

    /// Some visual content has changed
    contentMask         = 0x00f0,

    /// A style pass is needed
    styleMask           = 0x0030,
    /// Style has changed for this node.
    /// This includes: id, class, pseudo-class and of course rules.
    style               = 0x0010,
    /// One children or descendant has its style dirty.
    childrenStyle       = 0x0020,

    /// Content is dirty
    content             = 0x0040,
    /// One or more descendant have dirty content
    childrenContent     = 0x0080,

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

    /// All bits set
    all                 = 0xffff_ffff,
}

/// Testing scene graph relationship
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
    import dgt.math.approx : approxUlp, approxUlpAndAbs;

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

/// The runtime class name of obj.
@property string className(Object obj)
{
    import std.algorithm : splitter;
    return typeid(obj).toString().splitter('.').back;
}

private:

/// Bidirectional range that traverses a sibling view list
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

static assert (isBidirectionalRange!(SgSiblingNodeRange!View));
static assert (isBidirectionalRange!(SgSiblingNodeRange!(const(View))));
