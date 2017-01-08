module dgt.platform.xcb.context;

version(linux):

import dgt.platform.xcb;
import dgt.platform.xcb.screen;
import dgt.surface;

import X11.Xlib;
import xcb.xcb;
import derelict.opengl3.gl3;
import derelict.opengl3.glx;
import derelict.opengl3.glxext;

import std.typecons;
import std.format;
import std.experimental.logger;

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
XVisualInfo* getXlibVisualInfo(Display* dpy, int screenNum, in SurfaceAttribs attribs)
{
    auto fbc = getGlxFBConfig(dpy, screenNum, attribs);
    if (!fbc)
        return null;
    return glXGetVisualFromFBConfig(dpy, fbc);
}

private GLXFBConfig getGlxFBConfig(Display* dpy, int screenNum, in SurfaceAttribs attribs)
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

private int[] getGlxAttribs(in SurfaceAttribs attribs)
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
