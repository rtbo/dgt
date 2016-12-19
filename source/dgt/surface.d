module dgt.surface;

import dgt.util : ValueProperty;
import dgt.geometry : ISize;

enum OpenGLProfile
{
    Compatibility,
    Core,
}

struct SurfaceAttribs
{
    mixin ValueProperty!("majorVersion", int, 3);
    mixin ValueProperty!("minorVersion", int, 0);
    mixin ValueProperty!("profile", OpenGLProfile);

    mixin ValueProperty!("redSize", int, 8);
    mixin ValueProperty!("greenSize", int, 8);
    mixin ValueProperty!("blueSize", int, 8);
    mixin ValueProperty!("alphaSize", int, 8);

    mixin ValueProperty!("depthSize", int, 24);
    mixin ValueProperty!("stencilSize", int, 8);

    mixin ValueProperty!("samples", int);

    mixin ValueProperty!("doublebuffer", bool, true);

    mixin ValueProperty!("debugContext", bool);

    @property bool hasAlpha() const
    {
        return alphaSize_ > 0;
    }

    @property bool hasDepth() const
    {
        return depthSize_ > 0;
    }

    @property bool hasStencil() const
    {
        return stencilSize_ > 0;
    }

    @property bool hasSamples() const
    {
        return samples_ > 0;
    }

    @property int decimalVersion() const
    {
        return majorVersion_ * 10 + minorVersion_;
    }
}

interface Surface
{
    @property SurfaceAttribs attribs() const;
    @property ISize size() const;
}
