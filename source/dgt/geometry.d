/// Geometric primitives module
module dgt.geometry;

import dgt.math.mat;
public import dgt.math.vec;

import std.algorithm : max, min;
import std.range;
import std.traits : isNumeric;

alias Point(T) = Vec2!T;
alias FPoint = Point!float;
alias IPoint = Point!int;
alias isPoint(T) = isVec!(2, T);

alias FSize = Size!float;
alias ISize = Size!int;

alias FPadding = Padding!float;
alias IPadding = Padding!int;
alias FMargins = Margins!float;
alias IMargins = Margins!int;

alias FRect = Rect!float;
alias IRect = Rect!int;

/// Represents a two dimensional size
struct Size(T) if (isNumeric!T)
{
    alias Scalar = T;

    T width =0;
    T height =0;

    this(in T width, in T height)
    {
        this.width = width;
        this.height = height;
    }

    this (in Vec2!T vec)
    {
        width = vec.x;
        height = vec.y;
    }

    U opCast(U : Size!V, V)() const
    {
        return Size!V(cast(V) width, cast(V) height);
    }
}

unittest
{
    auto sd = FSize(3, 5);
    assert(sd.area == 15);

    auto si = ISize(4, 15);
    assert(si.area == 60);

    static assert(__traits(compiles, sd = cast(FSize)si));
    static assert(__traits(compiles, si = cast(ISize)sd));
}

/// Compile time checks that T is a size
template isSize(T)
{
    import std.traits : TemplateOf;
    enum isSize = __traits(isSame, TemplateOf!T, Size);
}

static assert(  isSize!FSize);
static assert(  isSize!ISize);
static assert(! isSize!FPoint);


/// Represents padding inside a rectangular area
struct Padding(T) if (isNumeric!T)
{
    alias Scalar = T;

    T left =0;
    T top =0;
    T right =0;
    T bottom =0;

    this(in T left, in T top, in T right, in T bottom)
    {
        this.left = left;
        this.top = top;
        this.right = right;
        this.bottom = bottom;
    }

    this(in T hor, in T ver)
    {
        this.left = hor;
        this.top = ver;
        this.right = hor;
        this.bottom = ver;
    }

    this(in T constant)
    {
        left = constant;
        top = constant;
        right = constant;
        bottom = constant;
    }

    @property T horizontal() const
    {
        return left + right;
    }

    @property T vertical() const
    {
        return top + bottom;
    }

    U opCast(U : Padding!V, V)() const
    {
        return Padding!V(cast(V) left, cast(V) top, cast(V) right, cast(V) bottom);
    }
}

/// Compile time checks that T is a padding
template isPadding(T)
{
    import std.traits : TemplateOf;
    enum isPadding = __traits(isSame, TemplateOf!T, Padding);
}

static assert(  isPadding!FPadding);
static assert(  isPadding!IPadding);
static assert(! isPadding!IMargins);

/// Represents margins around a rectangular area
struct Margins(T) if (isNumeric!T)
{
    alias Scalar = T;

    T left =0;
    T top =0;
    T right =0;
    T bottom =0;

    this(in T left, in T top, in T right, in T bottom)
    {
        this.left = left;
        this.top = top;
        this.right = right;
        this.bottom = bottom;
    }

    this(in T hor, in T ver)
    {
        this.left = hor;
        this.top = ver;
        this.right = hor;
        this.bottom = ver;
    }

    this(in T constant)
    {
        left = constant;
        top = constant;
        right = constant;
        bottom = constant;
    }

    @property T horizontal() const
    {
        return left + right;
    }

    @property T vertical() const
    {
        return top + bottom;
    }

    U opCast(U : Margins!V, V)() const
    {
        return Margins!V(cast(V) left, cast(V) top, cast(V) right, cast(V) bottom);
    }
}

