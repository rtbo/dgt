module dgt.platform.win32.buffer;

version(Windows):

import dgt.platform.win32.window;
import dgt.platform;
import dgt.geometry;
import dgt.image;
import dgt.vg;
import gfx.foundation.rc;

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


class Win32WindowBuffer : PlatformWindowBuffer
{
    private Win32Window _window;
    private ISize _size;

    private HDC _hdc;
    private HBITMAP _bitmap;
    private HBITMAP _prevBitmap;
    private Image _img;

    this(Win32Window win, in ISize size)
    {
        _window = win;
        _size = size;
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

    override @property inout(PlatformWindow) window() inout
    {
        return _window;
    }

    override @property inout(Image) image() inout
    {
        return _img;
    }

    override void blit(in IPoint orig, in ISize size)
    in {
        assert(orig.x + size.width <= _size.width);
        assert(orig.y + size.height <= _size.height);
    }
    body
    {
        auto dc = _window.getDC();
        scope(exit) _window.releaseDC(dc);

        BitBlt(
            dc, orig.x, orig.y, size.width, size.height,
            _hdc, orig.x, orig.y,
            SRCCOPY
        );
    }
}
