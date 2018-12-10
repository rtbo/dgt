/// Vector graphics path module.
module dgt.vg.path;

import dgt.core.geometry : FPoint, FRect;
import gfx.math : FMat2x3, FVec2;

import std.exception : enforce;
import std.range.primitives;
import std.typecons : Rebindable;

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
        return 1;
    case PathSeg.lineTo:
        return 1;
    case PathSeg.quadTo:
        return 2;
    case PathSeg.cubicTo:
        return 3;
    case PathSeg.close:
        return 0;
    }
}

/// Vector graphics path builder
struct PathBuilder
{
    private PathSeg[] _segments;
    private FVec2[] _data;
    private FVec2 _lastControl = FVec2.nan;
    private FVec2 _lastPoint = FVec2.nan;
    private size_t _lastMoveTo = size_t.max; // data offset of last moveTo
    private FRect _bounds;
    private bool _boundsSet = false;

    this(in FVec2 moveToPoint)
    {
        _segments = [ PathSeg.moveTo ];
        _data = [ moveToPoint ];
        _lastControl = FVec2.nan;
        _lastPoint = moveToPoint;
        _lastMoveTo = 0;
    }

    private this (PathSeg[] segs, FVec2[] data, FVec2 lastC, FVec2 lastP, size_t lastMT, FRect bounds, bool boundsSet)
    {
        _segments = segs;
        _data = data;
        _lastControl = lastC;
        _lastPoint = lastP;
        _lastMoveTo = lastMT;
        _bounds = bounds;
        _boundsSet = boundsSet;
    }

    @disable this(this);

    PathBuilder dup() const
    {
        return PathBuilder(
            _segments.dup, _data.dup, _lastControl, _lastPoint, _lastMoveTo, _bounds, _boundsSet
        );
    }

    @property const(PathSeg)[] segments() const
    {
        return _segments;
    }

    @property const(FVec2)[] data() const
    {
        return _data;
    }

    @property FVec2 lastControl() const
    {
        return _lastControl;
    }

    @property FVec2 lastPoint() const
    {
        return _lastPoint;
    }

    ref PathBuilder moveTo(in FVec2 point)
    {
        _lastMoveTo = _data.length;
        _segments ~= PathSeg.moveTo;
        _data ~= point;
        _lastControl = FVec2.nan;
        _lastPoint = point;
        return this;
    }

    ref PathBuilder moveToRel(in FVec2 vec)
    {
        enforce(hasLastPoint);
        return moveTo(_lastPoint + vec);
    }

    ref PathBuilder lineTo(in FVec2 point)
    {
        _segments ~= PathSeg.lineTo;
        _data ~= point;
        _lastControl = _lastPoint;
        _lastPoint = point;
        return this;
    }

    ref PathBuilder lineToRel(in FVec2 vec)
    {
        enforce(hasLastPoint);
        return lineTo(_lastPoint + vec);
    }

    ref PathBuilder horLineTo(in float xPoint)
    {
        enforce(hasLastPoint);
        return lineTo(FVec2(xPoint, _lastPoint.y));
    }

    ref PathBuilder horLineToRel(in float xVec)
    {
        enforce(hasLastPoint);
        return lineTo(FVec2(_lastPoint.x + xVec, _lastPoint.y));
    }

    ref PathBuilder verLineTo(in float yPoint)
    {
        enforce(hasLastPoint);
        return lineTo(FVec2(_lastPoint[0], yPoint));
    }

    ref PathBuilder verLineToRel(in float yVec)
    {
        enforce(hasLastPoint);
        return lineTo(FVec2(_lastPoint.x, _lastPoint.y + yVec));
    }

    ref PathBuilder quadTo(in FVec2 control, in FVec2 point)
    {
        _segments ~= PathSeg.quadTo;
        _data ~= [ control, point ];
        _lastControl = control;
        _lastPoint = point;
        return this;
    }

    ref PathBuilder cubicTo(in FVec2 control1, in FVec2 control2, in FVec2 point)
    {
        _segments ~= PathSeg.cubicTo;
        _data ~= [ control1, control2, point ];
        _lastControl = control2;
        _lastPoint = point;
        return this;
    }

    ref PathBuilder smoothQuadTo(FVec2 point)
    {
        enforce(hasLastControl);
        enforce(hasLastPoint);
        return quadTo( 2 * _lastPoint - _lastControl, point );
    }

    ref PathBuilder smoothCubicTo(in FVec2 control2, in FVec2 point)
    {
        enforce(hasLastControl);
        enforce(hasLastPoint);
        return cubicTo( 2 * _lastPoint - _lastControl, control2, point );
    }

    ref PathBuilder shortCcwArcTo(float rh, float rv, float rot, in FVec2 point)
    {
        // TODO: implement with quad or cubic
        assert(false, "unimplemented");
    }

