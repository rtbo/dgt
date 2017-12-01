module dgt.scene.scene;

import dgt.core.geometry;
import dgt.scene.node;

class Scene {

    @property ISize size() {
        return _size;
    }

    @property ScenePass dirtyPass() {
        return _dirtyPass;
    }

    void requestPass(in ScenePass pass) {
        _dirtyPass |= pass;
    }

    private ISize _size;
    private ScenePass _dirtyPass;
}

enum ScenePass {
    none    = 0,
    style   = 1,
    layout  = 2,
    render  = 4,
}
