module dgt.platform.xcb.drawing_buffer;

version(linux):

import dgt.platform.xcb;
import dgt.platform.xcb.window;
import dgt.platform;
import dgt.core.resource;
import dgt.geometry;
import dgt.vg;
import dgt.image;

import dgt.bindings.cairo;

import xcb.xcb;
import xcb.shm;
import xcb.image;

import std.exception : enforce;
import std.conv : octal;
import std.string : toStringz;

import core.sys.posix.sys.mman;
import core.sys.posix.unistd;



class XcbShmImage : Disposable
{
    private ISize _size;
    private ubyte _depth;
    private xcb_image_t* _xcbImg;
    private int _shmFd;
    private xcb_shm_segment_info_t _shmInfo;
    private string _shmName;
    private Image _img;

    this(ISize size, xcb_format_t* format)
    {
        import dgt.platform.linux : createMmapableFile;
        _size = size;
        _depth = format.depth;
        _xcbImg = xcb_image_create(
            cast(ushort)size.width, cast(ushort)size.height,
            XCB_IMAGE_FORMAT_Z_PIXMAP, format.scanline_pad, format.depth,
            format.bits_per_pixel, format.bits_per_pixel, xcbImageOrder,
            XCB_IMAGE_ORDER_MSB_FIRST, null, ~0, null
        );
        immutable segSize = _xcbImg.stride * _xcbImg.height;

        _shmFd = createMmapableFile(segSize);

        _shmInfo.shmaddr = cast(ubyte*)enforce(mmap(
            null, segSize, PROT_READ | PROT_WRITE, MAP_SHARED, _shmFd, 0
        ));
        _xcbImg.data = _shmInfo.shmaddr;
        _shmInfo.shmseg = xcb_generate_id(g_connection);

        auto err = xcb_request_check(g_connection, xcb_shm_attach_fd_checked(
            g_connection, _shmInfo.shmseg, _shmFd, 0
        ));

        _img = new Image(
            _xcbImg.data[0 .. segSize], dgtImageFormat(format),
            _xcbImg.width, _xcbImg.stride
        );
    }

    override void dispose()
    {
        xcb_shm_detach(g_connection, _shmInfo.shmseg);
        munmap(_xcbImg.data, _xcbImg.stride * _xcbImg.height);
        _xcbImg.data = null;
        xcb_image_destroy(_xcbImg);
        close(_shmFd);
        _shmFd = 0;
        _xcbImg = null;
        _img = null;
    }

    void put(xcb_drawable_t dst, xcb_gcontext_t gc)
    {
        immutable w = cast(ushort)_size.width;
        immutable h = cast(ushort)_size.height;
        xcb_shm_put_image(g_connection,
                dst, gc,
                w, h, 0, 0, w, h, 0, 0,
                _depth, cast(ubyte)_xcbImg.format,
                0, _shmInfo.shmseg,
                cast(uint)(_xcbImg.data - _shmInfo.shmaddr));
    }
}


class XcbPixmap : Disposable
{
    private xcb_drawable_t handle;

    this(xcb_drawable_t baseDrawable, ubyte depth, ISize size)
    {
        handle = xcb_generate_id(g_connection);
        xcb_create_pixmap(
            g_connection, depth, handle, baseDrawable,
            cast(ushort)size.width, cast(ushort)size.height
        );
    }

    override void dispose()
    {
        xcb_free_pixmap(g_connection, handle);
    }
}


class XcbDrawingBuffer : PlatformDrawingBuffer
{
    private ISize _size;
    private ubyte _depth;
    private xcb_visualtype_t* _visual;
    private XcbWindow _window;
    private XcbShmImage _shmImage;
    private VgSurface _surface;

    private xcb_gcontext_t _gc;

    this(XcbWindow window)
    {
        _size = window.geometry.size;
        _depth = cast(ubyte)window.depth;
        _visual = window.xcbVisual;
        _window = window;

        _shmImage = new XcbShmImage(_size, window.xcbFormat);
        _surface = _shmImage._img.makeVgSurface();
        _surface.retain();


        immutable uint mask = XCB_GC_GRAPHICS_EXPOSURES;
        immutable uint values = 0;

        _gc = xcb_generate_id(g_connection);
        xcb_create_gc(g_connection, _gc, _window.xcbWin, mask, &values);
    }

    override ISize size() const
    {
        return _size;
    }

    override void size(in ISize size)
    {
        if (size == _size) return;

        _size = size;
        _shmImage.dispose();
        _surface.flush();
        _surface.release();

        _shmImage = new XcbShmImage(_size, _window.xcbFormat);
        _surface = _shmImage._img.makeVgSurface();
        _surface.retain();
    }

    override void dispose()
    {
        _shmImage.dispose();
        _surface.release();
        _shmImage = null;
        _surface = null;
    }

    override @property VgSurface surface()
    {
        return _surface;
    }

    override @property inout(PlatformWindow) window() inout
    {
        return _window;
    }

    override void flush()
    {
        _surface.flush();
        _shmImage.put(_window.xcbWin, _gc);
    }
}

private:

version(BigEndian)
{
    enum xcbImageOrder = XCB_IMAGE_ORDER_MSB_FIRST;
}
else
{
    enum xcbImageOrder = XCB_IMAGE_ORDER_LSB_FIRST;
}
