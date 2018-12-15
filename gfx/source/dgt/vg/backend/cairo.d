/// Cairo Vector graphics backend
module dgt.vg.backend.cairo;

import dgt.vg;

package(dgt.vg) __gshared VgBackend cairoBackend = null;


private:

import dgt.bindings.cairo;
import dgt.gfx.color : Color;
import dgt.core.container : GrowableStack;
import dgt.gfx.geometry : FRect;
import dgt.gfx.image : Image, ImageFormat;
import dgt.gfx.paint;
import gfx.math : FMat2x3, FMat3, FVec2;

final class CairoBackend : VgBackend
{
    string name()
    {
        return "cairo";
    }

    VgContext makeContext(Image image)
    {
        return new CairoContext(image);
    }
}

struct State
{
    RPen pen;
    RBrush brush;
    FMat2x3 transform;
    CairoSource source;

    this (immutable(Pen) pen, immutable(Brush) brush)
    {
        this.pen = pen;
        this.brush = brush;
        transform = FMat2x3.identity;
    }
}

final class CairoContext : VgContext
{
    private Image _img;
    private cairo_surface_t* _surf;
    private cairo_t* _cr;

    private RPath _path;

    private State _current;
    private GrowableStack!State _state;

    this (Image image)
    {
        _img = image;
        _surf = makeCairoSurface(_img);
        _cr = cairo_create(_surf);
        // cairo happens to have the same default parameter as dgt, except
        // for the line width
        cairo_set_line_width(_cr, 1.0);
        _current = State ( defaultPen, defaultBrush );
    }

    override void dispose()
    {
        _current = State.init;
        _state.clear();
        cairo_surface_flush(_surf);
        cairo_destroy(_cr);
        cairo_surface_destroy(_surf);
    }

    override Image image()
    {
        return _img;
    }

    override void save()
    {
        _state.push(_current);
        cairo_save(_cr);
    }
    override void restore()
    {
        cairo_save(_cr);
        _current = _state.pop();
    }

    override FMat2x3 transform() const
    {
        return _current.transform;
    }

    override void transform(in FMat2x3 transform)
    {
        _current.transform = transform;
        setCairoTransform(transform);
    }

    override void mulTransform(in FMat2x3 transform)
    {
        import gfx.math : affineMult;

        _current.transform = affineMult(_current.transform, transform);
        setCairoTransform(_current.transform);
    }

    override void clip(immutable(Path) path)
    {
        setPath(path);
        cairo_clip_preserve(_cr);
    }

    override void mask(immutable(Image) mask, immutable(Paint) paint)
    {
        setSource(paint);
        auto maskSrc = CairoSource(mask);

        cairo_mask(_cr, maskSrc.patt);
    }

    override void drawImage(immutable(Image) img)
    {
        setSource(img);

        cairo_paint(_cr);
    }

    override void clear(in Color color)
    {
        const c = color.asFloats;
        cairo_save(_cr);
        if (c[3] == 1) {
            cairo_set_source_rgba(_cr, c[0], c[1], c[2], c[3]);
        }
        else if (c[3] == 0) {
            cairo_set_operator(_cr, CAIRO_OPERATOR_CLEAR);
        }
        else {
            cairo_set_source_rgba(_cr, c[0], c[1], c[2], c[3]);
            cairo_set_operator(_cr, CAIRO_OPERATOR_SOURCE);
        }
        cairo_paint(_cr);
        cairo_restore(_cr);
    }

    override void stroke(immutable(Path) path, immutable(Pen) pen=null)
    {
        setPen(pen ? pen : defaultPen);
        setPath(path);
        cairo_stroke_preserve(_cr);
    }

    override void fill(immutable(Path) path, immutable(Brush) brush=null)
    {
        setBrush(brush ? brush : defaultBrush);
        setPath(path);
        cairo_fill_preserve(_cr);
    }

    private ref State state()
    {
        return _state.peek;
    }

