module dgt.vg.backend.cairo;

import dgt.vg;
import gfx.foundation.rc;
import dgt.util : hash;
import dgt.image;
import dgt.geometry;
import dgt.bindings.cairo;

import dgt.math.vec;

import std.typecons : Flag, Yes, No;
import std.exception : enforce;
import std.experimental.logger;

private __gshared CairoBackend _cairoBackend;

shared static this()
{
    _cairoBackend = new CairoBackend;
}

shared static ~this()
{
    _cairoBackend.dispose();
}

/// Access to the cairo backend singleton.
static @property CairoBackend cairoBackend()
{
    return _cairoBackend;
}

/// Unique identifier of the cairo backend.
public enum cairoUid = hash!"dgt.vg.backend.cairo";
static assert(cairoUid != 0);


private class CairoBackend : VgBackend
{
    override void dispose()
    {}

    override @property size_t uid() const
    {
        return cairoUid;
    }

    override @property string name() const
    {
        return "cairo";
    }

    override VgContext createContext(Image image)
    {
        return new CairoContext(this, image);
    }
}


/// Context state tracked explicitely, that is not handled by cairo,
/// or just easier to track that way.
private struct State
{
    Paint fill;
    Paint stroke;
    Transform transform;
}

/// VgContext implementation for cairo graphics library
class CairoContext : VgContext
{
    import dgt.container : GrowableStack;

    private CairoBackend _backend;
    private Image _image;
    private cairo_surface_t* _surf;
    private cairo_t* _cairo;
    private Paint _defaultPaint;
    private State _currentState;
    private GrowableStack!State _stateStack;

    this(CairoBackend backend, Image image)
    {
        _backend = backend;
        _image = image;
        _surf = makeCairoSurface(image);
        _cairo = cairo_create(_surf);

        auto defaultSrc = cairo_get_source(_cairo);
        Paint defaultPaint;
        if (defaultSrc)
        {
            defaultPaint = paintFromCairoPattern(defaultSrc);
        }
        else
        {
            defaultPaint = new ColorPaint( fvec(0, 0, 0, 1) );
        }

        _currentState.fill = defaultPaint;
        _currentState.stroke = defaultPaint;
        cairo_matrix_t cm;
        cairo_get_matrix(_cairo, &cm);
        _currentState.transform = Transform (
            cm.xx, cm.xy, cm.x0,
            cm.yx, cm.yy, cm.y0
        );
    }

    private @property cairo_t* cairo() const
    {
        // That is quite ugly but unfortunately necessary to preserve constness
        // to the application. The backend has responsibility to not abuse it
        // and using the const cast only for getters.
        return cast(cairo_t*) _cairo;
    }

    private @property cairo_t* cairo()
    {
        return _cairo;
    }

    override void dispose()
    {
        cairo_surface_flush(_surf);
        if (!_stateStack.empty)
        {
            warning("CairoContext disposed with state stack not empty");
            while (!_stateStack.empty)
            {
                _stateStack.pop();
            }
        }
        _currentState = State.init; // release the state
        cairo_destroy(_cairo);
        cairo_surface_destroy(_surf);
    }

    override @property inout(VgBackend) backend() inout
    {
        return _backend;
    }

    override @property inout(Image) image() inout
    {
        return _image;
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
        auto surf = makeCairoSurface(img.makeVgCompatible());
        auto patt = cairo_pattern_create_for_surface(surf);

        setPaint(_currentState.fill);
        cairo_mask(cairo, patt);

        cairo_pattern_destroy(patt);
        cairo_surface_destroy(surf);
    }

    override void drawImage(Image img)
    {
        auto surf = makeCairoSurface(img.makeVgCompatible());

        cairo_set_source_surface(cairo, surf, 0, 0);
        cairo_paint(cairo);

        cairo_surface_destroy(surf);
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
            setPaint(_currentState.fill);
            if (stroke)
                cairo_fill_preserve(cairo);
            else
                cairo_fill(cairo);
        }
        if (stroke)
        {
            setPaint(_currentState.stroke);
            cairo_stroke(cairo);
        }
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

    private void setPaint(Paint paint)
    {
        assert(paint !is null);
        auto patt = cairoPatternFromPaint(paint);
        cairo_set_source(cairo, patt);
    }
}

cairo_surface_t* makeCairoSurface(Image image)
in {
    assert(image && image.vgCompatible);
}
body
{
    return cairo_image_surface_create_for_data(
        image.data.ptr, cairoFormat(image.format),
        image.width, image.height, cast(int)image.stride
    );
}