    ref PathBuilder shortCwArcTo(float rh, float rv, float rot, in FVec2 point)
    {
        // TODO: implement with quad or cubic
        assert(false, "unimplemented");
    }

    ref PathBuilder largeCcwArcTo(float rh, float rv, float rot, in FVec2 point)
    {
        // TODO: implement with quad or cubic
        assert(false, "unimplemented");
    }

    void largeCwArcTo(float rh, float rv, float rot, in FVec2 point)
    {
        // TODO: implement with quad or cubic
        assert(false, "unimplemented");
    }

    /// Throws: Exception if no moveTo can be found before this call.
    ref PathBuilder close()
    {
        import std.exception : enforce;

        enforce(_data.length > _lastMoveTo, "Cannot close an empty path");

        _segments ~= PathSeg.close;
        _lastPoint = _data[_lastMoveTo];
        _lastControl = FVec2.nan;

        return this;
    }

    ref PathBuilder bounds(in FRect bounds)
    {
        _bounds = bounds;
        _boundsSet = true;
        return this;
    }

    immutable(Path) done()
    {
        import std.exception : assumeUnique;

        // FIXME: enforce path consistence
        immutable segs = assumeUnique(_segments);
        immutable data = assumeUnique(_data);
        if (_boundsSet) {
            return new immutable Path(segs, data, _bounds);
        }
        else {
            return new immutable Path(segs, data);
        }
    }

    Path doneMut()
    {
        // FIXME: enforce path consistence
        if (_boundsSet) {
            return new Path(_segments, _data, _bounds);
        }
        else {
            return new Path(_segments, _data);
        }
    }

    private bool hasLastPoint() const
    {
        import std.math : isNaN;

        return !isNaN(_lastPoint.x);
    }

    private bool hasLastControl() const
    {
        import std.math : isNaN;

        return !isNaN(_lastControl.x);
    }
}

alias RPath = Rebindable!(immutable(Path));

/// A Path represent a vector graphics path, that is an assembly
/// of line primitives related to each other
final class Path
{
    immutable this (immutable(PathSeg)[] segments, immutable(FVec2)[] data)
    {
        _segments = segments;
        _data = data;
    }

    immutable this (immutable(PathSeg)[] segments, immutable(FVec2)[] data, in FRect bounds)
    {
        _segments = segments;
        _data = data;
        _bounds = bounds;
        _boundsCached = true;
    }

    this (PathSeg[] segments, FVec2[] data)
    {
        _segments = segments;
        _data = data;
    }

    this (PathSeg[] segments, FVec2[] data, in FRect bounds)
    {
        _segments = segments;
        _data = data;
        _bounds = bounds;
        _boundsCached = true;
    }

    static PathBuilder build()
    {
        return PathBuilder.init;
    }

    static PathBuilder build(in FVec2 moveToPoint)
    {
        return PathBuilder(moveToPoint);
    }

    const(PathSeg)[] segments() const
    {
        return _segments;
    }

    immutable(PathSeg)[] segments() immutable
    {
        return _segments;
    }


    const(FVec2)[] data() const
    {
        return _data;
    }

    immutable(FVec2)[] data() immutable
    {
        return _data;
    }

    auto segmentRange() const
    {
        return SegmentDataRange(_segments, _data);
    }

    @property FRect bounds() const
    {
        if (_boundsCached) {
            return _bounds;
        }
        else {
            return computeBounds();
        }
    }

    @property FRect bounds()
    {
        if (!_boundsCached) {
            _bounds = computeBounds();
            _boundsCached = true;
        }
        return _bounds;
    }

    FRect computeBounds(in FMat2x3 mat) const
    {
        import dgt.core.geometry : extend;
        import gfx.math : transform;

        if (mat == FMat2x3.identity) return bounds;

        FVec2 transformVec (in FVec2 v) {
            return transform(v, mat);
        }

        return computeBoundsImpl!transformVec(this);
    }

    private FRect computeBounds() const
    {
        return computeBoundsImpl!vecIdent(this);
    }

    private PathSeg[] _segments;
    private FVec2[] _data;
    private FRect _bounds;
    private bool _boundsCached;
}


/// Aggregates the data of a Path segment
struct SegmentData
{
    /// The segment type.
    PathSeg seg;
    /// The data of this segment.
    const(FVec2)[] data;
    /// The last control point of the previous segment.
    FVec2 previousControl;
    /// The end point of the previous segment.
    FVec2 previousPoint;
}

/// Segment data forward range.
/// Allow lazy iteration over the segments of a path.
struct SegmentDataRange
{
    private const(PathSeg)[] segments;
    private const(FVec2)[] data;
    private FVec2 previousControl;
    private FVec2 previousPoint;

