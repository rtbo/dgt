module dgt.ui.view;

import dgt.core.geometry;
import dgt.core.tree;
import dgt.css.style;
import dgt.math.mat;
import dgt.math.transform;
import dgt.render.framegraph;
import dgt.ui;
import dgt.ui.layout;

import std.exception;

/// Base class for all views in the user interface
class View : StyleElement {

    this() { }

    /// The UI this view is attached to.
    @property UserInterface ui()
    {
        return root._ui;
    }

    /// The root of this user interface
    override @property View root()
    {
        if (!_parent) return this;
        View p = _parent;
        while (p._parent) p = p._parent;
        return p;
    }

    /// This view's parent.
    override @property View parent()
    {
        return _parent;
    }

    /// This view's previous sibling.
    override @property View prevSibling()
    {
        return _prevSibling;
    }

    /// This view's next sibling.
    override @property View nextSibling()
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
    override @property View firstChild()
    {
        return _firstChild;
    }

    /// This view's last child.
    override @property View lastChild()
    {
        return _lastChild;
    }

    /// A bidirectional range of this view's children
    @property auto children()
    {
        return siblingRange!View(_firstChild, _lastChild);
    }

    /// Appends the given view to this view children list.
    protected void appendChild(View view)
    {
        enforce(view && !view._parent);
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
    protected void prependChild(View view)
    {
        enforce(view && !view._parent);
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
    protected void insertChildBefore(View view, View child)
    {
        enforce(view && !view._parent && child._parent is this);
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
    protected void removeChild(View child)
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
            // _rect.point is included in parent and ui transforms
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
            // _rect.point is included in parent and ui transforms
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

    /// Position of this view as seen by ui, considering
    /// the whole transform chain.
    final @property FPoint uiPos()
    {
        return mapToUI(fvec(0, 0));
    }

    /// The rect of this view, as seen by ui, taking into account
    /// the whole transform chain. A rect is always axis aligned, so in case of rotation,
    /// the bounding rect is returned.
    final @property FRect uiRect()
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
        if (isDirty(Dirty.transformFromUI)) {
            _transformFromUI = inverse(transformToUI);
            clean(Dirty.transformFromUI);
        }
        return _transformFromUI;
    }

    /// Map a point from ui coordinates to this view coordinates
    final FPoint mapFromUI(in FPoint pos)
    {
        return fvec(pos, 0).transform(transformFromUI).xy;
    }

    /// Map a point from this view coordinates to ui coordinates
    final FPoint mapToUI(in FPoint pos)
    {
        return fvec(pos, 0).transform(transformToUI).xy;
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
    final FPoint mapFromView(View view, in FPoint pos)
    {
        immutable sp = view.mapToUI(pos);
        return mapFromUI(sp);
    }

    /// Map a point from this view coordinates to the other view coordinates
    final FPoint mapToView(View view, in FPoint pos)
    {
        immutable sp = mapToUI(pos);
        return view.mapFromUI(sp);
    }

    /// Map a point from ui coordinates to this view coordinates
    final FRect mapFromUI(in FRect rect)
    {
        return rect.transformBounds(transformFromUI);
    }

    /// Map a point from this view coordinates to ui coordinates
    final FRect mapToUI(in FRect rect)
    {
        return rect.transformBounds(transformToUI);
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
    final FRect mapFromView(View view, in FRect rect)
    {
        return rect.transformBounds(
            view.transformToUI * transformFromUI
        );
    }

    /// Map a point from this view coordinates to the other view coordinates
    final FRect mapToView(View view, in FRect rect)
    {
        return rect.transformBounds(
            transformToUI * view.transformFromUI
        );
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
        // requestStylePass(); ??
    }
    /// ditto
    final void remPseudoState(in PseudoState flags)
    {
        pseudoState = _pseudoState & (~flags);
        // requestStylePass(); ??
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


    immutable(FGNode) render() {
        import std.algorithm : map;
        import std.array : array;
        return new immutable FGGroupNode (
            children.map!(c => c.transformRender()).array
        );
    }

    final immutable(FGNode) transformRender() {
        return new immutable FGTransformNode(
            transformToParent, render()
        );
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
    private FPadding        _padding;
    private FSize           _measurement;
    private FRect           _rect;
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
