module dgt.vg.path;

import std.range.primitives;
import std.exception : enforce;

/// Path segments
enum PathSeg
{
    moveTo,
    lineTo,
    quadTo,
    cubicTo,
    shortCcwArcTo,
    shortCwArcTo,
    largeCcwArcTo,
    largeCwArcTo,
    close,
}

/// Tell how many components compose a segment
size_t numComponents(in PathSeg seg)
{
    final switch(seg)
    {
        case PathSeg.moveTo: return 2;
        case PathSeg.lineTo: return 2;
        case PathSeg.quadTo: return 4;
        case PathSeg.cubicTo: return 6;
        case PathSeg.shortCcwArcTo:
        case PathSeg.shortCwArcTo:
        case PathSeg.largeCcwArcTo:
        case PathSeg.largeCwArcTo: return 5;
        case PathSeg.close: return 0;
    }
}


/// Vector graphics path
class Path
{
    private PathSeg[] segments_;
    private float[] data_;
    private float[2] lastControl_;
    private float[2] lastPoint_;


    this(in float[2] moveToPoint)
    {
        segments_ = [ PathSeg.moveTo ];
        data_ = moveToPoint.dup;
        lastControl_[] = float.nan;
        lastPoint_ = moveToPoint;
    }

    @property const(PathSeg)[] segments() const { return segments_; }
    @property const(float)[] data() const { return data_; }
    @property float[2] lastControl() const { return lastControl_; }
    @property float[2] lastPoint() const { return lastPoint_; }

    @property auto segmentRange() const
    {
        return SegmentDataRange(segments_, data_);
    }

    void moveTo(in float[2] point)
    {
        segments_ ~= PathSeg.moveTo;
        data_ ~= point.dup;
        lastControl_[] = float.nan;
        lastPoint_ = point;
    }

    void moveToRel(in float[2] vec)
    {
        enforce(hasLastPoint);
        moveTo([lastPoint_[0]+vec[0], lastPoint_[1]+vec[1]]);
    }

    void lineTo(in float[2] point)
    {
        segments_ ~= PathSeg.lineTo;
        data_ ~= point.dup;
        lastControl_[] = float.nan;
        lastPoint_ = point;
    }

    void lineToRel(in float[2] vec)
    {
        enforce(hasLastPoint);
        lineTo([lastPoint_[0]+vec[0], lastPoint_[1]+vec[1]]);
    }

    void horLineTo(in float xPoint)
    {
        enforce(hasLastPoint);
        lineTo([xPoint, lastPoint_[1]]);
    }

    void horLineToRel(in float xVec)
    {
        enforce(hasLastPoint);
        lineTo([lastPoint_[0]+xVec, lastPoint_[1]]);
    }

    void verLineTo(in float yPoint)
    {
        enforce(hasLastPoint);
        lineTo([lastPoint_[0], yPoint]);
    }

    void verLineToRel(in float yVec)
    {
        enforce(hasLastPoint);
        lineTo([lastPoint_[0], lastPoint_[1]+yVec]);
    }

    void quadTo(in float[2] control, in float[2] point)
    {
        segments_ ~= PathSeg.quadTo;
        data_ ~= [ control[0], control[1], point[0], point[1] ];
        lastControl_ = control;
        lastPoint_ = point;
    }

    void cubicTo(float[2] control1, float[2] control2, float[2] point)
    {
        segments_ ~= PathSeg.cubicTo;
        data_ ~= [ control1[0], control1[1],
                    control2[0], control2[1],
                    point[0], point[1] ];
        lastControl_ = control2;
        lastPoint_ = point;
    }

    void smoothQuadTo(float[2] point)
    {
        enforce(hasLastControl);
        enforce(hasLastPoint);
        quadTo(
            [   2*lastPoint_[0] - lastControl_[0],
                2*lastPoint_[1] - lastControl_[1]   ],
            point
        );
    }

    void smoothCubicTo(float[2] control2, float[2] point)
    {
        enforce(hasLastControl);
        enforce(hasLastPoint);
        cubicTo(
            [   2*lastPoint_[0] - lastControl_[0],
                2*lastPoint_[1] - lastControl_[1]   ],
            control2,
            point
        );
    }

