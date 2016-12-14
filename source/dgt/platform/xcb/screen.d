module dgt.platform.xcb.screen;

import dgt.screen;

import xcb.xcb;

/// Xcb implementation of Screen
class XcbScreen : Screen
{
    private int num_;
    private xcb_screen_t s_;

    this(int num, xcb_screen_t *s)
    {
        num_ = num;
        s_ = *s;
    }

    override @property int num() const { return num_; }

    override @property int width() const { return s_.width_in_pixels; }

    override @property int height() const { return s_.height_in_pixels; }

    override @property double dpi() const
    {
        return width / (s_.width_in_millimeters / 25.4);
    }

    @property xcb_window_t root() const { return s_.root; }
    @property ubyte rootDepth() const { return s_.root_depth; }
    @property xcb_visualid_t rootVisual() const { return s_.root_visual; }
    @property uint whitePixel() const { return s_.white_pixel; }
    @property uint blackPixel() const { return s_.black_pixel; }

}
