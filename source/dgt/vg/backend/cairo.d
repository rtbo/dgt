module dgt.vg.backend.cairo;

import dgt.core.resource;
import dgt.vg;
import dgt.surface;
import dgt.image;
import dgt.bindings.cairo;

import std.exception : enforce;
import std.experimental.logger;

pure @safe @nogc
{
    private cairo_fill_rule_t cairoFillRule(in FillRule fillRule)
    {
        final switch (fillRule)
        {
        case FillRule.NonZero:
            return CAIRO_FILL_RULE_WINDING;
        case FillRule.EvenOdd:
            return CAIRO_FILL_RULE_EVEN_ODD;
        }
    }

    private FillRule dgtFillRule(in cairo_fill_rule_t fillRule)
    {
        final switch (fillRule)
        {
        case CAIRO_FILL_RULE_WINDING:
            return FillRule.NonZero;
        case CAIRO_FILL_RULE_EVEN_ODD:
            return FillRule.EvenOdd;
        }
    }

    private cairo_line_cap_t cairoLineCap(in LineCap cap)
    {
        final switch (cap)
        {
        case LineCap.butt:
            return CAIRO_LINE_CAP_BUTT;
        case LineCap.round:
            return CAIRO_LINE_CAP_ROUND;
        case LineCap.square:
            return CAIRO_LINE_CAP_SQUARE;
        }
    }

    private LineCap dgtLineCap(in cairo_line_cap_t cap)
    {
        final switch (cap)
        {
        case CAIRO_LINE_CAP_BUTT:
            return LineCap.butt;
        case CAIRO_LINE_CAP_ROUND:
            return LineCap.round;
        case CAIRO_LINE_CAP_SQUARE:
            return LineCap.square;
        }
    }

    private cairo_line_join_t cairoLineJoin(in LineJoin val)
    {
        final switch (val)
        {
        case LineJoin.miter:
            return CAIRO_LINE_JOIN_MITER;
        case LineJoin.round:
            return CAIRO_LINE_JOIN_ROUND;
        case LineJoin.bevel:
            return CAIRO_LINE_JOIN_BEVEL;
        }
    }

    private LineJoin dgtLineJoin(in cairo_line_join_t val)
    {
        final switch (val)
        {
        case CAIRO_LINE_JOIN_MITER:
            return LineJoin.miter;
        case CAIRO_LINE_JOIN_ROUND:
            return LineJoin.round;
        case CAIRO_LINE_JOIN_BEVEL:
            return LineJoin.bevel;
        }
    }
}

/// Context state tracked explicitely, that is not handled by cairo,
/// or just easier to track that way.
private struct State
{
    Rc!Paint fill;
    Rc!Paint stroke;
    Transform transform;
}

/// VgContext implementation for cairo graphics library
class CairoVgContext : VgContext
{
    import dgt.core.typecons : GrowableStack;

    mixin(rcCode);

    private Surface _surface;
    private cairo_surface_t* _cairoSurface;
    private cairo_t* _cairo;
    private Rc!CairoPaint _defaultSrc;
    private State _currentState;
    private GrowableStack!State _stateStack;

    this(Surface surface, cairo_surface_t* cairoSurface)
    {
        _surface = surface;
        _cairoSurface = cairo_surface_reference(cairoSurface);
        _cairo = cairo_create(_cairoSurface);

        auto defaultSrc = cairo_get_source(_cairo);
        if (defaultSrc)
        {
            _defaultSrc = makeRc!CairoPaint(defaultSrc);
        }
        else
        {
            _defaultSrc = makeRc!CairoPaint();
            _defaultSrc.color = [ 0, 0, 0, 1 ];
        }

        _currentState.fill = _defaultSrc;
        _currentState.stroke = _defaultSrc;
        cairo_matrix_t cm;
        cairo_get_matrix(_cairo, &cm);
        _currentState.transform = Transform (
            cm.xx, cm.xy, cm.x0,
            cm.yx, cm.yy, cm.y0
        );
    }

    private @property cairo_t* cairo() const
    {
        return cast(cairo_t*) _cairo;
    }