unittest
{
    auto md = FMargins(3, 5, 5, 6);
    auto mi = IMargins(4, 15, 2, 5);

    static assert(__traits(compiles, md = cast(FMargins) mi));
    static assert(__traits(compiles, mi = cast(IMargins) md));
}

/// Compile time checks that T is margins
template isMargins(T)
{
    import std.traits : TemplateOf;
    enum isMargins = __traits(isSame, TemplateOf!T, Margins);
}

static assert(  isMargins!FMargins);
static assert(  isMargins!IMargins);
static assert(! isMargins!FPadding);

/// Represents a rectangular area, defined by a position and a size
struct Rect(T) if (isNumeric!T)
{
    private
    {
        T _x=0;
        T _y=0;
        T _w=0;
        T _h=0;
    }

    alias Scalar = T;

    invariant()
    {
        //assert(_w >= 0 && _h >= 0);
    }

    this(in T x, in T y, in T w, in T h)
    {
        _x = x; _y = y; _w = w; _h = h;
    }

    this(in T x, in T y, in Size!T s)
    {
        _x = x; _y = y; _w = s.width; _h = s.height;
    }

    this(in Point!T p, in T w, in T h)
    {
        _x = p.x; _y = p.y; _w = w; _h = h;
    }

    this(Point!T p, Size!T s)
    {
        _x = p.x;
        _y = p.y;
        _w = s.width;
        _h = s.height;
    }

    this(Point!T topLeft, Point!T bottomRight)
    {
        _x = topLeft.x;
        _y = topLeft.y;
        _w = cast(T)(bottomRight.x - topLeft.x);
        _h = cast(T)(bottomRight.y - topLeft.y);
    }

    @property T x() const
    {
        return _x;
    }

    @property void x(T val)
    {
        _x = val;
    }

    @property T y() const
    {
        return _y;
    }

    @property void y(T val)
    {
        _y = val;
    }

    @property T width() const
    {
        return _w;
    }

    @property void width(T val)
    {
        _w = cast(T)max(0, val);
    }

    @property T height() const
    {
        return _h;
    }

    @property void height(T val)
    {
        _h = cast(T)max(0, val);
    }

    @property Point!T point() const
    {
        return Point!T(_x, _y);
    }

    @property void point(Point!T p)
    {
        _x = p.x;
        _y = p.y;
    }

    @property Size!T size() const
    {
        return Size!T(width, height);
    }

    @property void size(Size!T s)
    {
        width = s.width;
        height = s.height;
    }

    @property T left() const
    {
        return _x;
    }

    @property void left(T val)
    {
        _w = cast(T)max(0, _w - (val - _x));
        _x = val;
    }

    @property T top() const
    {
        return _y;
    }

    @property void top(T val)
    {
        _h = cast(T)max(0, _h - (val - _y));
        _y = val;
    }

    @property T right() const
    {
        return cast(T)(_x + _w);
    }

    @property void right(T val)
    in {
        assert(val >= _x);
    }
    body {
        _w = cast(T)(val - _x);
    }

    @property T bottom() const
    {
        return cast(T)(_y + _h);
    }

    @property void bottom(T val)
    in {
        assert(val >= _y);
    }
    body {
        _h = cast(T)(val - _y);
    }

    @property Point!T topLeft() const
    {
        return Point!T(left, top);
    }

    @property void topLeft(Point!T p)
    {
        left = p.x;
        top = p.y;
    }

    @property Point!T topRight() const
    {
        return Point!T(right, top);
    }

    @property void topRight(Point!T p)
    {
        right = p.x;
        top = p.y;
    }

    @property Point!T bottomLeft() const
    {
        return Point!T(left, bottom);
    }

    @property void bottomLeft(Point!T p)
    {
        left = p.x;
        bottom = p.y;
    }

    @property Point!T bottomRight() const
    {
        return Point!T(right, bottom);
    }

    @property void bottomRight(Point!T p)
    {
        right = p.x;
        bottom = p.y;
    }