    this(const(PathSeg)[] segments, const(FVec2)[] data)
    {
        this.segments = segments;
        this.data = data;
    }

    private this(const(PathSeg)[] segments, const(FVec2)[] data,
            in FVec2 previousControl, in FVec2 previousPoint)
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
        const seg = segments[0];
        const numComps = seg.numComponents;
        assert(data.length >= numComps);

        final switch (seg)
        {
        case PathSeg.moveTo:
            previousControl = FVec2.nan;
            previousPoint = data[0];
            break;
        case PathSeg.lineTo:
            previousControl = FVec2.nan;
            previousPoint = data[0];
            break;
        case PathSeg.quadTo:
            previousControl = data[0];
            previousPoint = data[1];
            break;
        case PathSeg.cubicTo:
            previousControl = data[1];
            previousPoint = data[2];
            break;
        case PathSeg.close:
            previousControl = FVec2.nan;
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

private FVec2 vecIdent(in FVec2 vec)
{
    return vec;
}

private FRect computeBoundsImpl(alias vecMap)(const(Path) path)
{
    import dgt.core.geometry : extend;

    bool firstSet;
    FRect res;
    void addPoint(in FVec2 vec) {
        if (firstSet) {
            res.extend(vec);
        }
        else {
            res = FRect(vec, 0f, 0f);
            firstSet = true;
        }
    }

    FVec2 lastP;
    const(FVec2)[] data = path._data;

    foreach(seg; path._segments) {
        final switch (seg) {
        case PathSeg.moveTo:
        case PathSeg.lineTo:
            lastP = vecMap(data[0]);
            addPoint(lastP);
            data = data[1 .. $];
            break;
        case PathSeg.quadTo:
            const p0 = lastP;
            const p1 = vecMap(data[0]);
            const p2 = vecMap(data[1]);
            addPoint(p2);
            res.extendWithQuad(p0, p1, p2);
            lastP = p2;
            data = data[2 .. $];
            break;
        case PathSeg.cubicTo:
            const p0 = lastP;
            const p1 = vecMap(data[0]);
            const p2 = vecMap(data[1]);
            const p3 = vecMap(data[2]);
            addPoint(p3);
            res.extendWithCubic(p0, p1, p2, p3);
            lastP = p3;
            data = data[3 .. $];
            break;
        case PathSeg.close:
            break;
        }
    }
    return res;
}

private void extendWithQuad(ref FRect r, in FPoint p0, in FPoint p1, in FPoint p2)
{
    import dgt.core.geometry : extendHor, extendVer;

    // find t for B'(t) = 0
    // with B(t) = (1-t)²p0 + 2t(1-t)p1 + t²p2    with t ∊ [0, 1]
    //     B'(t) = 2t(p0 - 2p1 + p2) + 2p1 - 2p0
    //     B'(t) = 0 for t = -b/a    with
    //     a = p0 - 2p1 + p2    and    b = p1 - p0

    bool extrema (size_t i, out float val) {
        const real a = p0[i] - 2*p1[i] + p2[i];
        const real b = p1[i] - p0[i];
        const t = -b/a;
        if (t > 0 && t < 1) {
            const t1 = 1-t;
            val = cast(float)(t1*t1*p0[i] + 2*t*t1*p1[i] + t*t*p2[i]);
            return true;
        }
        else return false;
    }

    float val;
    if (extrema(0, val)) {
        r.extendHor(val);
    }
    if (extrema(1, val)) {
        r.extendVer(val);
    }
}

private void extendWithCubic(ref FRect r, in FPoint p0, in FPoint p1, in FPoint p2, in FPoint p3)
{
    import dgt.core.geometry : extendHor, extendVer;

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
        r.extendHor(x);
    }
    foreach(y; extremas(1)) {
        r.extendVer(y);
    }
}

unittest
{
    import gfx.math : fvec;
    import gfx.math.approx : approxUlp;

    immutable path = Path.build(fvec(0, 50))
        .quadTo(fvec(0, 0), fvec(70, 0))
        .quadTo(fvec(100, 0), fvec(50, 50))
        .close()
        .done();

    const b = path.bounds();

    assert(approxUlp(b.left, 0f));
    assert(approxUlp(b.top, 0f));
    assert(approxUlp(b.right, 81.25f));
    assert(approxUlp(b.bottom, 50f));
}


unittest
{
    import gfx.math : fvec;
    import gfx.math.approx : approxUlp;

    immutable p = Path.build()
        .moveTo(fvec(5, 5))
        .cubicTo(fvec(5, 25), fvec(25, 25), fvec(25, 5))
        .done();

    const b = p.bounds();

    assert(approxUlp(b.left, 5f));
    assert(approxUlp(b.top, 5f));
    assert(approxUlp(b.right, 25f));
    assert(approxUlp(b.bottom, 20f));
}
