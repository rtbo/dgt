module dgt.geometry;

import dgt.math;

import std.traits : isNumeric;
import std.algorithm : min, max;
import std.range;

alias Point(T) = Vec2!T;
alias FPoint = Point!float;
alias IPoint = Point!int;

alias FSize = Size!float;
alias ISize = Size!int;

alias FMargins = Margins!float;
alias IMargins = Margins!int;

alias FRect = Rect!float;
alias IRect = Rect!int;

/// Represents a two dimensional size
struct Size(T) if (isNumeric!T)
{
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

/// Represents margins around a rectangular area
struct Margins(T) if (isNumeric!T)
{
    T left =0;
    T top =0;
    T right =0;
    T bottom =0;

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

/// Represents a rectangular area
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

bool contains(T)(in Size!T big, in Size!T small)
{
    return big.width >= small.width && big.height >= small.height;
}

bool contains(T)(in Rect!T r, in Point!T p)
{
    return p.x >= r.left && p.x <= r.right && p.y >= r.top && p.y <= r.bottom;
}

bool contains(T)(in Rect!T rl, in Rect!T rr)
{
    // is rr fully within rl?
    return rr.left >= rl.left && rr.right <= rl.right && rr.top >= rl.top && rr.bottom <= rl.bottom;
}

bool overlaps(T)(in Rect!T rl, in Rect!T rr)
{
    return rl.right >= rr.left && rl.left <= rr.right && rl.bottom >= rr.top && rl.top <= rr.bottom;
}

Rect!T intersection(T)(in Rect!T r1, in Rect!T r2)
{
    Rect!T r;
    r.left = max(r1.left, r2.left);
    r.right = max(min(r1.right, r2.right), r.left);
    r.top = max(r1.top, r2.top);
    r.bottom = max(min(r1.bottom, r2.bottom), r.top);
    return r;
}

Rect!T extents(T)(in Rect!T r1, in Rect!T r2)
{
    Rect!T r;
    r.left = min(r1.left, r2.left);
    r.right = max(r1.right, r2.right);
    r.top = min(r1.top, r2.top);
    r.bottom = max(r1.bottom, r2.bottom);
    return r;
}

@property T area(T)(in Size!T s)
{
    return s.width * s.height;
}

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
