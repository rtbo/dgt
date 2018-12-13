/// Aggregates what is necessary to stroke and fill.
module dgt.vg.penbrush;

import dgt.core.color;
import dgt.gfx.paint;
import std.typecons : Rebindable;

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
    float offset=0f;
    immutable(float)[] values;

    enum Dash solid = Dash.init;
}

struct PenBuilder
{
    ref PenBuilder width(in float width)
    {
        _width = width;
        return this;
    }

    ref PenBuilder cap(in LineCap cap)
    {
        _cap = cap;
        return this;
    }

    ref PenBuilder join(in LineJoin join)
    {
        _join = join;
        return this;
    }

    ref PenBuilder dash(in Dash dash)
    {
        _dash = dash;
        return this;
    }

    ref PenBuilder paint(immutable(Paint) paint)
    {
        _paint = paint;
        return this;
    }

    ref PenBuilder color(Color color)
    {
        _paint = new immutable ColorPaint(color);
        return this;
    }

    immutable(Pen) done()
    {
        return new immutable Pen (_paint ? _paint : ColorPaint.black, _width, _cap, _join, _dash);
    }

    private float _width = 1f;
    private RPaint _paint;
    private LineCap _cap;
    private LineJoin _join;
    private Dash _dash;
}

alias RPen = Rebindable!(immutable(Pen));

final immutable class Pen
{
    private this()
    {
        _paint = ColorPaint.black;
        _width = 1f;
        _cap = LineCap.butt;
        _join = LineJoin.miter;
        _dash = Dash.solid;
    }

    this (immutable(Paint) paint, float width=1f)
    {
        _paint = paint;
        _width = width;
        _cap = LineCap.butt;
        _join = LineJoin.miter;
        _dash = Dash.solid;
    }

    this (Color color, in float width=1f)
    {
        _paint = new immutable ColorPaint(color);
        _width = width;
        _cap = LineCap.butt;
        _join = LineJoin.miter;
        _dash = Dash.solid;
    }

    this(immutable(Paint) paint, in float width, in LineCap cap, in LineJoin join, in Dash dash)
    {
        _paint = paint;
        _width = width;
        _cap = cap;
        _join = join;
        _dash = dash;
    }

    static PenBuilder build()
    {
        return PenBuilder.init;
    }

    float width() immutable
    {
        return _width;
    }

    immutable(Paint) paint() immutable
    {
        return _paint;
    }
    LineCap cap() immutable
    {
        return _cap;
    }

    LineJoin join() immutable
    {
        return _join;
    }

    Dash dash() immutable
    {
        return _dash;
    }

    private immutable(Paint) _paint;
    private float _width = 1f;
    private LineCap _cap;
    private LineJoin _join;
    private Dash _dash;
}


enum FillRule
{
    nonZero,
    evenOdd,
}

alias RBrush = Rebindable!(immutable(Brush));

final immutable class Brush
{
    private this()
    {
        _paint = ColorPaint.black;
        _fillRule = FillRule.nonZero;
    }

    this(immutable(Paint) paint, in FillRule fillFule=FillRule.nonZero)
    {
        _paint = paint;
        _fillRule = fillRule;
    }

    @property immutable(Paint) paint() immutable { return _paint; }
    @property FillRule fillRule() immutable { return _fillRule; }

    private immutable(Paint) _paint;
    private FillRule _fillRule;
}

/// The default pen for stroking:
///     - black color
///     - 1px width
///     - butt end cap
///     - miter joins
///     - solid line (no dash)
immutable Pen defaultPen;

/// The default brush for filling:
///     - black color
///     - non-zero fill rule
immutable Brush defaultBrush;

shared static this()
{
    defaultPen = new immutable Pen;
    defaultBrush = new immutable Brush;
}
