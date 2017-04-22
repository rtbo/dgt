module dgt.platform.win32.context;
version(Windows):

import dgt.platform;
import dgt.platform.win32;
import dgt.platform.win32.window;
import dgt.context;
import dgt.window;
import dgt.screen;

import gfx.foundation.util : unsafeCast;

import derelict.opengl3.gl3;
import derelict.opengl3.wglext;

import std.exception;
import std.experimental.logger;
import core.sys.windows.wingdi;
import core.sys.windows.windef;
import core.sys.windows.winuser;

package:

void initWin32Gl()
{
    DerelictGL3.load();

    immutable attribs = GlAttribs.init;

    PIXELFORMATDESCRIPTOR pfd = void;
    setupPFD(attribs, pfd);

    auto dummy = new Window("Dummy context window", WindowFlags.dummy);
    dummy.show();
    scope(exit) dummy.close();

    auto pDummy = unsafeCast!Win32Window(dummy.platformWindow);
    auto dc = GetDC(pDummy.handle);
    scope(exit) ReleaseDC(pDummy.handle, dc);

    auto chosen = ChoosePixelFormat(dc, &pfd);
    SetPixelFormat(dc, chosen, &pfd);

    auto glrc = wglCreateContext(dc);
    scope(exit) wglDeleteContext(glrc);

    wglMakeCurrent(dc, glrc);
    scope(exit) wglMakeCurrent(null, null);

    DerelictGL3.reload();

    enforce(WGL_ARB_create_context && WGL_ARB_pixel_format);
}


shared(GlContext) createWin32GlContext(GlAttribs attribs, PlatformWindow window,
                                   shared(GlContext)sharedCtx, Screen screen)
{
    auto wnd = cast(HWND)window.nativeHandle;
    auto dc = GetDC(wnd);
    scope(exit) ReleaseDC(wnd, dc);

    int[] attribList = [
        WGL_DRAW_TO_WINDOW_ARB,     GL_TRUE,
        WGL_SUPPORT_OPENGL_ARB,     GL_TRUE,
        WGL_PIXEL_TYPE_ARB,         WGL_TYPE_RGBA_ARB,
        WGL_COLOR_BITS_ARB,         attribs.colorSize,
        WGL_DEPTH_BITS_ARB,         attribs.depthSize,
        WGL_STENCIL_BITS_ARB,       attribs.stencilSize,
    ];
    if (attribs.hasSamples) {
        attribList ~= [
            WGL_SAMPLE_BUFFERS_ARB,     GL_TRUE,
            WGL_SAMPLES_ARB,            attribs.samples,
        ];
    }
    attribList ~= 0;
    int pixelFormat;
    uint numFormats;
    wglChoosePixelFormatARB(dc, attribList.ptr, null, 1, &pixelFormat, &numFormats);

    enforce(numFormats > 0);
    PIXELFORMATDESCRIPTOR pfd = void;
    setupPFD(attribs, pfd);
    SetPixelFormat(dc, pixelFormat, &pfd);

    int[] ctxAttribs = [
        WGL_CONTEXT_MAJOR_VERSION_ARB, attribs.majorVersion,
        WGL_CONTEXT_MINOR_VERSION_ARB, attribs.minorVersion
    ];
    if (attribs.decimalVersion >= 32) {
        ctxAttribs ~= WGL_CONTEXT_PROFILE_MASK_ARB;
        if (attribs.profile == GlProfile.core) {
            ctxAttribs ~= WGL_CONTEXT_CORE_PROFILE_BIT_ARB;
        }
        else {
            ctxAttribs ~= WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB;
        }
    }
    ctxAttribs ~= 0;

    auto w32glc = cast(shared(Win32GlContext)) sharedCtx;
    HGLRC sharedGlrc = w32glc ? cast(HGLRC)w32glc._glrc : null;
    auto glrc = wglCreateContextAttribsARB(dc, sharedGlrc, ctxAttribs.ptr);

    if (glrc) {
        auto ctx = new shared(Win32GlContext)(glrc, attribs);
        auto mutCtx = cast(Win32GlContext)ctx;
        mutCtx.makeCurrent(window.nativeHandle);
        scope(exit) mutCtx.doneCurrent();

        DerelictGL3.reload();

        return ctx;
    }
    else {
        return null;
    }
}


private:

final class Win32GlContext : GlContext
{
    private HGLRC _glrc;
    private GlAttribs _attribs;

    shared this(HGLRC glrc, GlAttribs attribs) {
        _glrc = cast(shared(HGLRC))glrc;
        _attribs = attribs;
    }

    override void dispose()
    {
        wglDeleteContext(_glrc);
    }

    override @property GlAttribs attribs() const { return _attribs; }

    override bool makeCurrent(size_t nativeHandle)
    {
        auto wnd = cast(HWND)nativeHandle;
        auto dc = GetDC(wnd);
        scope(exit) ReleaseDC(wnd, dc);
        return wglMakeCurrent(dc, _glrc) != 0;
    }

    override void doneCurrent()
    {
        wglMakeCurrent(null, null);
    }

    override void swapBuffers(size_t nativeHandle)
    {
        auto wnd = cast(HWND)nativeHandle;
        auto dc = GetDC(wnd);
        scope(exit) ReleaseDC(wnd, dc);
        SwapBuffers(dc);
    }
}


void setupPFD(in GlAttribs attribs, out PIXELFORMATDESCRIPTOR pfd)
{
    pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
    pfd.nVersion = 1;

    pfd.dwFlags = PFD_SUPPORT_OPENGL | PFD_DRAW_TO_WINDOW;
    if (attribs.doublebuffer) pfd.dwFlags |= PFD_DOUBLEBUFFER;

    pfd.iPixelType = PFD_TYPE_RGBA;

    pfd.cColorBits = attribs.colorSize;
    pfd.cRedBits = attribs.redSize;
    pfd.cRedShift = attribs.redShift;
    pfd.cGreenBits = attribs.greenSize;
    pfd.cGreenShift = attribs.greenShift;
    pfd.cBlueBits = attribs.blueSize;
    pfd.cBlueShift = attribs.blueShift;
    pfd.cAlphaBits = attribs.alphaSize;
    pfd.cAlphaShift = attribs.alphaShift;
    pfd.cDepthBits = attribs.depthSize;
    pfd.cStencilBits = attribs.stencilSize;

    pfd.iLayerType = PFD_MAIN_PLANE;
}

