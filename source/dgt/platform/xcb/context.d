module dgt.platform.xcb.context;

version(linux):

import dgt.platform;
import dgt.platform.xcb;
import dgt.platform.xcb.screen;
import dgt.platform.xcb.window;
import dgt.gfx;
import dgt.screen;

import gfx.foundation.util : unsafeCast;

import X11.Xlib;
import xcb.xcb;
import derelict.opengl3.gl3;
import derelict.opengl3.glx;
import derelict.opengl3.glxext;

import std.typecons;
import std.exception;
import std.format;
import std.experimental.logger;

alias Screen = dgt.screen.Screen;

xcb_visualtype_t* getXcbVisualForId(in XcbScreen screen, xcb_visualid_t visualId)
{
    auto vt = findXcbVisualInScreen(screen, visualId);
    if (!vt)
        throw new Exception("getXcbVisualForId: visual not found for given screen");
    return vt;
}

xcb_visualtype_t* getXcbVisualForId(in XcbScreen[] screens, xcb_visualid_t visualId)
{
    foreach (s; screens)
    {
        auto vt = findXcbVisualInScreen(s, visualId);
        if (vt)
            return vt;
    }
    throw new Exception("getXcbVisualForId: visual not found for given screens");
}

xcb_visualtype_t* getXcbDefaultVisualOfScreen(in XcbScreen screen)
{
    return getXcbVisualForId(screen, screen.rootVisual);
}

/// Returned data should be freed with XFree.
XVisualInfo* getXlibVisualInfo(Display* dpy, int screenNum, in GlAttribs attribs)
{
    auto fbc = getGlxFBConfig(dpy, screenNum, attribs);
    if (!fbc)
        return null;
    return glXGetVisualFromFBConfig(dpy, fbc);
}


class XcbGlContext : PlatformGlContext
{
    private GLXContext _context;
    private int _screenNum;

    override bool realize(GlAttribs attribs,
                    PlatformWindow window,
                    PlatformGlContext sharedCtx,
                    Screen screen)
    {
        _screenNum = screen ? screen.num() : XDefaultScreen(g_display);
        auto fbc = getGlxFBConfig(g_display, _screenNum, attribs);

        auto xWin = unsafeCast!XcbWindow(window);

        if (!glXCreateContextAttribsARB) {
            auto dummyCtx = enforce(
                glXCreateNewContext(g_display, fbc, GLX_RGBA_TYPE, null, true)
            );
            glXMakeCurrent(g_display, xWin.xcbWin, dummyCtx);

            DerelictGL3.reload();

            glXMakeCurrent(g_display, 0, null);
            glXDestroyContext(g_display, dummyCtx);
        }

        enforce(GLX_ARB_create_context);

        int[] ctxAttribs = [
            GLX_CONTEXT_MAJOR_VERSION_ARB, attribs.majorVersion,
            GLX_CONTEXT_MINOR_VERSION_ARB, attribs.minorVersion
        ];
        if (attribs.decimalVersion >= 32) {
            ctxAttribs ~= GLX_CONTEXT_PROFILE_MASK_ARB;
            if (attribs.profile == GlProfile.core) {
                ctxAttribs ~= GLX_CONTEXT_CORE_PROFILE_BIT_ARB;
            }
            else {
                ctxAttribs ~= GLX_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB;
            }
        }
        ctxAttribs ~= 0;

        GLXContext shCtx = sharedCtx ?
                unsafeCast!XcbGlContext(sharedCtx)._context :
                null;
        _context = enforce(
            glXCreateContextAttribsARB(g_display, fbc, shCtx, 1, &ctxAttribs[0])
        );

        XSync(g_display, false);

        return _context != null;
    }

    override bool makeCurrent(PlatformWindow window)
    {
        auto xWin = unsafeCast!XcbWindow(window);
        return glXMakeCurrent(g_display, xWin.xcbWin, _context) != 0;
    }

    override void doneCurrent()
    {
        glXMakeCurrent(g_display, 0, null);
    }

    override void swapBuffers(PlatformWindow window)
    {
        auto xWin = unsafeCast!XcbWindow(window);
        glXSwapBuffers(g_display, xWin.xcbWin);
    }
}


private GLXFBConfig getGlxFBConfig(Display* dpy, int screenNum, in GlAttribs attribs)
{
    auto glxAttribs = getGlxAttribs(attribs);

    int numConfigs;
    GLXFBConfig* fbConfigs = glXChooseFBConfig(dpy, screenNum, &glxAttribs[0], &numConfigs);

    if (!fbConfigs || !numConfigs)
    {
        critical("DGT-XCB: could not get fb config");
        return null;
    }
    scope (exit)
        XFree(fbConfigs);

    return fbConfigs[0];
}

private xcb_visualtype_t* findXcbVisualInScreen(in XcbScreen screen, xcb_visualid_t visualId)
{
    auto depthIter = xcb_screen_allowed_depths_iterator(screen.xcbScreen);
    while (depthIter.rem)
    {
        auto visualIter = xcb_depth_visuals_iterator(depthIter.data);
        while (visualIter.rem)
        {
            if (visualId == visualIter.data.visual_id)
                return visualIter.data;
            xcb_visualtype_next(&visualIter);
        }
        xcb_depth_next(&depthIter);
    }
    return null;
}

private int[] getGlxAttribs(in GlAttribs attribs)
{
    int[] glxAttribs = [
        GLX_X_RENDERABLE,   1,
        GLX_DRAWABLE_TYPE,  GLX_WINDOW_BIT,
        GLX_RENDER_TYPE,    GLX_RGBA_BIT,
        GLX_X_VISUAL_TYPE,  GLX_TRUE_COLOR
    ];

    if (attribs.redSize)
        glxAttribs ~= [GLX_RED_SIZE, attribs.redSize];
    if (attribs.greenSize)
        glxAttribs ~= [GLX_GREEN_SIZE, attribs.greenSize];
    if (attribs.blueSize)
        glxAttribs ~= [GLX_BLUE_SIZE, attribs.blueSize];
    if (attribs.hasAlpha)
        glxAttribs ~= [GLX_ALPHA_SIZE, attribs.alphaSize];

    if (attribs.depthSize)
        glxAttribs ~= [GLX_DEPTH_SIZE, attribs.depthSize];
    if (attribs.hasStencil)
        glxAttribs ~= [GLX_STENCIL_SIZE, attribs.stencilSize];

    if (attribs.doublebuffer)
        glxAttribs ~= [GLX_DOUBLEBUFFER, 1];

    if (attribs.hasSamples)
    {
        glxAttribs ~= [GLX_SAMPLE_BUFFERS, 1, GLX_SAMPLES, attribs.samples];
    }

    return glxAttribs ~ 0;
}
