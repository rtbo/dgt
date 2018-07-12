module dgt.ui;

import dgt.core.geometry;
import dgt.core.color;
import dgt.core.paint;
import dgt.css.om : Stylesheet;
import dgt.css.style;
import dgt.platform.event;
import dgt.render.framegraph;
import dgt.ui.animation;
import dgt.ui.event;
import dgt.ui.style;
import dgt.ui.view : View;

import gfx.core.typecons : option, Option, none;

import std.experimental.logger;
import std.typecons : rebindable, Rebindable;

/// The UserInterface class represent the top level of the GUI tree.
final class UserInterface : StyleElement {

    this() {
        _backgroundProperty = addStyleSupport(BackgroundMetaProperty.instance);
        _backgroundProperty.onChange += { _bgDirty = true; };
    }

    @property ISize size() {
        return _size;
    }

    @property immutable(Paint) background() {
        return _backgroundProperty.value;
    }

    @property void background(immutable(Paint) value) {
        _backgroundProperty.setValue(rebindable(value));
    }

    /// The View root attached to this ui
    @property inout(View) root() inout { return _root; }
    /// ditto
    @property void root(View root)
    {
        if (_root) {
            _root._ui = null;
        }
        _root = root;
        if (_root) {
            _root._ui = this;
        }
    }

    void handleEvent(PlWindowEvent wEv)
    {
        switch (wEv.type)
        {
        case PlEventType.expose:
            requestPass(UIPass.render);
            break;
        case PlEventType.resize:
            handleResize(cast(PlResizeEvent) wEv);
            break;
        case PlEventType.mouseDown:
            handleMouseDown(cast(PlMouseEvent) wEv);
            break;
        case PlEventType.mouseUp:
            handleMouseUp(cast(PlMouseEvent) wEv);
            break;
        case PlEventType.mouseMove:
            handleMouseMove(cast(PlMouseEvent) wEv);
            break;
        case PlEventType.mouseEnter:
            handleMouseEnter(cast(PlMouseEvent) wEv);
            break;
        case PlEventType.mouseLeave:
            handleMouseLeave(cast(PlMouseEvent) wEv);
            break;
        case PlEventType.keyDown:
            // need focus
            break;
        case PlEventType.keyUp:
            // need focus
            break;
        default:
            break;
        }
    }

    @property UIPass dirtyPass() {
        return _dirtyPass;
    }

    void requestPass(in UIPass pass) {
        _dirtyPass |= pass;
    }

    @property bool needStylePass() {
        return (_dirtyPass & UIPass.style) == UIPass.style;
    }

    @property bool needLayoutPass() {
        return (_dirtyPass & UIPass.layout) == UIPass.layout;
    }

    @property bool needRenderPass() {
        return (_dirtyPass & UIPass.render) == UIPass.render;
    }

    void stylePass () {
        if (!_size.area) return;

        import dgt.css.cascade : cssCascade;
        import dgt.css.parse : parseCSS;
        import dgt.css.style : Origin;

        if (!_dgtCSS) {
            _dgtCSS = parseCSS(cast(string)import("dgt.css"), null, Origin.dgt);
        }
        cssCascade(this, _dgtCSS);
        _root.recursClean(View.Dirty.styleMask);
        _dirtyPass &= ~UIPass.style;
    }

    void layoutPass () {
        if (!_root) return;
        if (!_size.area) return;

        import dgt.ui.layout : MeasureSpec;
        _root.measure(
            MeasureSpec.makeAtMost(_size.width),
            MeasureSpec.makeAtMost(_size.height)
        );
        _root.layout(IRect(0, 0, _size));
        _dirtyPass &= ~UIPass.layout;
    }

    immutable(FGFrame) frame(in size_t windowHandle) {
        import std.algorithm : map;
        import std.exception : assumeUnique;

        auto fc = new FrameContext;

        if (_bgDirty) {
            immutable bg = background;
            if (_bgNode) {
                // release resource held by previous node
                fc.prune(_bgNode.cookie);
                _bgNode = null;
            }

            if (bg) {
                switch (bg.type) {
                case PaintType.color:
                    immutable cp = cast(immutable(ColorPaint))bg;
                    _clearColor = cp.color;
                    break;
                default:
                    _clearColor.setNone();
                    _bgNode = new immutable FGRectNode(
                        FRect(0, 0, cast(FSize)size), 0f,
                        bg, none!RectBorder, CacheCookie.next()
                    );
                }
            }
            else {
                _clearColor = Color.transparent;
            }

            _bgDirty = false;
        }

        Rebindable!(immutable(FGNode)) rootNode = _root ? _root.transformRender(fc) : null;

        if (_bgNode) {
            immutable viewNode = rootNode.get;
            rootNode = new immutable FGGroupNode([
                _bgNode.get, viewNode,
            ]);
        }

        _dirtyPass &= ~UIPass.render;

        return new immutable FGFrame (
            windowHandle, IRect(0, 0, _size),
            option(_clearColor.map!(c => c.asVec)), rootNode,
            assumeUnique(fc._prune)
        );
    }

