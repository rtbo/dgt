module dgt.vg.context;

import dgt.core.resource;
import dgt.vg;
import dgt.image;
import dgt.math.mat;

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

/// The transform type of the VgContext is 2x3 row major float matrix.
alias Transform = FMat2x3;


/// Call dg in a state sandbox.
void sandbox(alias dg)(VgContext ctx)
{
    ctx.save();
    scope(exit) ctx.restore();
    dg();
}

/// A vector graphics context.
interface VgContext : RefCounted
{
    /// Get the backend associated with this context.
    @property inout(VgBackend) backend() inout;

    /// Get the surface this context is drawing on.
    @property inout(VgSurface) surface() inout;

    /// Save and restore the context state.
    /// The state include the following properties:
    ///   - fillRule
    ///   - lineWidth
    ///   - lineCap
    ///   - lineJoin
    ///   - dash
    ///   - transform
    ///   - fillPaint and strokePaint
    ///   - clip
    void save();
    /// ditto
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

    /// Get and set the transform of the context.
    @property Transform transform() const;
    /// ditto
    @property void transform(in Transform transform);

    /// Get and set the transform directly with row major data.
    /// Allow the use of an alternative matrix library.
    /// Supplied data can be 2x3 floats or 3x3. The drawing transformation
    /// should be affine, therefore the backend has the possibility to ignore
    /// the last row.
    @property const(float)[] transformData() const;
    /// ditto
    @property void transformData(in float[] transform);

    /// Intersects the current clip path with path
    void clip(in Path path);
    /// Resets the clip region to the whole surface
    void resetClip();

    @property inout(Paint) fillPaint() inout;
    @property void fillPaint(Paint paint);

    @property inout(Paint) strokePaint() inout;
    @property void strokePaint(Paint paint);

    /// Mask the surface with the alpha plane of the texture and paint it
    /// with the current fill paint. tex.format must be either ImageFormat.a1 or
    /// ImageFormat.a8.
    void mask(VgTexture tex);

    /// Draw the texture to the surface.
    void drawTexture(VgTexture tex);

    /// Clear the whole clipping area with the provided color.
    /// This is equivalent has filling the clip path with a color Paint,
    /// but can possibly be faster.
    void clear(in float[4] color);
    void drawPath(in Path path, in PaintMode paintMode);
}
