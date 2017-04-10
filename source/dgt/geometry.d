module dgt.geometry;

import dgt.math.vec;

import std.traits : isNumeric;
import std.algorithm : min, max;

alias TPoint(T) = Vec2!T;
alias Point = TPoint!float;
alias IPoint = TPoint!int;

alias Size = TSize!float;
alias ISize = TSize!int;

alias Margins = TMargins!float;
alias IMargins = TMargins!int;

alias Rect = TRect!float;
alias IRect = TRect!int;

/// Represents a two dimensional size
struct TSize(T) if (isNumeric!T)
{
    T width;
    T height;

    U opCast(U : TSize!V, V)() const
    {
        return TSize!V(cast(V) width, cast(V) height);
    }

    static if (is(T == int))
    {
        @property Size toDouble() const
        {
            return Size(width, height);
        }

        alias toDouble this;
    }
}

unittest
{
    auto sd = Size(3, 5);
    assert(sd.area == 15);

    auto si = ISize(4, 15);
    assert(si.area == 60);

    static assert(__traits(compiles, sd = si));
    static assert(!__traits(compiles, si = sd));
    static assert(__traits(compiles, si = cast(ISize) sd));
}

/// Represents margins around a rectangular area
struct TMargins(T) if (isNumeric!T)
{
    T left;
    T top;
    T right;
    T bottom;

    U opCast(U : TMargins!V, V)() const
    {
        return TMargins!V(cast(V) left, cast(V) top, cast(V) right, cast(V) bottom);
    }

    static if (is(T == int))
    {
        @property Margins toDouble() const
        {
            return Margins(left, top, right, bottom);
        }

        alias toDouble this;
    }
}

unittest
{
    auto md = Margins(3, 5, 5, 6);
    auto mi = IMargins(4, 15, 2, 5);

    static assert(__traits(compiles, md = mi));
    static assert(!__traits(compiles, mi = md));
    static assert(__traits(compiles, mi = cast(IMargins) md));
}

/// Represents a rectangular area
struct TRect(T) if (isNumeric!T)
{
    private
    {
        T _x;
        T _y;
        T _w;
        T _h;
    }

    invariant()
    {
        assert(_w >= 0 && _h >= 0);
    }

    this(in T x, in T y, in T w, in T h)
    {
        _x = x; _y = y; _w = w; _h = h;
    }

    this(in T x, in T y, in TSize!T s)
    {
        _x = x; _y = y; _w = s.width; _h = s.height;
    }

    this(in TPoint!T p, in T w, in T h)
    {
        _x = p.x; _y = p.y; _w = w; _h = h;
    }

    this(TPoint!T p, TSize!T s)
    {
        _x = p.x;
        _y = p.y;
        _w = s.width;
        _h = s.height;
    }

    this(TPoint!T topLeft, TPoint!T bottomRight)
    {
        _x = topLeft.x;
        _y = topLeft.y;
        _w = bottomRight.x - topLeft.x;
        _h = bottomRight.y - topLeft.y;
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
        _w = max(0, val);
    }

    @property T height() const
    {
        return _h;
    }

    @property void height(T val)
    {
        _h = max(0, val);
    }

    @property TPoint!T point() const
    {
        return TPoint!T(_x, _y);
    }

    @property void point(TPoint!T p)
    {
        _x = p.x;
        _y = p.y;
    }

    @property TSize!T size() const
    {
        return TSize!T(width, height);
    }