pure @safe
{
    /// map ImageFormat to cairo_format_t
    public cairo_format_t cairoFormat(in ImageFormat ifmt)
    {
        switch (ifmt)
        {
        case ImageFormat.a1:
            return CAIRO_FORMAT_A1;
        case ImageFormat.a8:
            return CAIRO_FORMAT_A8;
        case ImageFormat.rgb:
            return CAIRO_FORMAT_RGB24;
        case ImageFormat.argbPremult:
            return CAIRO_FORMAT_ARGB32;
        default:
            import std.format : format;
            throw new Exception(
                format("ImageFormat.%s is not supported by cairo", ifmt)
            );
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

private void patternAddStops(cairo_pattern_t* patt, in GradientStop[] stops)
{
    foreach (stop; stops)
    {
        cairo_pattern_add_color_stop_rgba(patt, stop.offset,
                stop.color[0], stop.color[1], stop.color[2], stop.color[3]);
    }
}

private GradientStop[] patternGetStops(cairo_pattern_t* patt)
{
    import std.array : uninitializedArray;
    int stopCount = void;
    cairo_pattern_get_color_stop_count(patt, &stopCount);
    auto stops = uninitializedArray!(GradientStop[])(stopCount);
    foreach (i; 0 .. stopCount)
    {
        double offset=void, r=void, g=void, b=void, a=void;
        cairo_pattern_get_color_stop_rgba(patt, i, &offset, &r, &g, &b, &a);
        stops[i] = GradientStop(cast(float) offset, fvec(r, g, b, a));
    }
    return stops;
}

private SpreadMode patternSpreadMode(in cairo_extend_t extend)
{
    final switch (extend)
    {
    case CAIRO_EXTEND_NONE:
        return SpreadMode.none;
    case CAIRO_EXTEND_PAD:
        return SpreadMode.pad;
    case CAIRO_EXTEND_REPEAT:
        return SpreadMode.reflect;
    case CAIRO_EXTEND_REFLECT:
        return SpreadMode.reflect;
    }
}

private cairo_extend_t paintPatternExtend(in SpreadMode mode)
{
    final switch (mode)
    {
    case SpreadMode.none:
        return CAIRO_EXTEND_NONE;
    case SpreadMode.pad:
        return CAIRO_EXTEND_PAD;
    case SpreadMode.repeat:
        return CAIRO_EXTEND_REPEAT;
    case SpreadMode.reflect:
        return CAIRO_EXTEND_REFLECT;
    }
}

private Paint paintFromCairoPattern(cairo_pattern_t* patt)
{
    Paint paint;
    final switch(cairo_pattern_get_type(patt))
    {
    case CAIRO_PATTERN_TYPE_SOLID:
        double r=void, g=void, b=void, a=void;
        cairo_pattern_get_rgba(patt, &r, &g, &b, &a);
        paint = new ColorPaint(fvec(r, g, b, a));
        break;
    case CAIRO_PATTERN_TYPE_LINEAR:
        auto stops = patternGetStops(patt);
        double xs=void, ys=void, xe=void, ye=void;
        cairo_pattern_get_linear_points(patt, &xs, &ys, &xe, &ye);
        auto lgp = new LinearGradientPaint(fvec(xs, ys), fvec(xe, ye), stops);
        lgp.spreadMode = patternSpreadMode(
            cairo_pattern_get_extend(patt)
        );
        paint = lgp;
        break;
    case CAIRO_PATTERN_TYPE_RADIAL:
        import dgt.math.approx : approxUlpAndAbs;
        auto stops = patternGetStops(patt);
        double x0 = void, y0 = void, x1 = void, y1 = void;
        double r0 = void, r1 = void;
        cairo_pattern_get_radial_circles(patt, &x0, &y0, &r0, &x1, &y1, &r1);
        assert(approxUlpAndAbs(r0, 0.0));
        auto rgp = new RadialGradientPaint(fvec(x0, y0), fvec(x1, y1), cast(float)r1, stops);
        rgp.spreadMode = patternSpreadMode(
            cairo_pattern_get_extend(patt)
        );
        paint = rgp;
        break;
    case CAIRO_PATTERN_TYPE_SURFACE:
        assert(false, "unimplemented");
    case CAIRO_PATTERN_TYPE_MESH:
        assert(false, "unsupported");
    case CAIRO_PATTERN_TYPE_RASTER_SOURCE:
        assert(false, "unsupported");
    }
    return paint;
}

private cairo_pattern_t* cairoPatternFromPaint(Paint paint)
{
    import gfx.foundation.util : unsafeCast;

    cairo_pattern_t* patt;

    switch (paint.type)
    {
    case PaintType.color:
        auto cp = unsafeCast!ColorPaint(paint);
        immutable c = cp.color;
        patt = cairo_pattern_create_rgba(c[0], c[1], c[2], c[3]);
        break;
    case PaintType.linearGradient:
        auto lgp = unsafeCast!LinearGradientPaint(paint);
        immutable s = lgp.start;
        immutable e = lgp.end;
        patt = cairo_pattern_create_linear(s[0], s[1], e[0], e[1]);
        patternAddStops(patt, lgp.stops);
        break;
    case PaintType.radialGradient:
        auto rgp = unsafeCast!RadialGradientPaint(paint);
        immutable f = rgp.focal;
        immutable c = rgp.center;
        immutable r = rgp.radius;
        patt = cairo_pattern_create_radial(f[0], f[1], 0.0, c[0], c[1], r);
        patternAddStops(patt, rgp.stops);
        break;
    case PaintType.image:
        auto ip =  unsafeCast!ImagePaint(paint);
        auto surf = makeCairoSurface(ip.image);
        patt = cairo_pattern_create_for_surface(surf);
        cairo_surface_destroy(surf);
        break;
    default:
        assert(false, "unimplemented");
    }
    return patt;
}
