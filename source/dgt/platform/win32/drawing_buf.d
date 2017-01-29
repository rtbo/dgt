module dgt.platform.win32.drawing_buf;

version(Windows):

import dgt.platform.win32.window;
import dgt.platform;
import dgt.geometry;
import dgt.image;
import dgt.vg;
import dgt.core.resource;

import std.exception;
import core.sys.windows.windows;
import core.sys.windows.wingdi;


private HDC createDc()
{
    auto sysDc = GetDC(null);
    auto dc = CreateCompatibleDC(sysDc);
    ReleaseDC(null, sysDc);
    return dc;
}


class DibImage : Disposable
{
    private HDC _hdc;
    private HBITMAP _bitmap;
    private HBITMAP _prevBitmap;
    private Image _img;

    this(ISize size)
    {
        _hdc = createDc();

        BITMAPINFO bmi;
        bmi.bmiHeader.biSize        = BITMAPINFOHEADER.sizeof;
        bmi.bmiHeader.biWidth       = size.width;
        bmi.bmiHeader.biHeight      = -size.height; // top-down.
        bmi.bmiHeader.biPlanes      = 1;
        bmi.bmiHeader.biSizeImage   = 0;
        bmi.bmiHeader.biBitCount    = 32;
        bmi.bmiHeader.biCompression = BI_RGB;
        void* vptr;
        _bitmap = enforce(
            CreateDIBSection(_hdc, &bmi, DIB_RGB_COLORS, &vptr, null, 0)
        );
        _prevBitmap = cast(HBITMAP)SelectObject(_hdc, _bitmap);

        auto ubptr = cast(ubyte*)vptr;
        _img = new Image(ubptr[0 .. 4*size.area], ImageFormat.argbPremult, size.width, size.width*4);
    }

    override void dispose()
    {
        SelectObject(_hdc, _prevBitmap);
        DeleteObject(_bitmap);
        DeleteDC(_hdc);
        _hdc = null;
        _bitmap = null;
        _prevBitmap = null;
        _img = null;
    }
}


class Win32DrawingBuffer : PlatformDrawingBuffer
{
    private ISize _size;
    private Win32Window _window;
    private DibImage _dibImg;
    private VgSurface _surf;

    this(Win32Window win)
    {
        _size = win.geometry.size;
        _window = win;
        _dibImg = new DibImage(_size);
        _surf = _dibImg._img.makeVgSurface();
        _surf.retain();
    }

    override void dispose()
    {
        _surf.release();
        _dibImg.dispose();

        _surf = null;
        _dibImg = null;
    }

    override @property inout(PlatformWindow) window() inout
    {
        return _window;
    }

    override @property ISize size() const
    {
        return _size;
    }

    override @property void size(in ISize size)
    {
        if (_size == size) return;

        _size = size;
        _surf.release();
        _dibImg.dispose();

        _dibImg = new DibImage(_size);
        _surf = _dibImg._img.makeVgSurface();
        _surf.retain();
    }

    override @property VgSurface surface()
    {
        return _surf;
    }

    override void flush()
    {
        auto dc = _window.getDC();
        scope(exit) _window.releaseDC(dc);

        BitBlt(
            dc, 0, 0, _size.width, _size.height,
            _dibImg._hdc, 0, 0,
            SRCCOPY
        );
    }
}
