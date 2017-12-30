module dgt.ui;

import dgt.core.color;
import dgt.core.geometry;
import dgt.css.om : Stylesheet;
import dgt.render.framegraph;
import dgt.ui.view : View;

import gfx.foundation.typecons : option, Option;

/// The UserInterface class represent the top level of the GUI tree.
class UserInterface {

    this() {
        // temporary hack
        _size = ISize(640, 480);
    }

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

    private ISize _size;
    private Option!Color _clearColor;
    private View _root;
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