    // impl of style element

    final override @property StyleElement styleParent() {
        return null;
    }

    final override @property StyleElement styleRoot() {
        return this;
    }

    final override @property StyleElement stylePrevSibling() {
        return null;
    }

    final override @property StyleElement styleNextSibling() {
        return null;
    }

    final override @property StyleElement styleFirstChild() {
        return _root;
    }

    final override @property StyleElement styleLastChild() {
        return _root;
    }

    final override @property string inlineCSS() { return _inlineCSS; }
    /// Set the inline CSS
    final @property void inlineCSS(string css)
    {
        if (css != _inlineCSS) {
            _inlineCSS = css;
            requestPass(UIPass.style);
        }
    }

    final override @property string css() { return _css; }
    /// Set the CSS stylesheet.
    /// Can be set without surrounding rules, in such case, the declarations
    /// are surrdounding by a universal selector.
    final @property void css(string css)
    {
        import std.algorithm : canFind;
        if (!css.canFind('{')) {
            css = "*{"~css~"}";
        }
        if (css != _css) {
            _css = css;
            requestPass(UIPass.style);
        }
    }

    /// The type used in css type selector.
    /// e.g. in the following style rule, "label" is the CSS type:
    /// `label { font-family: serif; }`
    override @property string cssType() { return "ui"; }

    /// The id of this view.
    /// Used in CSS '#' selector, and for debug printing if name is not set.
    override @property string id() { return _id; }
    /// ditto
    @property void id(in string id)
    {
        if (id != _id) {
            _id = id;
            requestPass(UIPass.style);
        }
    }

    /// The CSS class of this view.
    /// Used in CSS '.' selector.
    override @property string cssClass() { return _cssClass; }
    /// ditto
    @property void cssClass(in string cssClass)
    {
        if (cssClass != _cssClass) {
            _cssClass = cssClass;
            requestPass(UIPass.style);
        }
    }

    /// A pseudo state of the view.
    override @property PseudoState pseudoState() { return _pseudoState; }


    override @property IStyleMetaProperty[] styleMetaProperties() {
        return _styleMetaProperties;
    }

    override @property IStyleProperty styleProperty(string name) {
        auto sp = name in _styleProperties;
        return sp ? *sp : null;
    }

    override @property FSize viewportSize() {
        return cast(FSize)_size;
    }

    override @property float dpi() {
        return 96f; // FIXME: get actual screen DPI
    }

    override @property bool isStyleDirty() {
        return needStylePass;
    }

    override @property bool hasChildrenStyleDirty() {
        if (!_root) return false;
        return (_root.dirtyState & View.Dirty.styleMask) != View.Dirty.clean;
    }


    package(dgt) {
        @property AnimationManager animManager() {
            return _animManager;
        }
        @property bool hasAnimations() {
            return _animManager.hasAnimations;
        }
        void tickAnimations() {
            _animManager.tick();
        }
    }

