module dgt.vg.context;

import dgt.resource;
import dgt.vg.path;
import dgt.vg.paint;
import dgt.surface;

import std.typecons : BitFlags, Flag, No;

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

enum PaintMode
{
    fill = 1,
    stroke = 2,
}

alias PaintModeFlags = BitFlags!PaintMode;

interface VgContext : RefCounted
{
    @property inout(Surface) surface() inout;

    void save();
    void restore();

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

    /// Intersects the current clip path with path
    void clip(in Path path);
    /// Resets the clip region to the whole surface
    void resetClip();

    @property inout(Paint) fillPaint() inout;
    @property void fillPaint(Paint paint);

    @property inout(Paint) strokePaint() inout;
    @property void strokePaint(Paint paint);

    /// Clear the whole clipping area with the provided color.
    /// This is equivalent has filling the clip path with a color Paint,
    /// but can possibly be faster.
    void clear(in float[4] color);
    void drawPath(in Path path, in PaintMode paintMode);
    void flush();
}
