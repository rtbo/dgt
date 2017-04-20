/// Vector graphics path module.
module dgt.vg.path;

import dgt.geometry;

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
    private FRect _bounds;
    private bool _boundsDirty=true;

    this() {}

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
        _boundsDirty = true;
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
        _boundsDirty = true;
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
        _boundsDirty = true;
    }

    void cubicTo(float[2] control1, float[2] control2, float[2] point)
    {
        _segments ~= PathSeg.cubicTo;
        _data ~= [control1[0], control1[1], control2[0], control2[1], point[0], point[1]];
        _lastControl = control2;
        _lastPoint = point;
        _boundsDirty = true;
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

    /// Axis-aligned bounds
    @property FRect bounds() const
    {
        if (!_boundsDirty) return _bounds;
        else return computeBounds();
    }

    /// ditto
    @property FRect bounds()
    {
        if (_boundsDirty) {
            _bounds = computeBounds();
            _boundsDirty = false;
        }
        return _bounds;
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

    private FRect computeBounds() const
    {
        bool firstSet;
        FRect res;
        void addPoint(in FPoint point) {
            if (firstSet) {
                res.extend!float(point);
            }
            else {
                res.x = point.x;
                res.y = point.y;
                res.width = 0;
                res.height = 0;
                firstSet = true;
            }
        }

        FPoint lastP;
        const(float)[] data = _data;

        foreach(seg; _segments) {
            final switch (seg) {
            case PathSeg.moveTo:
            case PathSeg.lineTo:
                lastP = FPoint(data[0 .. 2]);
                addPoint(lastP);
                data = data[2 .. $];
                break;
            case PathSeg.quadTo:
                immutable p0 = lastP;
                immutable p1 = FPoint(data[0 .. 2]);
                immutable p2 = FPoint(data[2 .. 4]);
                addPoint(p2);
                res.extendWithQuad(p0, p1, p2);
                lastP = p2;
                data = data[4 .. $];
                break;
            case PathSeg.cubicTo:
                immutable p0 = lastP;
                immutable p1 = FPoint(data[0 .. 2]);
                immutable p2 = FPoint(data[2 .. 4]);
                immutable p3 = FPoint(data[4 .. 6]);
                addPoint(p3);
                res.extendWithCubic(p0, p1, p2, p3);
                lastP = p3;
                data = data[6 .. $];
                break;
            case PathSeg.close:
                break;
            }
        }
        return res;
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


private void extendWithQuad(ref FRect r, in FPoint p0, in FPoint p1, in FPoint p2)
{
    // find t for B'(t) = 0
    // with B(t) = (1-t)²p0 + 2t(1-t)p1 + t²p2    with t ∊ [0, 1]
    //     B'(t) = 2t(p0 + 2p1 + p2) + 2p1 - 2p0
    //     B'(t) = 0 for t = -b/a    with
    //     a = p0 + 2p1 + p2    and    b = p1 - p0

    float[2] buf;
    float[] extrema (size_t i) {
        immutable size_t bs = i; // buf start
        size_t bp = bs; // buf pos

        immutable real a = p0[i] + 2*p1[i] + p2[i];
        immutable real b = p1[i] - p0[i];
        immutable t = -b/a;
        if (t > 0 && t < 1) {
            immutable t1 = 1-t;
            buf[bp++] = cast(float)(t1*t1*p0[i] + 2*t*t1*p1[i] + t*t*p2[i]);
        }
        return buf[bs .. bp];
    }

    foreach(x; extrema(0)) {
        if (x < r.left) r.left = x;
        else if (x > r.right) r.right = x;
    }
    foreach(y; extrema(1)) {
        if (y < r.top) r.top = y;
        else if (y > r.bottom) r.bottom = y;
    }
}

private void extendWithCubic(ref FRect r, in FPoint p0, in FPoint p1, in FPoint p2, in FPoint p3)
{
    // find t for B'(t) = 0
    // with B(t) = (1-t)³p0 + 3t(1-t)²p1 + 3t²(1-t)p2 + t³p3   with t ∊ [0, 1]
    //      B'(t) = 3(3p1-3p2+p3-p0)t² + 6(p0-2p1+p2)t + 3p1 - 3p0
    //      B'(t) = at² + 2bt + c = 0
    //      a = 3p1-3p2+p3-p0    b = p0-2p1+p2   c = p1-p0
    //
    //  if a = 0, we are in order 1:
    //      t = -c/2b
    //
    //  otherwise, order 2 (simplified due to 2b):
    //      d = b² - ac
    //      if d > 0:    t1 = (-b+sqrt(d))/a      t2 = (-b-sqrt(d))/a
    //      if d = 0:    t = -b/a

    float[4] buf;
    float[] extremas(size_t i)
    {
        immutable size_t bs = i*2; // buf start
        size_t bp = bs; // buf pos

        void addPolynom(in real t)
        {
            if (t > 0 && t < 1) {
                immutable t1 = 1-t;
                buf[bp++] = cast(float)(
                    t1*t1*t1*p0[i] + 3*t*t1*t1*p1[i] + 3*t*t*t1*p2[i] + t*t*t*p3[i]
                );
            }
        }

        immutable real a = 3*p1[i] + p3[i] - 3*p2[i] - p0[i];
        immutable real b = p0[i] - 2*p1[i] + p2[i];
        immutable real c = p1[i] - p0[i];
        if (a == 0 && b != 0) {
            addPolynom(-c/(2*b));
        }
        else if (a != 0) {
            immutable d = b*b - a*c;
            if (d > 0) {
                import std.math : sqrt;
                immutable srd = sqrt(d);
                addPolynom((-b+srd)/a);
                addPolynom((-b-srd)/a);
            }
            else if (d == 0) {
                addPolynom(-b/a);
            }
        }
        return buf[bs .. bp];
    }

    foreach(x; extremas(0)) {
        if (x < r.left) r.left = x;
        else if (x > r.right) r.right = x;
    }
    foreach(y; extremas(1)) {
        if (y < r.top) r.top = y;
        else if (y > r.bottom) r.bottom = y;
    }
}

unittest
{
    import dgt.math.approx : approxUlp;
    auto p = new Path;
    p.moveTo([5, 5]);
    p.cubicTo([5, 25], [25, 25], [25, 5]);

    immutable b = p.bounds;
    assert(approxUlp(b.left, 5f));
    assert(approxUlp(b.top, 5f));
    assert(approxUlp(b.right, 25f));
    assert(approxUlp(b.bottom, 20f));
}
