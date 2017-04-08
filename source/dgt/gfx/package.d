module dgt.gfx;

import dgt.platform;
import dgt.core.util : ValueProperty;
import dgt.geometry : ISize;
import dgt.screen;
import dgt.window;

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
    mixin ValueProperty!("minorVersion", byte, 0);

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


final class GlContext
{
    private GlAttribs _attribs;
    private GlContext _sharedCtx;
    private Screen _screen;
    private string[] _extensions;
    private bool _realized;

    private PlatformGlContext _platformCtx;

    this()
    {
        import dgt.application;
        _platformCtx = Application.platform.createGlContext();
    }

    @property GlAttribs attribs() const
    {
        return _attribs;
    }

    @property void attribs(GlAttribs attribs)
    in { assert(!_realized); }
    body
    {
        _attribs = attribs;
    }

    @property GlContext sharedCtx()
    {
        return _sharedCtx;
    }
    @property void sharedCtx(GlContext shCtx)
    in { assert(!_realized); }
    body {
        _sharedCtx = shCtx;
    }

    @property Screen screen()
    {
        return _screen;
    }
    @property void screen(Screen screen)
    in { assert(!_realized); }
    body {
        screen = screen;
    }


    bool realize (Window w)
    {
        if (_realized) {
            warning("DGT: try to realise a realized Gl context");
            return true;
        }

        Window dummy;
        if (!w) {
            w = new Window;
            w.hide();
            dummy = w;
        }

        _realized = _platformCtx.realize (
            _attribs,
            w.platformWindow,
            _sharedCtx ? _sharedCtx._platformCtx : null,
            _screen
        );

        if (dummy) {
            dummy.close();
        }

        return _realized;
    }

    bool makeCurrent(Window w)
    {
        if (!_realized) realize(w);
        return _platformCtx.makeCurrent(w.platformWindow);
    }

    void doneCurrent()
    {
        _platformCtx.doneCurrent();
    }

    void swapBuffers(Window w)
    {
        _platformCtx.swapBuffers(w.platformWindow);
    }
}