    void shortCcwArcTo(float rh, float rv, float rot, float[2] point)
    {
        segments_ ~= PathSeg.shortCcwArcTo;
        data_ ~= [rh, rv, rot, point[0], point[1]];
    }

    void shortCwArcTo(float rh, float rv, float rot, float[2] point)
    {
        segments_ ~= PathSeg.shortCwArcTo;
        data_ ~= [rh, rv, rot, point[0], point[1]];
    }

    void largeCcwArcTo(float rh, float rv, float rot, float[2] point)
    {
        segments_ ~= PathSeg.largeCcwArcTo;
        data_ ~= [rh, rv, rot, point[0], point[1]];
    }

    void largeCwArcTo(float rh, float rv, float rot, float[2] point)
    {
        segments_ ~= PathSeg.largeCwArcTo;
        data_ ~= [rh, rv, rot, point[0], point[1]];
    }

    void close()
    {
        segments_ ~= PathSeg.close;
    }

    private @property hasLastPoint() const
    {
        import std.math : isNaN;
        return !isNaN(lastPoint_[0]) && !isNaN(lastPoint_[1]);
    }

    private @property hasLastControl() const
    {
        import std.math : isNaN;
        return !isNaN(lastControl_[0]) && !isNaN(lastControl_[1]);
    }
}


/// Aggregates a the data of a Path segment
struct SegmentData
{
    /// The segment type.
    PathSeg seg;
    /// The data of this segment.
    const(float)[] data;
    /// The last control point of the previous segment.
    /// For lineTo segments, previousControl is the start point of the line.
    float[2] previousControl;
    /// The end point of the previous segment.
    float[2] previousPoint;
}


/// Segment data forward range.
/// Allow lazy iteration over the segments of a path.
struct SegmentDataRange
{
    private const(PathSeg)[] segments;
    private const(float)[] data;
    private float[2] previousControl;
    private float[2] previousPoint;

    this(const(PathSeg)[] segments, const(float)[] data)
    {
        this.segments = segments;
        this.data = data;
    }

    private this(const(PathSeg)[] segments, const(float)[] data,
                in float[2] previousControl, in float[2] previousPoint)
    {
        this.segments = segments;
        this.data = data;
        this.previousControl = previousControl;
        this.previousPoint = previousPoint;
    }

    @property bool empty()
    {
        return segments.empty || data.empty;
    }

    @property auto front()
    {
        assert(segments.length);
        auto seg = segments[0];
        auto count = seg.numComponents;
        assert(data.length >= count);
        return SegmentData(seg, data[0 .. count], previousControl, previousPoint);
    }

    void popFront()
    {
        import std.math : isNaN;

        assert(segments.length);
        immutable seg = segments[0];
        immutable numComps = seg.numComponents;
        assert(data.length >= numComps);

        final switch(seg)
        {
            case PathSeg.moveTo:
                previousControl[] = float.nan;
                previousPoint = data[0 .. 2];
                break;
            case PathSeg.lineTo:
                previousControl[] = float.nan;
                previousPoint = data[0 .. 2];
                break;
            case PathSeg.quadTo:
                previousControl = data[0 .. 2];
                previousPoint = data[2 .. 4];
                break;
            case PathSeg.cubicTo:
                previousControl = data[2 .. 4];
                previousPoint = data[4 .. 6];
                break;
            case PathSeg.shortCcwArcTo:
            case PathSeg.shortCwArcTo:
            case PathSeg.largeCcwArcTo:
            case PathSeg.largeCwArcTo:
                previousControl[] = float.nan;
                previousPoint = data[3 .. 5];
                break;
            case PathSeg.close:
                break;
        }

        segments = segments[1 .. $];
        data = data[numComps .. $];
    }

    @property auto save()
    {
        return SegmentDataRange(segments, data, previousControl, previousPoint);
    }
}

static assert(isForwardRange!SegmentDataRange);
