module dgt.context;

import dgt.platform;
import dgt.util : ValueProperty;
import dgt.geometry : ISize;
import dgt.screen;
import dgt.window;

import derelict.opengl3.gl3;

import std.exception;
import std.experimental.logger;


enum GlProfile
{
    core,
    compatibility
}

struct GlAttribs
{
    enum profile = GlProfile.core;
    enum doublebuffer = true;

    mixin ValueProperty!("majorVersion", byte, 3);
    mixin ValueProperty!("minorVersion", byte, 3);

    mixin ValueProperty!("redSize", byte, 8);
    mixin ValueProperty!("greenSize", byte, 8);
    mixin ValueProperty!("blueSize", byte, 8);
    mixin ValueProperty!("alphaSize", byte, 8);

    mixin ValueProperty!("depthSize", byte, 24);
    mixin ValueProperty!("stencilSize", byte, 8);

    mixin ValueProperty!("samples", byte);

    mixin ValueProperty!("debugContext", bool);

    @property byte colorSize() const
    {
        return cast(byte)(redSize + greenSize + blueSize + alphaSize);
    }

    @property byte redShift() const
    {
        return cast(byte)(greenShift + greenSize);
    }

    @property byte greenShift() const
    {
        return cast(byte)(blueShift + blueSize);
    }

    @property byte blueShift() const
    {
        return cast(byte)(alphaShift + alphaSize);
    }

    enum byte alphaShift = 0;

    @property bool hasAlpha() const
    {
        return alphaSize > 0;
    }

    @property bool hasDepth() const
    {
        return depthSize > 0;
    }

    @property bool hasStencil() const
    {
        return stencilSize > 0;
    }

    @property bool hasSamples() const
    {
        return samples > 0;
    }

    @property int decimalVersion() const
    {
        return majorVersion * 10 + minorVersion;
    }
}

synchronized interface GlContext
{
    bool makeCurrent(size_t nativeHandle);
    void doneCurrent();
    void swapBuffers(size_t nativeHandle);
}

shared(GlContext) createGlContext(GlAttribs attribs,
                                  shared(GlContext) sharedCtx=null,
                                  Screen screen=null)
{
    return createGlContext(
        attribs, null, sharedCtx, screen
    );
}

shared(GlContext) createGlContext(Window window=null,
                                  shared(GlContext) sharedCtx=null,
                                  Screen screen=null)
{
    return createGlContext(
        window ? window.attribs : GlAttribs.init,
        window, sharedCtx, screen
    );
}


private:

shared(GlContext) createGlContext(GlAttribs attribs, Window window,
                                  shared(GlContext) sharedCtx, Screen screen)
{
    Window dummy;
    if (!window) {
        window = new Window("Dummy!", WindowFlags.dummy);
        window.hide();
        dummy = window;
    }
    scope(exit) {
        if (dummy) dummy.close();
    }

    import dgt.application : Application;
    return enforce(Application.platform.createGlContext (
        attribs, window.platformWindow, sharedCtx, screen
    ));
}
