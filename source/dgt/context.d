module dgt.context;

import dgt.core.geometry : ISize;
import dgt.core.util : ValueProperty;
import dgt.screen;
import dgt.window;

import gfx.foundation.rc;

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

interface GlContext : Disposable
{
    @property GlAttribs attribs() const;

    bool makeCurrent(size_t nativeHandle);

    void doneCurrent();

    @property bool current() const;

    @property int swapInterval()
    in { assert(current); }

    @property void swapInterval(int interval)
    in { assert(current); }

    void swapBuffers(size_t nativeHandle)
    in { assert(current); }
}

GlContext createGlContext(GlAttribs attribs,
                                  GlContext sharedCtx=null,
                                  Screen screen=null)
{
    return createGlContext(
        attribs, null, sharedCtx, screen
    );
}

GlContext createGlContext(Window window=null,
                                  GlContext sharedCtx=null,
                                  Screen screen=null)
{
    return createGlContext(
        window ? window.attribs : GlAttribs.init,
        window, sharedCtx, screen
    );
}


private:

GlContext createGlContext(GlAttribs attribs, Window window,
                                  GlContext sharedCtx, Screen screen)
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