    private void setPath(immutable(Path) path)
    {
        if (path is _path) return;

        cairo_new_path(_cr);

        foreach (seg; path.segmentRange)
        {
            final switch (seg.seg)
            {
            case PathSeg.moveTo:
                cairo_move_to(_cr, seg.data[0].x, seg.data[0].y);
                break;
            case PathSeg.lineTo:
                cairo_line_to(_cr, seg.data[0].x, seg.data[0].y);
                break;
            case PathSeg.quadTo:
                const cps = quadToCubicControlPoints(seg.previousPoint,
                        seg.data[0], seg.data[1]);
                cairo_curve_to(_cr, cps[0].x, cps[0].y, cps[1].x, cps[1].y,
                        seg.data[1].x, seg.data[1].y);
                break;
            case PathSeg.cubicTo:
                cairo_curve_to(_cr, seg.data[0].x, seg.data[0].y,
                        seg.data[1].x, seg.data[1].y,
                        seg.data[2].x, seg.data[2].y);
                break;
            case PathSeg.close:
                cairo_close_path(_cr);
                break;
            }
        }

        _path = path;
    }

    private void setCairoTransform(in ref FMat2x3 tr)
    {
        // cairo matrix is column major
        const cm = CairoMatrix(tr);
        cairo_set_matrix(_cr, &cm.mat);
    }

    private void setPen(immutable(Pen) pen)
    {
        setSource(pen.paint);

        if (pen is _current.pen.get) return;

        cairo_set_line_width(_cr, pen.width);
        cairo_set_line_cap(_cr, cairoLineCap(pen.cap));
        cairo_set_line_join(_cr, cairoLineJoin(pen.join));
        setDash(pen.dash);

        _current.pen = pen;
    }

    private void setBrush(immutable(Brush) brush)
    {
        setSource(brush.paint);

        if (brush is _current.brush.get) return;

        cairo_set_fill_rule(_cr, cairoFillRule(brush.fillRule));

        _current.brush = brush;
    }

    private void setDash(in Dash dash)
    {
        if (dash.values.length) {
            static double[] dashes;
            dashes.length = dash.values.length;
            foreach(i, v; dash.values) dashes[i] = v;
            cairo_set_dash(_cr, &dashes[0], cast(int)dash.values.length, dash.offset);
        }
        else {
            cairo_set_dash(_cr, null, 0, 0f);
        }
    }

    private void setSource(immutable(Paint) paint)
    {
        if (_current.source.paint is paint) return;

        _current.source = CairoSource(paint);
        cairo_set_source(_cr, _current.source.patt);
    }

    private void setSource(immutable(Image) img)
    {
        if (_current.source.image is img) return;

        _current.source = CairoSource(img);
        cairo_set_source(_cr, _current.source.patt);
    }
}

struct CairoMatrix
{
    cairo_matrix_t mat;

    this (in ref FMat2x3 m)
    {
        // cairo matrix is column major
        mat = cairo_matrix_t (
            m[0, 0], m[1, 0],
            m[0, 1], m[1, 1],
            m[0, 2], m[1, 2],
        );
    }
}

struct CairoSource
{
    import dgt.gfx.image : RImage;

    RPaint paint;
    RImage image;
    cairo_pattern_t* patt;

    this(immutable(Paint) paint)
    {
        import gfx.core.util : unsafeCast;

        this.paint = paint;
        image = null;

        switch (paint.type)
        {
        case PaintType.color:
            const cp = unsafeCast!(immutable ColorPaint)(paint);
            const c = cp.color.asFloats;
            patt = cairo_pattern_create_rgba(c[0], c[1], c[2], c[3]);
            break;
        case PaintType.linearGradient:
            const lgp = unsafeCast!(immutable LinearGradientPaint)(paint);
            // line is between (-1, 0) (1, 0) in pattern space
            // this will be adjusted using matrix for each shape bounds
            patt = cairo_pattern_create_linear(-1.0, 0.0, 1.0, 0.0);
            patternAddStops(patt, lgp.stops);
            break;
        case PaintType.radialGradient:
            const rgp = unsafeCast!(immutable RadialGradientPaint)(paint);
            const f = rgp.focal;
            const c = rgp.center;
            const r = rgp.radius;
            patt = cairo_pattern_create_radial(f[0], f[1], 0.0, c[0], c[1], r);
            patternAddStops(patt, rgp.stops);
            break;
        case PaintType.image:
            const ip =  unsafeCast!(immutable ImagePaint)(paint);
            // Casting immutable away. Not nice, but necessary in this case to avoid
            // a copy of the image. The pattern must be used readonly.
            image = makeVgCompatible(ip.image);
            auto surf = makeCairoSurface(cast(Image)image.get);
            patt = cairo_pattern_create_for_surface(surf);
            cairo_surface_destroy(surf);
            break;
        default:
            assert(false, "unimplemented");
        }
    }

