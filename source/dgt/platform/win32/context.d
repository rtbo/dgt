module dgt.platform.win32.context;

import dgt.platform;
import dgt.platform.win32;
import dgt.platform.win32.window;
import dgt.core.util;
import dgt.gfx;
import dgt.window;
import dgt.screen;

import derelict.opengl3.gl3;
import derelict.opengl3.wglext;

import std.exception;
import std.experimental.logger;
import core.sys.windows.wingdi;

package void initWin32Gl()
{
    DerelictGL3.load();

    auto dummy = new Window("Dummy context window", WindowFlags.dummy);
    dummy.show();

    immutable attribs = dummy.attribs;

    PIXELFORMATDESCRIPTOR pfd;
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

    auto pDummy = unsafeCast!Win32Window(dummy.platformWindow);
    auto dc = pDummy.getDC();
    auto chosen = ChoosePixelFormat(dc, &pfd);
    SetPixelFormat(dc, chosen, &pfd);

    auto glrc = wglCreateContext(dc);
    wglMakeCurrent(dc, glrc);

    DerelictGL3.reload();

    wglMakeCurrent(null, null);
    wglDeleteContext(glrc);

    enforce(wglCreateContextAttribsARB);

    dummy.close();
}


class Win32GlContext : PlatformGlContext
{
    override bool realize(GlAttribs attribs,
                    PlatformWindow window,
                    PlatformGlContext sharedCtx,
                    Screen screen)
    {
        return false;
    }

    override bool makeCurrent(PlatformWindow window)
    {
        return false;
    }

    override void doneCurrent()
    {

    }

    override void swapBuffers(PlatformWindow window)
    {

    }
}