    private
    {
        void handleResize(PlResizeEvent ev)
        {
            immutable newSize = ev.size;
            _size = newSize;
            // FIXME: style and viewport size
            requestPass(UIPass.layout | UIPass.render);
        }

        void handleMouseDown(PlMouseEvent ev)
        {
            assert(ev.type == PlEventType.mouseDown);
            if (_root) {
                import std.typecons : scoped;

                const pos = ev.point;

                if (!_mouseViews.length) {
                    errorf("mouse down without prior move");
                    _root.viewsAtPos(pos, _mouseViews);
                }
                _dragChain = _mouseViews;

                if (!_mouseViews.length) {
                    error("No View under mouse?");
                    return;
                }

                auto sceneEv = scoped!MouseEvent(
                    EventType.mouseDown, _dragChain, pos, pos, ev.button, ev.state, ev.modifiers
                );
                auto consumer = sceneEv.chainToNext();
                if (consumer) {
                    // if a view has explicitely consumed the event, we trim
                    // the chain after it, such as its children won't receive
                    // the drag event.
                    import std.algorithm : countUntil;
                    auto ind = _dragChain.countUntil!"a is b"(consumer);
                    _dragChain = _dragChain[0 .. ind+1];
                }
            }
        }

        void handleMouseMove(PlMouseEvent ev)
        {
            assert(ev.type == PlEventType.mouseMove);
            if (_root) {
                import std.algorithm : swap;
                import std.typecons : scoped;

                const pos = ev.point;

                assert(!_tempViews.length);
                _root.viewsAtPos(pos, _tempViews);
                checkEnterLeave(_mouseViews, _tempViews, ev);

                swap(_mouseViews, _tempViews);
                _tempViews.length = 0;

                if (!_mouseViews.length) {
                    error("No View under mouse?");
                    return;
                }

                if (_dragChain.length) {
                    auto dragEv = scoped!MouseEvent(
                        EventType.mouseDrag, _dragChain, pos, pos,
                        ev.button, ev.state, ev.modifiers
                    );
                    dragEv.chainToNext();
                }
                else {
                    auto moveEv = scoped!MouseEvent(
                        EventType.mouseMove, _mouseViews, pos, pos,
                        ev.button, ev.state, ev.modifiers
                    );
                    moveEv.chainToNext();
                }
            }
        }

        void handleMouseUp(PlMouseEvent ev)
        {
            assert(ev.type == PlEventType.mouseUp);
            if (_root) {
                import std.typecons : scoped;

                const pos = ev.point;

                if (_dragChain.length) {
                    auto upEv = scoped!MouseEvent(
                        EventType.mouseUp, _dragChain, pos, pos,
                        ev.button, ev.state, ev.modifiers
                    );
                    upEv.chainToNext();

                    if (_mouseViews.length >= _dragChain.length &&
                        _dragChain[$-1] is _mouseViews[_dragChain.length-1])
                    {
                        // still on same view => trigger click
                        auto clickEv = scoped!MouseEvent(
                            EventType.mouseClick, _dragChain, pos, pos,
                            ev.button, ev.state, ev.modifiers
                        );
                        clickEv.chainToNext();
                    }

                    _dragChain.length = 0;
                }
                else {
                    // should not happen
                    warning("mouse up without drag?");
                    if (!_mouseViews.length) {
                        error("No View under mouse?");
                        return;
                    }
                    auto upEv = scoped!MouseEvent(
                        EventType.mouseUp, _mouseViews, pos, pos,
                        ev.button, ev.state, ev.modifiers
                    );
                    upEv.chainToNext();
                }

                _mouseViews.length = 0;
            }
        }

        void handleMouseEnter(PlMouseEvent ev)
        {
            if (_root) {
                import std.algorithm : swap;
                const pos = ev.point;

                if (_mouseViews.length) {
                    errorf("Enter window while having already nodes under mouse??");
                    _mouseViews.length = 0;
                }
                assert(!_tempViews.length);
                _root.viewsAtPos(pos, _mouseViews);
                checkEnterLeave(_tempViews, _mouseViews, ev);
            }
        }

        void handleMouseLeave(PlMouseEvent ev)
        {
            if (_root) {
                import std.algorithm : swap;
                immutable pos = cast(FPoint)ev.point;

                assert(!_tempViews.length);
                checkEnterLeave(_mouseViews, _tempViews, ev);

                swap(_mouseViews, _tempViews);
                _tempViews.length = 0;
            }
        }

        static void emitEnterLeave(View view, EventType type, PlMouseEvent src)
        {
            import std.typecons : scoped;
            const uiPos = src.point;
            auto ev = scoped!MouseEvent(
                type, [view], uiPos - view.uiPos, uiPos, src.button, src.state, src.modifiers
            );
            ev.chainToNext();
        }

        static checkEnterLeave(View[] was, View[] now, PlMouseEvent src)
        {
            import std.algorithm : min;
            const common = min(was.length, now.length);
            foreach (i; 0 .. common) {
                if (was[i] !is now[i]) {
                    emitEnterLeave(was[i], EventType.mouseLeave, src);
                    emitEnterLeave(now[i], EventType.mouseEnter, src);
                }
            }
            foreach (n; was[common .. $]) {
                emitEnterLeave(n, EventType.mouseLeave, src);
            }
            foreach (n; now[common .. $]) {
                emitEnterLeave(n, EventType.mouseEnter, src);
            }
        }


        /// give support to a style instance to a view
        private auto addStyleSupport(SMP)(SMP metaProp)
        if (is(SMP : IStyleMetaProperty) && !SMP.isShorthand)
        {
            auto sp = new SMP.Property(this, metaProp);
            _styleProperties[metaProp.name] = sp;
            if (!metaProp.hasShorthand) _styleMetaProperties ~= metaProp;
            return sp;
        }

        /// give support to a shorthand style instance to a view
        void addShorthandStyleSupport(SMP)(SMP metaProp)
        if (is(SMP : IStyleMetaProperty) && SMP.isShorthand)
        {
            _styleMetaProperties ~= metaProp;
        }

    }

    private ISize _size;
    private View _root;
    private View[] _dragChain;
    private View[] _mouseViews;
    private View[] _tempViews;
    private UIPass _dirtyPass = UIPass.all;
    private AnimationManager _animManager = new AnimationManager;

    // style
    private string _css;
    private string _inlineCSS;
    private string _id;
    private string _cssClass;
    private PseudoState _pseudoState;
    private bool _hoverSensitive;
    // style properties
    private IStyleMetaProperty[]    _styleMetaProperties;
    private IStyleProperty[string]  _styleProperties;
    private StyleProperty!RPaint    _backgroundProperty;
    // UA stylesheet
    private Stylesheet _dgtCSS;
    // caching background
    private Rebindable!(immutable(FGRectNode)) _bgNode;
    private Option!Color _clearColor;
    private bool _bgDirty;

}

enum UIPass {
    none    = 0,
    style   = 1,
    layout  = 2,
    render  = 4,
    all     = style | layout | render,
}
