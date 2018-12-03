/// Cairo Vector graphics backend
module dgt.vg.backend.cairo;

import dgt.vg;

package(dgt.vg) __gshared VgBackend cairoBackend = null;


private:

import dgt : registerSubsystem, Subsystem;
import dgt.bindings.cairo;
import dgt.core.color : Color;
import dgt.core.image : Image, ImageFormat;
import dgt.core.paint;
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


final class CairoContext : VgContext
{
    private Image _img;
    private RPen _pen;
    private RBrush _brush;
    private RPath _path;
    private FMat2x3 _ctm;

    private cairo_surface_t* _surf;
    private cairo_t* _cr;

    private struct State
    {
        RPen pen;
        RBrush brush;
        FMat2x3 ctm;
    }

    this (Image image)
    {
        _img = image;
        _surf = makeCairoSurface(_img);
        _cr = cairo_create(_surf);
        _ctm = FMat2x3.identity;
        // cairo happens to have the same default parameter as dgt, except
        // for the line width
        cairo_set_line_width(_cr, 1.0);
        _pen = defaultPen;
        _brush = defaultBrush;
    }

    override void dispose()
    {
        cairo_surface_flush(_surf);
        cairo_destroy(_cr);
        cairo_surface_destroy(_surf);
    }

    override Image image()
    {
        return _img;
    }

    override void save()
    {}
    override void restore()
    {}

    override FMat2x3 transform() const
    {
        return FMat2x3.init;
    }
    override void transform(const ref FMat2x3 transform)
    {}

    override void pushTransform(const ref FMat2x3 transform)
    {}
    override void popTransform()
    {}

    override void clip(immutable(Path) path)
    {}
    override void resetClip()
    {}

    override void mask(immutable(Image) mask, immutable(Paint) paint)
    {}

    override void drawImage(immutable(Image) img)
    {}

    override void clear(in Color color)
    {}

    override void stroke(immutable(Path) path, immutable(Pen) pen=null)
    {
        setPen(pen ? pen : defaultPen);
        setPath(path);
    }

    override void fill(immutable(Path) path, immutable(Brush) brush=null)
    {}

    private void setCairoTransform(in FMat2x3 tr)
    {
        // cairo matrix is column major
        const cm = cairo_matrix_t (
            tr[0, 0], tr[1, 0],
            tr[0, 1], tr[1, 1],
            tr[0, 2], tr[1, 2],
        );
        cairo_set_matrix(_cr, &cm);
    }

    private void setPen(immutable(Pen) pen)
    {
        if (pen is _pen.get) return;

        cairo_set_line_width(_cr, pen.width);
        cairo_set_line_cap(_cr, cairoLineCap(pen.cap));
        cairo_set_line_join(_cr, cairoLineJoin(pen.join));
        setDash(pen.dash);
        _pen = pen;
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

final class CairoSubsystem : Subsystem
{
    override @property string name() const
    {
        return "Cairo Vector Graphics";
    }
    override @property bool running() const {
        return cairoBackend !is null;
    }
    override @property int priority() const {
        return 0;
    }
    override void initialize()
    {
        import dgt.bindings.cairo.load : loadCairoSymbols;

        loadCairoSymbols();
        cairoBackend = new CairoBackend;
    }
    override void finalize()
    {
        cairoBackend = null;
    }
}

shared static this()
{
    registerSubsystem(new CairoSubsystem);
}
