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


final shared class GlContext
{
    private PlatformGlContext _platformCtx;
    private bool _reloaded;

    this(Window window=null, GlContext sharedCtx=null, Screen screen=null)
    {
        GlAttribs attribs = window ? window.attribs : GlAttribs.init;
        realize(attribs, window, sharedCtx, screen);
    }

    this (GlAttribs attribs, GlContext sharedCtx=null, Screen screen=null)
    {
        realize(attribs, null, sharedCtx, screen);
    }

    private void realize(GlAttribs attribs, Window window,
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
        _platformCtx = Application.platform.createGlContext();
        enforce(_platformCtx.realize (
            attribs,
            window.platformWindow,
            sharedCtx ? sharedCtx._platformCtx : null,
            screen
        ));
    }

    bool makeCurrent(size_t nativeHandle)
    {
        auto res = _platformCtx.makeCurrent(nativeHandle);
        if (res && !_reloaded) {
            DerelictGL3.reload();
            _reloaded = true;
        }
        return res;
    }

    void doneCurrent()
    {
        _platformCtx.doneCurrent();
    }

    void swapBuffers(size_t nativeHandle)
    {
        _platformCtx.swapBuffers(nativeHandle);
    }
}


