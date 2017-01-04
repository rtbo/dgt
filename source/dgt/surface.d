module dgt.surface;

import dgt.core.util : ValueProperty;
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

interface Surface
{
    @property SurfaceAttribs attribs() const;
    @property ISize size() const;
}
