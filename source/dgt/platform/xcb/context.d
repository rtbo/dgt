module dgt.platform.xcb.context;

import dgt.surface;

import X11.Xlib;
import xcb.xcb;
import derelict.opengl3.gl3;
import derelict.opengl3.glx;
import derelict.opengl3.glxext;

import std.typecons;
import std.format;
import std.experimental.logger;


/// Returned data should be freed with XFree.
XVisualInfo *getVisualInfoFromAttribs(  Display *dpy,
                                        int screenNum,
                                        in SurfaceAttribs attribs)
{
    auto fbc = getFBConfigFromAttribs(dpy, screenNum, attribs);
    if (!fbc) return null;
    return glXGetVisualFromFBConfig(dpy, fbc);
}


private GLXFBConfig getFBConfigFromAttribs(
        Display *dpy, int screenNum, in SurfaceAttribs attribs)
{
    auto glxAttribs = chooseConfigAttribs(attribs);

    int numConfigs;
    GLXFBConfig *fbConfigs = glXChooseFBConfig(
            dpy, screenNum, &glxAttribs[0], &numConfigs
    );

    if (!fbConfigs || !numConfigs) {
        critical("Clue-XCB: could not get fb config");
        return null;
    }
    scope(exit) XFree(fbConfigs);

    return fbConfigs[0];
}

private int[] chooseConfigAttribs(in SurfaceAttribs attribs) {

    int [] glxAttribs = [
        GLX_X_RENDERABLE    , 1,
        GLX_DRAWABLE_TYPE   , GLX_WINDOW_BIT,
        GLX_RENDER_TYPE     , GLX_RGBA_BIT,
        GLX_X_VISUAL_TYPE   , GLX_TRUE_COLOR
    ];

    if (attribs.redSize)
        glxAttribs ~= [ GLX_RED_SIZE        , attribs.redSize ];
    if (attribs.greenSize)
        glxAttribs ~= [ GLX_GREEN_SIZE      , attribs.greenSize ];
    if (attribs.blueSize)
        glxAttribs ~= [ GLX_BLUE_SIZE       , attribs.blueSize ];
    if (attribs.hasAlpha)
        glxAttribs ~= [ GLX_ALPHA_SIZE      , attribs.alphaSize ];

    if (attribs.depthSize)
        glxAttribs ~= [ GLX_DEPTH_SIZE      , attribs.depthSize ];
    if (attribs.hasStencil)
        glxAttribs ~= [ GLX_STENCIL_SIZE    , attribs.stencilSize ];

    if (attribs.doublebuffer)
        glxAttribs ~= [ GLX_DOUBLEBUFFER    , 1 ];

    if (attribs.hasSamples) {
        glxAttribs ~= [
            GLX_SAMPLE_BUFFERS  , 1,
            GLX_SAMPLES         , attribs.samples
        ];
    }

    return glxAttribs ~ 0;
}
