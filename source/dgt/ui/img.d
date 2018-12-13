/// Image view module
module dgt.ui.img;

import dgt.gfx.geometry;
import dgt.gfx.image;
import dgt.gfx.paint;
import dgt.render.framegraph;
import dgt.ui.layout;
import dgt.ui.view;
import gfx.core.typecons;
import gfx.math;

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
        _dirty |= ImgDirty.img;
        invalidate();
        requestLayoutPass();
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

    override void layout(in FRect rect)
    {
        _dirty |= ImgDirty.layout;
        super.layout(rect);
    }

    override immutable(FGNode) frame(FrameContext fc)
    {
        if (_dirty.img) {
            if (_fgNode) fc.prune(_fgNode.cookie);
            immutable img = _img.get;
            _fgNode = new immutable(FGRectNode)(
                localRect, 0, new immutable(ImagePaint)(img),
                none!RectBorder, CacheCookie.next()
            );
        }
        else if (_dirty.layout) {
            immutable img = _img.get;
            const cookie = _fgNode ? _fgNode.cookie : CacheCookie.next();
            _fgNode = new immutable FGRectNode (
                cast(FRect)localRect, 0, new immutable ImagePaint(img),
                none!RectBorder, cookie
            );
        }
        _dirty = BitFlags!ImgDirty.init;

        return _fgNode.get;
    }

    private Rebindable!(immutable(FGRectNode)) _fgNode;
    private Rebindable!(immutable(Image)) _img;
    private enum ImgDirty {
        img     = 1,
        layout  = 2,
    }
    private BitFlags!ImgDirty _dirty;
}