    this (immutable(Image) img)
    {
        image = makeVgCompatible(img);
        auto surf = makeCairoSurface(cast(Image)image.get);
        patt = cairo_pattern_create_for_surface(surf);
        cairo_surface_destroy(surf);
    }

    this (in Color color)
    {
        const c = color.asFloats;
        patt = cairo_pattern_create_rgba(c[0], c[1], c[2], c[3]);
    }

    this(this)
    {
        if (patt) cairo_pattern_reference(patt);
    }

    ~this()
    {
        if (patt) cairo_pattern_destroy(patt);
    }

    void adaptToPath(immutable(Path) path)
    {
        import gfx.core.util : unsafeCast;
        import std.math : PI;

        if (!patt || !path || !paint) return;
        if (paint.type != PaintType.linearGradient) return;

        immutable lgp = unsafeCast!(immutable(LinearGradientPaint))(paint.get);
        const bounds = path.bounds();
        const angle = PI/2.0 - lgp.computeAngle(bounds.size); // from horizontal

        const m = linearGradientMatrix(angle, bounds);
        const cm = CairoMatrix(m);
        cairo_pattern_set_matrix(patt, &cm.mat);
    }
}

cairo_surface_t* makeCairoSurface(Image image)
in (image && image.vgCompatible)
{
    return cairo_image_surface_create_for_data(
        image.data.ptr, cairoFormat(image.format),
        image.width, image.height, cast(int)image.stride
    );
}

void patternAddStops(cairo_pattern_t* patt, in GradientStop[] stops)
{
    foreach (stop; stops)
    {
        const col = stop.color.asFloats;
        cairo_pattern_add_color_stop_rgba(patt, stop.position,
                col[0], col[1], col[2], col[3]);
    }
}

/// Compute transform from a line that goes from (-1, 0) to (1, 0) to a line that
/// follows the angle and bounds
FMat2x3 linearGradientMatrix(in float angle, in ref FRect bounds)
{
    import gfx.math : dot, fvec, squaredMag;
    import gfx.math.transform;
    import std.algorithm : max;
    import std.math : abs, cos, PI, sin, sqrt, tan;

    // 3 cases: horizontal, vertical and general
    // all 3 are solved with bounds centered around 0, 0, then translated to bounds.center

    const w2 = bounds.width / 2f;
    const h2 = bounds.height / 2f;

    const c = cos(angle);
    const absC = abs(c);

    // horizontal / vertical threshold
    enum thres = 0.001f;

    if (absC > (1f - thres)) {
        // horizontal
        return affineScale(c > 0 ? w2 : -w2, 1f)
            .translate(bounds.center);
    }

    else if (absC < thres) {
        // vertical
        return affineRotation!float(sin(angle) > 0 ? PI/2f : -PI/2f)
            .scale(1f, h2)
            .translate(bounds.center);
    }

    // General case

    // unit ascent of the line
    const tanA = tan(angle);
    // vector along the line
    const l = fvec(1, tanA);
    const ll = dot(l, l);

    // projection of one point on the line
    FVec2 proj (FVec2 v) {
        return (dot(v, l) / ll) * l;
    }

    // Testing top-right and bottom-right.
    // The right line end has greatest magnitude. This will give the scale factor.
    const tr = proj(fvec(w2, h2));
    const br = proj(fvec(w2, -h2));

    const mag = sqrt(max(squaredMag(tr), squaredMag(br)));

    return affineScale(mag, 1f)
        .rotate(angle)
        .translate(bounds.center);
}

