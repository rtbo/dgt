module dgt.vg.backend.cairo;

import dgt.vg.context;
import dgt.vg.path;
import dgt.surface;

import cairo.c.cairo;


pure @safe @nogc
{
    private cairo_fill_rule_t cairoFillRule(in FillRule fillRule)
    {
        final switch (fillRule)
        {
            case FillRule.NonZero:
                return cairo_fill_rule_t.CAIRO_FILL_RULE_WINDING;
            case FillRule.EvenOdd:
                return cairo_fill_rule_t.CAIRO_FILL_RULE_EVEN_ODD;
        }
    }

    private FillRule dgtFillRule(in cairo_fill_rule_t fillRule)
    {
        final switch (fillRule)
        {
            case cairo_fill_rule_t.CAIRO_FILL_RULE_WINDING:
                return FillRule.NonZero;
            case cairo_fill_rule_t.CAIRO_FILL_RULE_EVEN_ODD:
                return FillRule.EvenOdd;
        }
    }

    private cairo_line_cap_t cairoLineCap(in LineCap cap)
    {
        final switch (cap)
        {
            case LineCap.butt: return cairo_line_cap_t.CAIRO_LINE_CAP_BUTT;
            case LineCap.round: return cairo_line_cap_t.CAIRO_LINE_CAP_ROUND;
            case LineCap.square: return cairo_line_cap_t.CAIRO_LINE_CAP_SQUARE;
        }
    }

    private LineCap dgtLineCap(in cairo_line_cap_t cap)
    {
        final switch (cap)
        {
            case cairo_line_cap_t.CAIRO_LINE_CAP_BUTT: return LineCap.butt;
            case cairo_line_cap_t.CAIRO_LINE_CAP_ROUND: return LineCap.round;
            case cairo_line_cap_t.CAIRO_LINE_CAP_SQUARE: return LineCap.square;
        }
    }

    private cairo_line_join_t cairoLineJoin(in LineJoin val)
    {
        final switch (val)
        {
            case LineJoin.miter: return cairo_line_join_t.CAIRO_LINE_JOIN_MITER;
            case LineJoin.round: return cairo_line_join_t.CAIRO_LINE_JOIN_ROUND;
            case LineJoin.bevel: return cairo_line_join_t.CAIRO_LINE_JOIN_BEVEL;
        }
    }

    private LineJoin dgtLineJoin(in cairo_line_join_t val)
    {
        final switch (val)
        {
            case cairo_line_join_t.CAIRO_LINE_JOIN_MITER: return LineJoin.miter;
            case cairo_line_join_t.CAIRO_LINE_JOIN_ROUND: return LineJoin.round;
            case cairo_line_join_t.CAIRO_LINE_JOIN_BEVEL: return LineJoin.bevel;
        }
    }
}

/// VgContext implementation for cairo graphics library
class CairoVgContext : VgContext
{
    private Surface surface_;
    private cairo_surface_t *cairoSurface_;
    private cairo_t *cairo_;

    this(Surface surface, cairo_surface_t *cairoSurface)
    {
        surface_ = surface;
        cairoSurface_ = cairo_surface_reference(cairoSurface);
        cairo_ = cairo_create(cairoSurface_);
    }


    private @property cairo_t *cairo() const
    {
        return cast(cairo_t*)cairo_;
    }
    private @property cairo_t *cairo()
    {
        return cairo_;
    }

    override void dispose()
    {
        cairo_destroy(cairo_);
        cairo_surface_destroy(cairoSurface_);
    }

    override @property inout(Surface) surface() inout
    {
        return surface_;
    }

    override void save()
    {
        cairo_save(cairo);
    }
    override void restore()
    {
        cairo_restore(cairo);
    }

    override @property FillRule fillRule() const
    {
        return dgtFillRule(cairo_get_fill_rule(cairo));
    }
    override @property void fillRule(in FillRule fillRule)
    {
        cairo_set_fill_rule(cairo, cairoFillRule(fillRule));
    }

    override @property float lineWidth() const
    {
        return cast(float)cairo_get_line_width(cairo);
    }
    override @property void lineWidth(in float lineWidth)
    {
        cairo_set_line_width(cairo, lineWidth);
    }

    override @property LineCap lineCap() const
    {
        return dgtLineCap(cairo_get_line_cap(cairo));
    }
    override @property void lineCap(in LineCap lineCap)
    {
        cairo_set_line_cap(cairo, cairoLineCap(lineCap));
    }

