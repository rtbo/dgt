module dgt.scene.scene;

import dgt.core.color;
import dgt.core.geometry;
import dgt.render.framegraph;
import dgt.scene.node;

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

    immutable(FGFrame) frame(in size_t windowHandle) {
        import std.algorithm : map;
        return new immutable FGFrame (
            windowHandle, IRect(0, 0, _size),
            option(_clearColor.map!(c => c.asVec)), _root ? _root.transformRender() : null
        );
    }

    private ISize _size;
    private Option!Color _clearColor;
    private Node _root;
    private ScenePass _dirtyPass;
}

enum ScenePass {
    none    = 0,
    style   = 1,
    layout  = 2,
    render  = 4,
}
