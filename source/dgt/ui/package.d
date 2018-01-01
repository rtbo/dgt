module dgt.ui;

import dgt.core.color;
import dgt.core.geometry;
import dgt.css.om : Stylesheet;
import dgt.platform.event;
import dgt.render.framegraph;
import dgt.ui.event;
import dgt.ui.view : View;

import gfx.foundation.typecons : option, Option;

import std.experimental.logger;

/// The UserInterface class represent the top level of the GUI tree.
class UserInterface {

    this() {}

    @property ISize size() {
        return _size;
    }

    @property Option!Color clearColor()
    {
        return _clearColor;
    }
    @property void clearColor(in Option!Color color)
    {
        _clearColor = color;
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
        if (!_root) return;
        if (!_size.area) return;

        import dgt.css.cascade : cssCascade;
        import dgt.css.parse : parseCSS;
        import dgt.css.style : Origin;

        if (!_dgtCSS) {
            _dgtCSS = parseCSS(cast(string)import("dgt.css"), null, Origin.dgt);
        }
        cssCascade(_root, _dgtCSS);
        _root.recursClean(View.Dirty.styleMask);
        _dirtyPass &= ~UIPass.style;
    }

    void layoutPass () {
        if (!_root) return;
        if (!_size.area) return;

        import dgt.ui.layout : MeasureSpec;
        auto fs = cast(FSize) _size;
        _root.measure(
            MeasureSpec.makeAtMost(fs.width),
            MeasureSpec.makeAtMost(fs.height)
        );
        _root.layout(FRect(0, 0, fs));
        _dirtyPass &= ~UIPass.layout;
    }

    immutable(FGFrame) frame(in size_t windowHandle) {
        import std.algorithm : map;
        scope(success) {
            _dirtyPass &= ~UIPass.render;
        }
        return new immutable FGFrame (
            windowHandle, IRect(0, 0, _size),
            option(_clearColor.map!(c => c.asVec)), _root ? _root.transformRender() : null
        );
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

                immutable pos = cast(FVec2)ev.point;

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

                immutable pos = cast(FPoint)ev.point;

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

                immutable pos = cast(FVec2)ev.point;

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
                immutable pos = cast(FPoint)ev.point;

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
            immutable uiPos = cast(FPoint)src.point;
            auto ev = scoped!MouseEvent(
                type, [view], uiPos - view.uiPos, uiPos, src.button, src.state, src.modifiers
            );
            ev.chainToNext();
        }

        static checkEnterLeave(View[] was, View[] now, PlMouseEvent src)
        {
            import std.algorithm : min;
            immutable common = min(was.length, now.length);
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

    }

    private ISize _size;
    private Option!Color _clearColor;
    private View _root;
    private View[] _dragChain;
    private View[] _mouseViews;
    private View[] _tempViews;
    private UIPass _dirtyPass = UIPass.all;
    private Stylesheet _dgtCSS;
}

enum UIPass {
    none    = 0,
    style   = 1,
    layout  = 2,
    render  = 4,
    all     = style | layout | render,
}
