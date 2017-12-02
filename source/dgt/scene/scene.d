module dgt.scene.scene;

import dgt.core.color;
import dgt.core.geometry;
import dgt.scene.node;

/// The Scene class represent the scene graph scene.
/// It is a standalone representation of a scene graph.
class Scene {

    @property ISize size() {
        return _size;
    }

    @property Color clearColor()
    {
        return _clearColor;
    }
    @property void clearColor(in Color color)
    {
        _clearColor = color;
        _hasClearColor = true;
    }
    @property bool hasClearColor()
    {
        return _hasClearColor;
    }
    @property void hasClearColor(bool has)
    {
        _hasClearColor = has;
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

    private ISize _size;
    private Color _clearColor;
    private bool _hasClearColor;
    private Node _root;
    private ScenePass _dirtyPass;
}

enum ScenePass {
    none    = 0,
    style   = 1,
    layout  = 2,
    render  = 4,
}
