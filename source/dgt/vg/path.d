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
    close,
}

/// Tell how many components compose a segment
size_t numComponents(in PathSeg seg)
{
    final switch (seg)
    {
    case PathSeg.moveTo:
        return 2;
    case PathSeg.lineTo:
        return 2;
    case PathSeg.quadTo:
        return 4;
    case PathSeg.cubicTo:
        return 6;
    case PathSeg.close:
        return 0;
    }
}

/// Vector graphics path
class Path
{
    // FIXME: enforce path consistence
    private PathSeg[] _segments;
    private float[] _data;
    private float[2] _lastControl;
    private float[2] _lastPoint;

    this(in float[2] moveToPoint)
    {
        _segments = [PathSeg.moveTo];
        _data = moveToPoint.dup;
        _lastControl[] = float.nan;
        _lastPoint = moveToPoint;
    }

    @property const(PathSeg)[] segments() const
    {
        return _segments;
    }

    @property const(float)[] data() const
    {
        return _data;
    }

    @property float[2] lastControl() const
    {
        return _lastControl;
    }

    @property float[2] lastPoint() const
    {
        return _lastPoint;
    }

    @property auto segmentRange() const
    {
        return SegmentDataRange(_segments, _data);
    }

    void moveTo(in float[2] point)
    {
        _segments ~= PathSeg.moveTo;
        _data ~= point.dup;
        _lastControl[] = float.nan;
        _lastPoint = point;
    }

    void moveToRel(in float[2] vec)
    {
        enforce(hasLastPoint);
        moveTo([_lastPoint[0] + vec[0], _lastPoint[1] + vec[1]]);
    }

    void lineTo(in float[2] point)
    {
        _segments ~= PathSeg.lineTo;
        _data ~= point.dup;
        _lastControl[] = float.nan;
        _lastPoint = point;
    }

    void lineToRel(in float[2] vec)
    {
        enforce(hasLastPoint);
        lineTo([_lastPoint[0] + vec[0], _lastPoint[1] + vec[1]]);
    }

    void horLineTo(in float xPoint)
    {
        enforce(hasLastPoint);
        lineTo([xPoint, _lastPoint[1]]);
    }

    void horLineToRel(in float xVec)
    {
        enforce(hasLastPoint);
        lineTo([_lastPoint[0] + xVec, _lastPoint[1]]);
    }

    void verLineTo(in float yPoint)
    {
        enforce(hasLastPoint);
        lineTo([_lastPoint[0], yPoint]);
    }

    void verLineToRel(in float yVec)
    {
        enforce(hasLastPoint);
        lineTo([_lastPoint[0], _lastPoint[1] + yVec]);
    }

    void quadTo(in float[2] control, in float[2] point)
    {
        _segments ~= PathSeg.quadTo;
        _data ~= [control[0], control[1], point[0], point[1]];
        _lastControl = control;
        _lastPoint = point;
    }

    void cubicTo(float[2] control1, float[2] control2, float[2] point)
    {
        _segments ~= PathSeg.cubicTo;
        _data ~= [control1[0], control1[1], control2[0], control2[1], point[0], point[1]];
        _lastControl = control2;
        _lastPoint = point;
    }

    void smoothQuadTo(float[2] point)
    {
        enforce(hasLastControl);
        enforce(hasLastPoint);
        quadTo([2 * _lastPoint[0] - _lastControl[0], 2 * _lastPoint[1] - _lastControl[1]], point);
    }

    void smoothCubicTo(float[2] control2, float[2] point)
    {
        enforce(hasLastControl);
        enforce(hasLastPoint);
        cubicTo([2 * _lastPoint[0] - _lastControl[0],
                2 * _lastPoint[1] - _lastControl[1]], control2, point);
    }

    void shortCcwArcTo(float rh, float rv, float rot, float[2] point)
    {
        // TODO: implement with quad or cubic
        assert(false, "unimplemented");
    }

    void shortCwArcTo(float rh, float rv, float rot, float[2] point)
    {
        // TODO: implement with quad or cubic
        assert(false, "unimplemented");
    }

    void largeCcwArcTo(float rh, float rv, float rot, float[2] point)
    {
        // TODO: implement with quad or cubic
        assert(false, "unimplemented");
    }

    void largeCwArcTo(float rh, float rv, float rot, float[2] point)
    {
        // TODO: implement with quad or cubic
        assert(false, "unimplemented");
    }

    /// Throws: Exception if no moveTo can be found before this call.
    void close()
    {
        import std.range : retro;
        _segments ~= PathSeg.close;
        _lastControl[] = float.nan;
        // reverse search for the last move to or throw
        size_t offset = 0;
        foreach(seg; retro(_segments[0 .. $-1]))
        {
            offset += seg.numComponents;
            if (seg == PathSeg.moveTo)
            {
                assert(offset <= _data.length && offset >= 2);
                _lastPoint = _data[$-offset .. $-(offset-2)];
                return;
            }
        }
        enforce(false, "close without moveTo segment");
    }

    private @property hasLastPoint() const
    {
        import std.math : isNaN;

        return !isNaN(_lastPoint[0]) && !isNaN(_lastPoint[1]);
    }

    private @property hasLastControl() const
    {
        import std.math : isNaN;

        return !isNaN(_lastControl[0]) && !isNaN(_lastControl[1]);
    }
}

/// Aggregates the data of a Path segment
struct SegmentData
{
    /// The segment type.
    PathSeg seg;
    /// The data of this segment.
    const(float)[] data;
    /// The last control point of the previous segment.
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
        return segments.empty;
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

        final switch (seg)
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
        case PathSeg.close:
            previousControl[] = float.nan;
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
