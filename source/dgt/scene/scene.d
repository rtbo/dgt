module dgt.scene.scene;

import dgt.core.geometry;
import dgt.scene.node;

class Scene {

    @property ISize size() {
        return _size;
    }

    private ISize _size;
}