    ref Rect!T opOpAssign(string op)(FMargins rhs) if (op == "+")
    {
        left -= rhs.left;
        top -= rhs.top;
        right += rhs.right;
        bottom += rhs.bottom;
        return this;
    }

    ref Rect!T opOpAssign(string op)(FMargins rhs) if (op == "-")
    {
        left += rhs.left;
        top += rhs.top;
        right -= rhs.right;
        bottom -= rhs.bottom;
        return this;
    }

    ref Rect!T opOpAssign(string op : "+")(Point!T rhs)
    {
        point = point + rhs;
        return this;
    }

    ref Rect!T opOpAssign(string op : "-")(Point!T rhs)
    {
        point = point - rhs;
        return this;
    }

    Rect!T opBinary(string op)(Margins!T rhs) if (op == "+" || op == "-")
    {
        Rect!T ret = this;
        mixin("ret " ~ op ~ "= rhs;");
        return ret;
    }

    Rect!T opBinary(string op)(Point!T rhs) if (op == "+" || op == "-")
    {
        Rect!T ret = this;
        mixin("ret " ~ op ~ "= rhs;");
        return ret;
    }

    U opCast(U : Rect!V, V)() const
    {
        return Rect!V(cast(V) x, cast(V) y, cast(V) width, cast(V) height);
    }
}

/// Compile time checks that T is a rect
template isRect(T)
{
    import std.traits : TemplateOf;
    enum isRect = __traits(isSame, TemplateOf!T, Rect);
}

static assert(  isRect!FRect);
static assert(  isRect!IRect);
static assert(! isRect!FPadding);

/// Build a rect from point and size components
auto rect(X, Y, W, H)(in X x, in Y y, in W w, in H h)
if (isNumeric!X && isNumeric!Y && isNumeric!W && isNumeric!H)
{
    import std.traits : CommonType;
    alias T = CommonType!(X, Y, W, H);
    return Rect!T(x, y, w, h);
}

/// Build a rect from point and size components
auto rect(P, W, H)(in P p, in W w, in H h)
if (isPoint!P && isNumeric!W && isNumeric!H)
{
    import std.traits : CommonType;
    alias T = CommonType!(P.Scalar, W, H);
    return Rect!T(p, w, h);
}

/// Build a rect from point and size components
auto rect(X, Y, S)(in X x, in Y y, in S s)
if (isNumeric!X && isNumeric!Y && isSize!S)
{
    import std.traits : CommonType;
    alias T = CommonType!(X, Y, S.Scalar);
    return Rect!T(x, y, s);
}

/// Build a rect from point and size components
auto rect(P, S)(in P p, in S s)
if (isPoint!P && isSize!S)
{
    import std.traits : CommonType;
    alias T = CommonType!(P.Scalar, S.Scalar);
    return Rect!T(p, s);
}

/// Checks whether big contains small
bool contains(S1, S2)(in S1 big, in S2 small)
if (isSize!S1 && isSize!S2)
{
    return big.width >= small.width && big.height >= small.height;
}

/// Checks whether r contains p
bool contains(R, P)(in R r, in P p)
if (isRect!R && isPoint!P)
{
    return p.x >= r.left && p.x <= r.right && p.y >= r.top && p.y <= r.bottom;
}

/// Checks whether rl contains rr
bool contains(R1, R2)(in R1 r1, in R2 r2)
if (isRect!R1 && isRect!R2)
{
    // is r2 fully within r1?
    return r2.left >= r1.left && r2.right <= r1.right && r2.top >= r1.top && r2.bottom <= r1.bottom;
}

/// Checks whether rl overlaps with rr
bool overlaps(R1, R2)(in R1 r1, in R2 r2)
if (isRect!R1 && isRect!R2)
{
    return r1.right >= r2.left && r1.left <= r2.right && r1.bottom >= r2.top && r1.top <= r2.bottom;
}

