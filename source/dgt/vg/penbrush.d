/// Aggregates what is necessary to stroke and fill.
module dgt.vg.penbrush;

import dgt.core.paint;

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
    float[] values;

    immutable this(in float offset, immutable(float)[] values)
    {
        this.offset = offset;
        this.values = values;
    }

    this(in float offset, float[] values)
    {
        this.offset = offset;
        this.values = values;
    }

    @property Dash dup() const
    {
        return Dash(offset, values.dup);
    }

    @property immutable(Dash) idup() const {
        return immutable(Dash)(offset, values.idup);
    }
}


final class Pen
{
    this()
    {}

    this(in float width, in LineCap cap, in LineJoin join,
                Dash dash, immutable(Paint) paint)
    {
        _width = width;
        _cap = cap;
        _join = join;
        _dash = dash;
        _paint = paint;
    }

    @property float width() const { return _width; }
    @property void width(in float width) { _width = width; }

    @property LineCap cap() const { return _cap; }
    @property void cap(in LineCap cap) { _cap = cap; }

    @property LineJoin join() const { return _join; }
    @property void join(in LineJoin join) { _join = join; }

    @property const(Dash) dash() const { return _dash; }
    @property void dash(in Dash dash) { _dash = dash.dup; }

    @property immutable(Paint) paint() const { return _paint; }
    @property void paint(immutable(Paint) paint) { _paint = _paint; }

    private float _width = 1f;
    private LineCap _cap;
    private LineJoin _join;
    private Dash _dash;
    private RPaint _paint;
}


enum FillRule
{
    NonZero,
    EvenOdd,
}

final class Brush
{
    this()
    {}

    this(in FillRule rule, immutable(Paint) paint)
    {
        _rule = rule;
        _paint = paint;
    }

    @property FillRule rule() const { return _rule; }
    @property void rule(in FillRule rule) { _rule = rule; }

    @property immutable(Paint) paint() const { return _paint; }
    @property void paint(immutable(Paint) paint) { _paint = paint; }

    private FillRule _rule;
    private RPaint _paint;
}