unittest
{
    import gfx.math : fvec, transform;
    import gfx.math.approx;
    import std.math : PI;
    import std.stdio;

    const v1 = fvec(-1, 0);
    const v2 = fvec(1, 0);
    const bounds = FRect(40, 60, 80, 60);

    const east = linearGradientMatrix(0f, bounds);
    assert(approxUlpAndAbs(v1.transform(east), fvec(40, 90)));
    assert(approxUlpAndAbs(v2.transform(east), fvec(120, 90)));

    const south = linearGradientMatrix(PI/2, bounds);
    assert(approxUlpAndAbs(v1.transform(south), fvec(80, 60)));
    assert(approxUlpAndAbs(v2.transform(south), fvec(80, 120)));

    const west = linearGradientMatrix(PI, bounds);
    assert(approxUlpAndAbs(v1.transform(west), fvec(120, 90)));
    assert(approxUlpAndAbs(v2.transform(west), fvec(40, 90)));

    const north = linearGradientMatrix(-PI/2, bounds);
    assert(approxUlpAndAbs(v1.transform(north), fvec(80, 120)));
    assert(approxUlpAndAbs(v2.transform(north), fvec(80, 60)));

    const southEast = linearGradientMatrix(PI/4, bounds);
    assert(approxUlpAndAbs(v1.transform(southEast), fvec(45, 55)));
    assert(approxUlpAndAbs(v2.transform(southEast), fvec(115, 125)));

    const southWest = linearGradientMatrix(3*PI/4, bounds);
    assert(approxUlpAndAbs(v1.transform(southWest), fvec(115, 55)));
    assert(approxUlpAndAbs(v2.transform(southWest), fvec(45, 125)));

    const northWest = linearGradientMatrix(-3*PI/4, bounds);
    assert(approxUlpAndAbs(v1.transform(northWest), fvec(115, 125)));
    assert(approxUlpAndAbs(v2.transform(northWest), fvec(45, 55)));

    const northEast = linearGradientMatrix(-PI/4, bounds);
    assert(approxUlpAndAbs(v1.transform(northEast), fvec(45, 125)));
    assert(approxUlpAndAbs(v2.transform(northEast), fvec(115, 55)));

}

pure @safe
{
    /// map ImageFormat to cairo_format_t
    cairo_format_t cairoFormat(in ImageFormat ifmt)
    {
        switch (ifmt)
        {
        case ImageFormat.a1:
            return CAIRO_FORMAT_A1;
        case ImageFormat.a8:
            return CAIRO_FORMAT_A8;
        case ImageFormat.xrgb:
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

    FVec2[2] quadToCubicControlPoints(in FVec2 start,
                                      in FVec2 control,
                                      in FVec2 end) pure nothrow @safe @nogc
    {
        return [
            start / 3f + control * 2f / 3f,
            end / 3f + control * 2f / 3f
        ];
    }

    cairo_fill_rule_t cairoFillRule(in FillRule fillRule)
    {
        final switch (fillRule)
        {
        case FillRule.nonZero:
            return CAIRO_FILL_RULE_WINDING;
        case FillRule.evenOdd:
            return CAIRO_FILL_RULE_EVEN_ODD;
        }
    }

    FillRule dgtFillRule(in cairo_fill_rule_t fillRule)
    {
        final switch (fillRule)
        {
        case CAIRO_FILL_RULE_WINDING:
            return FillRule.nonZero;
        case CAIRO_FILL_RULE_EVEN_ODD:
            return FillRule.evenOdd;
        }
    }

    cairo_line_cap_t cairoLineCap(in LineCap cap)
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

    LineCap dgtLineCap(in cairo_line_cap_t cap)
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

    cairo_line_join_t cairoLineJoin(in LineJoin val)
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

    LineJoin dgtLineJoin(in cairo_line_join_t val)
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

shared static this()
{
    import dgt.bindings.cairo.load : loadCairoSymbols;
    loadCairoSymbols();
    cairoBackend = new CairoBackend;
}
