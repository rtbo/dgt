/// Image view module
module dgt.ui.img;

import dgt.core.geometry;
import dgt.core.image;
import dgt.core.paint;
import gfx.math;
import dgt.ui.layout;
import dgt.ui.view;
import dgt.render.framegraph;
import gfx.core.typecons;

import std.typecons;

class ImageView : View
{
    this() {}

    final @property immutable(Image) image()
    {
        return _img;
    }

    final @property void image(immutable(Image) image)
    {
        _img = image;
        _dirty = true;
        invalidate();
    }

    override @property string cssType()
    {
        return "img";
    }

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        if (_img) {
            measurement = cast(FSize)_img.size;
        }
        else {
            super.measure(widthSpec, heightSpec);
        }
    }

    override immutable(FGNode) render(FrameContext fc) {
        if (_dirty && _fgNode) {
            immutable node = _fgNode.get;
            fc.prune(node.cookie);
            _fgNode = null;
        }
        if (_dirty && _img) {
            immutable img = _img.get;
            _fgNode = new immutable(FGRectNode)(
                localRect, 0, new immutable(ImagePaint)(img),
                none!RectBorder, CacheCookie.next()
            );
            _dirty = false;
        }
        return _fgNode.get;
    }

    private Rebindable!(immutable(FGRectNode)) _fgNode;
    private Rebindable!(immutable(Image)) _img;
    bool _dirty;
}
