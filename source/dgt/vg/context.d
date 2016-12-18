module dgt.vg.context;

import dgt.vg.path;
import dgt.surface;

enum FillRule
{
    NonZero,
    EvenOdd,
}

enum LineCap
{
    butt,
    round,
    square,
}

enum LineJoin
{
    miter,
    round,
    bevel,
}

struct Dash
{
    float offset;
    float[] values;

    @property Dash dup() const
    {
        return Dash(offset, values.dup);
    }
}

interface VgContext
{
    /// Release all resources in this context.
    /// Context must not be used after this call.
    void dispose();

    @property inout(Surface) surface() inout;

    void save();
    void restore();

    @property inout(Path) clipPath() inout;
    @property void clipPath(Path path);

    @property FillRule fillRule() const;
    @property void fillRule(in FillRule fillRule);

    @property float lineWidth() const;
    @property void lineWidth(in float lineWidth);

    @property LineCap lineCap() const;
    @property void lineCap(in LineCap lineCap);

    @property LineJoin lineJoin() const;
    @property void lineJoin(in LineJoin lineJoin);

    @property const(Dash) dash() const;
    @property void dash(in Dash dash);

    @property const(float)[] pathTransform() const;
    @property void pathTransform(in float[] pathTransform);


}