    @property void size(TSize!T s)
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
        _w = max(0, _w - (val - _x));
        _x = val;
    }

    @property T top() const
    {
        return _y;
    }

    @property void top(T val)
    {
        _h = max(0, _h - (val - _y));
        _y = val;
    }

    @property T right() const
    {
        return _x + _w;
    }

    @property void right(T val)
    in {
        assert(val >= _x);
    }
    body {
        _w = val - _x;
    }

    @property T bottom() const
    {
        return _y + _h;
    }

    @property void bottom(T val)
    in {
        assert(val >= _y);
    }
    body {
        _h = val - _y;
    }

    @property TPoint!T topLeft() const
    {
        return TPoint!T(left, top);
    }

    @property void topLeft(TPoint!T p)
    {
        left = p.x;
        top = p.y;
    }

    @property TPoint!T topRight() const
    {
        return TPoint!T(right, top);
    }

    @property void topRight(TPoint!T p)
    {
        right = p.x;
        top = p.y;
    }

    @property TPoint!T bottomLeft() const
    {
        return TPoint!T(left, bottom);
    }

    @property void bottomLeft(TPoint!T p)
    {
        left = p.x;
        bottom = p.y;
    }

    @property TPoint!T bottomRight() const
    {
        return TPoint!T(right, bottom);
    }

    @property void bottomRight(TPoint!T p)
    {
        right = p.x;
        bottom = p.y;
    }

    ref TRect!T opOpAssign(string op)(Margins rhs) if (op == "+")
    {
        left -= rhs.left;
        top -= rhs.top;
        right += rhs.right;
        bottom += rhs.bottom;
        return this;
    }

    ref TRect!T opOpAssign(string op)(Margins rhs) if (op == "-")
    {
        left += rhs.left;
        top += rhs.top;
        right -= rhs.right;
        bottom -= rhs.bottom;
        return this;
    }

    ref TRect!T opOpAssign(string op : "+")(TPoint!T rhs)
    {
        point = point + rhs;
        return this;
    }

    ref TRect!T opOpAssign(string op : "-")(TPoint!T rhs)
    {
        point = point - rhs;
        return this;
    }

    TRect!T opBinary(string op)(TMargins!T rhs) if (op == "+" || op == "-")
    {
        TRect!T ret = this;
        mixin("ret " ~ op ~ "= rhs;");
        return ret;
    }

    TRect!T opBinary(string op)(TPoint!T rhs) if (op == "+" || op == "-")
    {
        TRect!T ret = this;
        mixin("ret " ~ op ~ "= rhs;");
        return ret;
    }

    U opCast(U : TRect!V, V)() const
    {
        return TRect!V(cast(V) x, cast(V) y, cast(V) width, cast(V) height);
    }

    static if (is(T == int))
    {
        @property Rect toDouble() const
        {
            return Rect(x, y, width, height);
        }

        alias toDouble this;
    }

}

bool contains(T)(in TSize!T big, in TSize!T small)
{
    return big.width >= small.width && big.height >= small.height;
}

bool contains(T)(in TRect!T r, in TPoint!T p)
{
    return p.x >= r.left && p.x <= r.right && p.y >= r.top && p.y <= r.bottom;
}

bool contains(T)(in TRect!T rl, in TRect!T rr)
{
    // is rr fully within rl?
    return rr.left >= rl.left && rr.right <= rl.right && rr.top >= rl.top && rr.bottom <= rl.bottom;
}

bool overlaps(T)(in TRect!T rl, in TRect!T rr)
{
    return rl.right >= rr.left && rl.left <= rr.right && rl.bottom >= rr.top && rl.top <= rr.bottom;
}

TRect!T intersection(T)(in TRect!T r1, in TRect!T r2)
{
    TRect!T r;
    r.left = max(r1.left, r2.left);
    r.right = max(min(r1.right, r2.right), r.left);
    r.top = max(r1.top, r2.top);
    r.bottom = max(min(r1.bottom, r2.bottom), r.top);
    return r;
}

@property T area(T)(in TSize!T s)
{
    return s.width * s.height;
}

@property T area(T)(in TRect!T r)
{
    return r.size.area;
}

unittest
{

    auto rd = Rect(3, 5, 5, 6);
    auto ri = IRect(4, 15, 2, 5);

    static assert(__traits(compiles, rd = ri));
    static assert(!__traits(compiles, ri = rd));
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