    private @property cairo_t* cairo()
    {
        return _cairo;
    }

    override void dispose()
    {
        if (!_stateStack.empty)
        {
            warning("CairoContext disposed with state stack not empty");
            while (!_stateStack.empty)
            {
                _stateStack.pop();
            }
        }
        _defaultSrc.unload();
        _currentState = State.init; // release the state
        cairo_destroy(_cairo);
        cairo_surface_destroy(_cairoSurface);
    }

    override @property inout(Surface) surface() inout
    {
        return _surface;
    }

    override void save()
    {
        _stateStack.push(_currentState);
        cairo_save(cairo);
    }

    override void restore()
    {
        cairo_restore(cairo);
        _currentState = _stateStack.pop();
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
        return cast(float) cairo_get_line_width(cairo);
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
        return Dash(cast(float) offset, values.map!(v => cast(float) v).array);
    }

    override @property void dash(in Dash dash)
    {
        import std.algorithm : map;
        import std.array : array;

        auto values = dash.values.map!(v => double(v)).array;
        cairo_set_dash(cairo, &values[0], cast(int) values.length, cast(float) dash.offset);
    }

    override @property Transform transform() const
    {
        return _currentState.transform;
    }

    override @property void transform(in Transform tr)
    {
        setCairoTransform(tr);
        _currentState.transform = tr;
    }

    override @property const(float)[] transformData() const
    {
        return _currentState.transform.data;
    }

    override @property void transformData(in float[] data)
    {
        import dgt.math.approx : approxUlp;
        import std.exception : enforce;

        if (data.length == 9)
        {
            debug {
                import dgt.math.approx : approxUlp, approxUlpAndAbs;
                if ( ! (approxUlpAndAbs(data[6], 0) &&
                        approxUlpAndAbs(data[7], 0) &&
                        approxUlp(data[8], 1)))
                {
                    import dgt.math.mat : FMat3;
                    warningf("Supplied matrix is not affine: %s", FMat3(data));
                }
            }
        }
        else
        {
            enforce(data.length == 6, "Unappropriate matrix size for 2D transforms");
        }

        immutable tr = Transform( data[0 .. 6] );
        setCairoTransform(tr);
        _currentState.transform = tr;
    }

    override @property inout(Paint) fillPaint() inout
    {
        return _currentState.fill;
    }

    override @property void fillPaint(Paint paint)
    {
        _currentState.fill = paint;
    }

    override @property inout(Paint) strokePaint() inout
    {
        return _currentState.stroke;
    }

    override @property void strokePaint(Paint paint)
    {
        _currentState.stroke = paint;
    }

    override void clip(in Path path)
    {
        assert(path !is null);
        bindPath(path);
        cairo_clip(cairo);
    }

    override void resetClip()
    {
        cairo_reset_clip(cairo);
    }

    override void mask(Image img)
    {
        auto imgSurf = cairo_image_surface_create_for_data(img.data.ptr,
            CAIRO_FORMAT_A8, img.width, img.height, cast(int)img.stride
        );
        scope(exit)
            cairo_surface_destroy(imgSurf);

        auto imgPatt = cairo_pattern_create_for_surface(imgSurf);
        scope(exit)
            cairo_pattern_destroy(imgPatt);

        setSource(cast(CairoPaint)_currentState.fill.obj);
        cairo_mask(cairo, imgPatt);
    }

    override void clear(in float[4] color)
    {
        cairo_set_source_rgba(cairo, color[0], color[1], color[2], color[3]);
        cairo_paint(cairo);
    }

    override void drawPath(in Path path, in PaintMode paintMode)
    {
        bindPath(path);
        immutable fill = paintMode & PaintMode.fill;
        immutable stroke = paintMode & PaintMode.stroke;
        // FIXME: pattern transform at cairo_set_source time
        if (fill)
        {
            setSource(cast(CairoPaint) _currentState.fill.obj);
            if (stroke)
                cairo_fill_preserve(cairo);
            else
                cairo_fill(cairo);
        }
        if (stroke)
        {
            setSource(cast(CairoPaint) _currentState.stroke.obj);
            cairo_stroke(cairo);
        }
    }

