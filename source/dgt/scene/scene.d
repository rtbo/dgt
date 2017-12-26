module dgt.scene.scene;

import dgt.core.color;
import dgt.core.geometry;
import dgt.css.om : Stylesheet;
import dgt.render.framegraph;
import dgt.scene.node : Node;
import dgt.ui.view : View;

import gfx.foundation.typecons : option, Option;

/// The Scene class represent the scene graph scene.
/// It is a standalone representation of a scene graph.
class Scene {

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

    /// The scene graph root attached to this window
    @property inout(Node) root() inout { return _root; }
    /// ditto
    @property void root(Node root)
    {
        if (_root) {
            _root._scene = null;
        }
        _root = root;
        if (_root) {
            _root._scene = this;
        }
    }


    @property ScenePass dirtyPass() {
        return _dirtyPass;
    }

    void requestPass(in ScenePass pass) {
        _dirtyPass |= pass;
    }

    @property bool needStylePass() {
        return (_dirtyPass & ScenePass.style) == ScenePass.style;
    }

    @property bool needLayoutPass() {
        return (_dirtyPass & ScenePass.layout) == ScenePass.layout;
    }

    @property bool needRenderPass() {
        return (_dirtyPass & ScenePass.render) == ScenePass.render;
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
        _root.recursClean(Node.Dirty.styleMask);
        _dirtyPass &= ~ScenePass.style;
    }

    void layoutPass () {
        if (!_root) return;

        // at the moment the only supported layout mode is with view at the root
        auto v = cast(View) _root;
        if (!v) return;
        import dgt.ui.layout : MeasureSpec;
        auto fs = cast(FSize) _size;
        v.measure(
            MeasureSpec.makeAtMost(fs.width),
            MeasureSpec.makeAtMost(fs.height)
        );
        v.layout(FRect(0, 0, fs));
        _dirtyPass &= ~ScenePass.layout;
    }

    immutable(FGFrame) frame(in size_t windowHandle) {
        import std.algorithm : map;
        scope(success) {
            _dirtyPass &= ~ScenePass.render;
        }
        return new immutable FGFrame (
            windowHandle, IRect(0, 0, _size),
            option(_clearColor.map!(c => c.asVec)), _root ? _root.transformRender() : null
        );
    }

    private View[] getViewRoots() {
        import std.algorithm : each;
        View [] roots;
        void collect(Node n) {
            auto v = cast(View) n;
            if (v) roots ~= v;
            else {
                n.children.each!(c => collect(c));
            }
        }
        if (_root) collect(_root);
        return roots;
    }

    private ISize _size;
    private Option!Color _clearColor;
    private Node _root;
    private ScenePass _dirtyPass = ScenePass.all;
    private Stylesheet _dgtCSS;
}

enum ScenePass {
    none    = 0,
    style   = 1,
    layout  = 2,
    render  = 4,
    all     = style | layout | render,
}