    override @property LineJoin lineJoin() const
    {
        return dgtLineJoin(cairo_get_line_join(cairo));
    }
    override @property void lineJoin(in LineJoin lineJoin)
    {
        cairo_set_line_join(cairo, cairoLineJoin(lineJoin));
    }

    override @property const(Dash) dash() const
    {
        import std.algorithm : map;
        import std.array : array;
        auto values = new double[cairo_get_dash_count(cairo)];
        double offset;
        cairo_get_dash(cairo, &values[0], &offset);
        return Dash(cast(float)offset, values.map!(v => cast(float)v).array);
    }
    override @property void dash(in Dash dash)
    {
        import std.algorithm : map;
        import std.array : array;
        auto values = dash.values.map!(v => double(v)).array;
        cairo_set_dash(cairo,
            &values[0], cast(int)values.length, cast(float)dash.offset
        );
    }

    override @property const(float)[] pathTransform() const
    {
        float[9] mat;
        cairo_matrix_t cairoMat;
        cairo_get_matrix(cairo, &cairoMat);
        mat[0] = cast(float)cairoMat.xx;
        mat[1] = cast(float)cairoMat.xy;
        mat[2] = cast(float)cairoMat.x0;
        mat[3] = cast(float)cairoMat.yy;
        mat[4] = cast(float)cairoMat.yx;
        mat[5] = cast(float)cairoMat.y0;
        mat[6] = 0; mat[7] = 0; mat[8] = 1;
        return mat[].dup;
    }
    override @property void pathTransform(in float[] pathTransform)
    {
        import dgt.math.approx : approx;
        import std.exception : enforce;
        enforce(pathTransform.length == 9, "incorrect matrix size");
        enforce(approx(pathTransform[6], 0), "not affine matrix");
        enforce(approx(pathTransform[7], 0), "not affine matrix");
        enforce(approx(pathTransform[8], 1), "not affine matrix");
        auto cairoMat = cairo_matrix_t(
            pathTransform[0], pathTransform[1], pathTransform[2],
            pathTransform[3], pathTransform[4], pathTransform[5]
        );
        cairo_set_matrix(cairo, &cairoMat);
    }

    override void clipWithPath(in Path path)
    {
        bindPath(path);
        cairo_clip(cairo);
    }

    override void drawPath(in Path path, in PaintModeFlags paintMode)
    {
        bindPath(path);
        if (paintMode & PaintMode.fill)
        {
            cairo_fill_preserve(cairo);
        }
        if (paintMode & PaintMode.stroke)
        {
            cairo_stroke_preserve(cairo);
        }
    }

    private void bindPath(in Path path)
    {
        cairo_new_path(cairo);
        foreach(seg; path.segmentRange)
        {
            final switch(seg.seg)
            {
                case PathSeg.moveTo:
                    cairo_move_to(cairo, seg.data[0], seg.data[1]);
                    break;
                case PathSeg.lineTo:
                    cairo_line_to(cairo, seg.data[0], seg.data[1]);
                    break;
                case PathSeg.quadTo:
                    immutable cps = quadToCubicControlPoints(
                        seg.previousPoint, seg.data[0 .. 2], seg.data[2 .. 4]
                    );
                    cairo_curve_to( cairo,
                        cps[0], cps[1], cps[2], cps[3], seg.data[2], seg.data[3]
                    );
                    break;
                case PathSeg.cubicTo:
                    cairo_curve_to( cairo,
                        seg.data[0], seg.data[1], seg.data[2], seg.data[3],
                        seg.data[4], seg.data[5]
                    );
                    break;
                case PathSeg.shortCcwArcTo:
                case PathSeg.shortCwArcTo:
                case PathSeg.largeCcwArcTo:
                case PathSeg.largeCwArcTo:
                    // FIXME: impl with transforms and cairo_arc
                    assert(false, "implemented");
                case PathSeg.close:
                    cairo_close_path(cairo);
                    break;
            }
        }
    }
}


private
float[4] quadToCubicControlPoints( in float[2] start,
                                   in float[2] control,
                                   in float[2] end) pure nothrow @safe @nogc
{
    return [
        start[0]/3f + control[0]*2f/3f,
        start[1]/3f + control[1]*2f/3f,
        end[0]/3f + control[0]*2f/3f,
        end[1]/3f + control[1]*2f/3f,
    ];
}
