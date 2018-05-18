module dgt.platform.xcb.screen;

version(linux):

import dgt.core.geometry;
import dgt.screen;

import xcb.xcb;

/// Xcb implementation of Screen
class XcbScreen : Screen
{
    private int _num;
    private xcb_screen_t* _s; // pointer invalidated after xcb connection shutdown

    this(int num, xcb_screen_t* s)
    {
        _num = num;
        _s = s;
    }

    override @property int num() const
    {
        return _num;
    }

    override @property IRect rect() const
    {
        return IRect(0, 0, _s.width_in_pixels, _s.height_in_pixels);
    }

    override @property double dpi() const
    {
        return _s.width_in_pixels / (_s.width_in_millimeters / 25.4);
    }

    @property inout(xcb_screen_t*) xcbScreen() inout
    {
        return _s;
    }

    @property xcb_window_t root() const
    {
        return _s.root;
    }

    @property xcb_colormap_t defaultColormap() const
    {
        return _s.default_colormap;
    }

    @property uint whitePixel() const
    {
        return _s.white_pixel;
    }

    @property uint blackPixel() const
    {
        return _s.black_pixel;
    }

    @property xcb_visualid_t rootVisual() const
    {
        return _s.root_visual;
    }

    @property ubyte rootDepth() const
    {
        return _s.root_depth;
    }

}