    override void flush()
    {
        cairo_surface_flush(_cairoSurface);
    }

    private void setCairoTransform(in Transform tr)
    {
        // cairo matrix is column major
        auto cm = cairo_matrix_t (
            tr[0, 0], tr[1, 0],
            tr[0, 1], tr[1, 1],
            tr[0, 2], tr[1, 2],
        );
        cairo_set_matrix(cairo, &cm);
    }

    private void bindPath(in Path path)
    {
        cairo_new_path(cairo);
        foreach (seg; path.segmentRange)
        {
            final switch (seg.seg)
            {
            case PathSeg.moveTo:
                cairo_move_to(cairo, seg.data[0], seg.data[1]);
                break;
            case PathSeg.lineTo:
                cairo_line_to(cairo, seg.data[0], seg.data[1]);
                break;
            case PathSeg.quadTo:
                immutable cps = quadToCubicControlPoints(seg.previousPoint,
                        seg.data[0 .. 2], seg.data[2 .. 4]);
                cairo_curve_to(cairo, cps[0], cps[1], cps[2], cps[3], seg.data[2], seg.data[3]);
                break;
            case PathSeg.cubicTo:
                cairo_curve_to(cairo, seg.data[0],
                        seg.data[1], seg.data[2], seg.data[3], seg.data[4], seg.data[5]);
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

    private void setSource(CairoPaint paint)
    {
        if (paint)
        {
            cairo_set_source(cairo, paint.pattern);
        }
        else
        {
            cairo_set_source(cairo, _defaultSrc.pattern);
        }
    }
}

private float[4] quadToCubicControlPoints(in float[2] start,
                                          in float[2] control,
                                          in float[2] end) pure nothrow @safe @nogc
{
    return [
        start[0] / 3f + control[0] * 2f / 3f,
        start[1] / 3f + control[1] * 2f / 3f,
        end[0] / 3f + control[0] * 2f / 3f,
        end[1] / 3f + control[1] * 2f / 3f
    ];
}

/// Paint implementation of Cairo
final class CairoPaint : Paint
{
    mixin(rcCode);

    private cairo_pattern_t* _pattern;

    /// Build an virgin paint.
    this() {}

    /// Build a paint from an existing pattern.
    this(cairo_pattern_t* pattern)
    {
        _pattern = pattern;
        cairo_pattern_reference(_pattern);
    }

    override void dispose()
    {
        if (_pattern)
        {
            cairo_pattern_destroy(_pattern);
            _pattern = null;
        }
    }

    override @property PaintType type() const
    {
        immutable cairoType = cairo_pattern_get_type(enforce(pattern));
        final switch (cairoType)
        {
        case CAIRO_PATTERN_TYPE_SOLID:
            return PaintType.color;
        case CAIRO_PATTERN_TYPE_LINEAR:
            return PaintType.linearGradient;
        case CAIRO_PATTERN_TYPE_RADIAL:
            return PaintType.radialGradient;
        case CAIRO_PATTERN_TYPE_SURFACE:
            assert(false, "unimplemented");
        case CAIRO_PATTERN_TYPE_MESH:
            assert(false, "unsupported");
        case CAIRO_PATTERN_TYPE_RASTER_SOURCE:
            assert(false, "unsupported");
        }
    }

    override @property float[4] color() const
    {
        enforce(type == PaintType.color);
        double r;
        double g;
        double b;
        double a;
        cairo_pattern_get_rgba(pattern, &r, &g, &b, &a);
        return [cast(float) r, cast(float) g, cast(float) b, cast(float) a];
    }

    override @property void color(in float[4] color)
    {
        enforce(!_pattern);
        _pattern = cairo_pattern_create_rgba(color[0], color[1], color[2], color[3]);
    }

    override @property LinearGradient linearGradient() const
    {
        enforce(type == PaintType.linearGradient);
        LinearGradient gradient;
        double x0 = void, y0 = void, x1 = void, y1 = void;
        cairo_pattern_get_linear_points(pattern, &x0, &y0, &x1, &y1);
        gradient.p0 = [cast(float) x0, cast(float) y0];
        gradient.p1 = [cast(float) x1, cast(float) y1];
        gradient.stops = getStops();
        return gradient;
    }

    override @property void linearGradient(in LinearGradient gradient)
    {
        enforce(!_pattern);
        _pattern = cairo_pattern_create_linear(gradient.p0[0], gradient.p0[1],
                gradient.p1[0], gradient.p1[1]);
        addStops(gradient.stops);
    }

    // OpenVG radial gradients bind in the following way
    // OpenVG       Cairo
    // focal        start circle (start circle radius = 0)
    // center       end circle
    // radius       end circle radius
    override @property RadialGradient radialGradient() const
    {
        import dgt.math.approx : approxUlp;

        enforce(type == PaintType.radialGradient);
        RadialGradient gradient;
        double x0 = void, y0 = void, x1 = void, y1 = void;
        double r0 = void, r1 = void;
        cairo_pattern_get_radial_circles(pattern, &x0, &y0, &r0, &x1, &y1, &r1);
        gradient.f = [cast(float) x0, cast(float) y0];
        assert(approxUlp(r0, 0f));
        gradient.c = [cast(float) x1, cast(float) y1];
        gradient.r = cast(float) r1;
        gradient.stops = getStops();
        return gradient;
    }

    override @property void radialGradient(in RadialGradient gradient)
    {
        assert(!_pattern);
        _pattern = cairo_pattern_create_radial(gradient.f[0], gradient.f[1],
                0.0, gradient.c[0], gradient.c[1], gradient.r);
        addStops(gradient.stops);
    }

    override @property SpreadMode spreadMode() const
    {
        immutable extend = cairo_pattern_get_extend(pattern);
        final switch (extend)
        {
        case cairo_extend_t.CAIRO_EXTEND_NONE:
            return SpreadMode.none;
        case cairo_extend_t.CAIRO_EXTEND_PAD:
            return SpreadMode.pad;
        case cairo_extend_t.CAIRO_EXTEND_REPEAT:
            return SpreadMode.reflect;
        case cairo_extend_t.CAIRO_EXTEND_REFLECT:
            return SpreadMode.reflect;
        }
    }

    override @property void spreadMode(in SpreadMode spreadMode)
    {
        final switch (spreadMode)
        {
        case SpreadMode.none:
            cairo_pattern_set_extend(pattern, cairo_extend_t.CAIRO_EXTEND_NONE);
            break;
        case SpreadMode.pad:
            cairo_pattern_set_extend(pattern, cairo_extend_t.CAIRO_EXTEND_PAD);
            break;
        case SpreadMode.repeat:
            cairo_pattern_set_extend(pattern,
                    cairo_extend_t.CAIRO_EXTEND_REPEAT);
            break;
        case SpreadMode.reflect:
            cairo_pattern_set_extend(pattern,
                    cairo_extend_t.CAIRO_EXTEND_REFLECT);
            break;
        }
    }

    private @property cairo_pattern_t* pattern() const
    {
        return cast(cairo_pattern_t*) _pattern;
    }

    private @property cairo_pattern_t* pattern()
    {
        return _pattern;
    }

    private GradientStop[] getStops() const
    {
        int stopCount = void;
        cairo_pattern_get_color_stop_count(pattern, &stopCount);
        auto stops = new GradientStop[stopCount];
        foreach (i; 0 .. stopCount)
        {
            double offset = void, r = void, g = void, b = void, a = void;
            cairo_pattern_get_color_stop_rgba(pattern, i, &offset, &r, &g, &b, &a);
            stops[i] = GradientStop(cast(float) offset, [cast(float) r,
                    cast(float) g, cast(float) b, cast(float) a]);
        }
        return stops;
    }

    private void addStops(in GradientStop[] stops)
    {
        foreach (stop; stops)
        {
            cairo_pattern_add_color_stop_rgba(pattern, stop.offset,
                    stop.color[0], stop.color[1], stop.color[2], stop.color[3]);
        }
    }
}