/// Computes the intersection of r1 with r2
auto intersection(R1, R2)(in R1 r1, in R2 r2)
if (isRect!R1 && isRect!R2)
{
    import std.traits : CommonType;
    Rect!(CommonType!(R1.Scalar, R2.Scalar)) r;
    r.left = max(r1.left, r2.left);
    r.right = max(min(r1.right, r2.right), r.left);
    r.top = max(r1.top, r2.top);
    r.bottom = max(min(r1.bottom, r2.bottom), r.top);
    return r;
}

/// Compute the extents of r1 and r2
auto extents(R1, R2)(in R1 r1, in R2 r2)
if (isRect!R1 && isRect!R2)
{
    import std.traits : CommonType;
    Rect!(CommonType!(R1.Scalar, R2.Scalar)) r;
    r.left = min(r1.left, r2.left);
    r.right = max(r1.right, r2.right);
    r.top = min(r1.top, r2.top);
    r.bottom = max(r1.bottom, r2.bottom);
    return r;
}

/// Extend a rect with the given point
void extend(R, P)(ref R r, in P p)
if (isRect!R && isPoint!P)
{
    if (r.left > p.x) r.left = p.x;
    else if (r.right < p.x) r.right = p.x;
    if (r.top > p.y) r.top = p.y;
    else if (r.bottom < p.y) r.bottom = p.y;
}

/// The area of size s
@property T area(T)(in Size!T s)
{
    return s.width * s.height;
}

/// The area of rect r
@property T area(T)(in Rect!T r)
{
    return r.size.area;
}

unittest
{
    auto rd = FRect(3, 5, 5, 6);
    auto ri = IRect(4, 15, 2, 5);

    static assert(__traits(compiles, rd = cast(FRect) ri));
    static assert(__traits(compiles, ri = cast(IRect) rd));

    ri.left = 2;
    assert(ri == IRect(2, 15, 4, 5));

    ri.topLeft = ri.topLeft + IPoint(3, 2);
    assert(ri == IRect(5, 17, 1, 3));

    ri -= IPoint(5, 10);
    assert(ri == IRect(0, 7, 1, 3));

    ri.bottomRight = ri.bottomRight + IPoint(5, 3);
    assert(ri == IRect(0, 7, 6, 6));

    assert(ri.overlaps(IRect(5, 5, 3, 3)));
    assert(!ri.overlaps(IRect(5, 14, 3, 3)));
    assert(!ri.overlaps(IRect(7, 5, 3, 3)));
    assert(ri.intersection(IRect(5, 5, 3, 3)) == IRect(5, 7, 1, 1));
}


/// Compute the extents of an input range of rects.
auto computeRectsExtents(R)(R rects)
if (isInputRange!R)
{
    alias RectT = ElementType!R;
    if (rects.empty) return RectT.init;
    RectT r = rects.front;
    while (!rects.empty) {
        r = extents(r, rects.front);
        rects.popFront();
    }
    return r;
}


/// Compute screen-aligned bounds of a rect transformation
FRect transformBounds(in FRect bounds, FMat4 mat)
{
    return transformBoundsPriv!float(bounds, mat);
}

private Rect!T transformBoundsPriv(T)(in Rect!T bounds, in Mat4!T mat)
{
    immutable tl = (mat * vec(bounds.topLeft, 0, 1)).xy;
    immutable tr = (mat * vec(bounds.topRight, 0, 1)).xy;
    immutable bl = (mat * vec(bounds.bottomLeft, 0, 1)).xy;
    immutable br = (mat * vec(bounds.bottomRight, 0, 1)).xy;

    immutable minX = min(tl.x, tr.x, bl.x, br.x);
    immutable maxX = max(tl.x, tr.x, bl.x, br.x);
    immutable minY = min(tl.y, tr.y, bl.y, br.y);
    immutable maxY = max(tl.y, tr.y, bl.y, br.y);

    return Rect!T(minX, minY, maxX-minX, maxY-minY);
}
