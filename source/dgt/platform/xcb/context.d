module dgt.platform.xcb.context;

version(linux):

import dgt.platform;
import dgt.platform.xcb;
import dgt.platform.xcb.screen;
import dgt.platform.xcb.window;
import dgt.context;
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

package:

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

shared(GlContext) createXcbGlContext(GlAttribs attribs, PlatformWindow window,
                                     shared(GlContext)sharedCtx, Screen screen)
{
    auto screenNum = screen ? screen.num() : XDefaultScreen(g_display);
    auto fbc = getGlxFBConfig(g_display, screenNum, attribs);

    if (!glXCreateContextAttribsARB) {
        auto dummyCtx = enforce(
            glXCreateNewContext(g_display, fbc, GLX_RGBA_TYPE, null, true)
        );
        glXMakeCurrent(g_display, cast(xcb_window_t)window.nativeHandle, dummyCtx);

        immutable glVer = cast(GLVersion)attribs.decimalVersion;
        DerelictGL3.reload(glVer, glVer);

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

    auto xcbCtx = cast(shared(XcbGlContext))sharedCtx;
    auto shCtx = xcbCtx ? xcbCtx._context : null;
    auto glxCtx = enforce(
        glXCreateContextAttribsARB(g_display, fbc, cast(GLXContext)shCtx, 1, &ctxAttribs[0])
    );

    XSync(g_display, false);

    if (glxCtx) {
        auto ctx = new shared(XcbGlContext)(glxCtx, attribs);
        auto mutCtx = cast(XcbGlContext)ctx;
        mutCtx.makeCurrent(window.nativeHandle);
        scope(exit) mutCtx.doneCurrent();

        immutable glVer = cast(GLVersion)attribs.decimalVersion;
        DerelictGL3.reload(glVer, glVer);

        return ctx;
    }
    else {
        return null;
    }
}

private:

final class XcbGlContext : GlContext
{
    private GLXContext _context;
    private GlAttribs _attribs;

    shared this (GLXContext context, GlAttribs attribs)
    {
        _context = cast(shared(GLXContext))context;
        _attribs = attribs;
    }

    override void dispose()
    {
        glXDestroyContext(g_display, _context);
        _context = null;
    }

    override @property GlAttribs attribs() const
    {
        return _attribs;
    }

    override bool makeCurrent(size_t nativeHandle)
    {
        auto xWin = cast(xcb_window_t)nativeHandle;
        return glXMakeCurrent(g_display, xWin, _context) != 0;
    }

    override void doneCurrent()
    {
        glXMakeCurrent(g_display, 0, null);
    }

    override @property int swapInterval()
    {
        Display *dpy = glXGetCurrentDisplay();
        GLXDrawable drawable = glXGetCurrentDrawable();
        uint swap;

        if (drawable) {
            glXQueryDrawable(dpy, drawable, GLX_SWAP_INTERVAL_EXT, &swap);
            return swap;
        }
        else {
            warningf("could not get glx drawable to get swap interval");
            return -1;
        }
    }

    override @property void swapInterval(int interval)
    {
        Display *dpy = glXGetCurrentDisplay();
        GLXDrawable drawable = glXGetCurrentDrawable();

        if (drawable) {
            glXSwapIntervalEXT(dpy, drawable, interval);
        }
        else {
            warningf("could not get glx drawable to set swap interval");
        }
    }

    override void swapBuffers(size_t nativeHandle)
    {
        auto xWin = cast(xcb_window_t)nativeHandle;
        glXSwapBuffers(g_display, xWin);
    }
}


GLXFBConfig getGlxFBConfig(Display* dpy, int screenNum, in GlAttribs attribs)
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

xcb_visualtype_t* findXcbVisualInScreen(in XcbScreen screen, xcb_visualid_t visualId)
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

int[] getGlxAttribs(in GlAttribs attribs)
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
