module dgt.platform.xcb.buffer;

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



class XcbWindowBuffer : PlatformWindowBuffer
{
    private XcbWindow _window;
    private ISize _size;
    private ubyte _depth;
    private xcb_image_t* _xcbImg;
    private int _shmFd;
    private xcb_shm_segment_info_t _shmInfo;
    private string _shmName;
    private Image _img;

    this(XcbWindow window, in ISize size)
    {
        import dgt.platform.linux : createMmapableFile;

        _window = window;
        _size = size;
        _depth = cast(ubyte)window.depth;

        auto format = window.xcbFormat;

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

    override @property inout(Image) image() inout
    {
        return _img;
    }

    override @property inout(PlatformWindow) window() inout
    {
        return _window;
    }

    void blit(in IPoint orig, in ISize size)
    in {
        assert(orig.x + size.width <= _size.width);
        assert(orig.y + size.height <= _size.height);
    }
    body
    {
        xcb_shm_put_image(g_connection,
                _window.xcbWin, _window.xcbGc,
                cast(ushort)_size.width,        // total size
                cast(ushort)_size.height,
                cast(short)orig.x,              // src point
                cast(short)orig.y,
                cast(ushort)size.width,         // source size
                cast(ushort)size.height,
                cast(short)orig.x,              // dest point
                cast(short)orig.y,

                _depth, cast(ubyte)_xcbImg.format,
                0, _shmInfo.shmseg,
                cast(uint)(_xcbImg.data - _shmInfo.shmaddr));
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
