module dgt.geometry;

import dgt.math.vec;

import std.traits : isNumeric;
import std.algorithm : min, max;

alias TPoint(T) = TVec2!T;
alias Point = TPoint!double;
alias IPoint = TPoint!int;

alias Size = TSize!double;
alias ISize = TSize!int;

alias Margins = TMargins!double;
alias IMargins = TMargins!int;

alias Rect = TRect!double;
alias IRect = TRect!int;



/// Represents a two dimensional size
struct TSize(T) if (isNumeric!T)
{
    T width;
    T height;

    U opCast(U : TSize!V, V)() const
    {
        return TSize!V(cast(V)width, cast(V)height);
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

    static assert(   __traits(compiles, sd = si));
    static assert( ! __traits(compiles, si = sd));
    static assert(   __traits(compiles, si = cast(ISize)sd));
}

/// Represents margins around a rectangular area
struct TMargins(T) if (isNumeric!T)
{
    T left;
    T top;
    T right;
    T bottom;

    U opCast(U : TMargins!V, V)() const {
        return TMargins!V(cast(V)left, cast(V)top, cast(V)right, cast(V)bottom);
    }

    static if (is(T == int)) {
        @property Margins toDouble() const {
            return Margins(left, top, right, bottom);
        }
        alias toDouble this;
    }
}


unittest {

    auto md = Margins(3, 5, 5, 6);
    auto mi = IMargins(4, 15, 2, 5);

    static assert(   __traits(compiles, md = mi));
    static assert( ! __traits(compiles, mi = md));
    static assert(   __traits(compiles, mi = cast(IMargins)md));

}

/// Represents a rectangular area
struct TRect(T) if (isNumeric!T)
{
    private {
        T x_;
        T y_;
        T w_;
        T h_;
    }

    invariant() {
        assert(w_>=0 && h_>=0);
    }

    this (TPoint!T p, TSize!T s)
    {
        x_ = p.x;
        y_ = p.y;
        w_ = s.width;
        h_ = s.height;
    }

    this (T x, T y, T w, T h)
    {
        x_ = x;
        y_ = y;
        w_ = w;
        h_ = h;
    }

    this (TPoint!T p, T w, T h)
    {
        x_ = p.x;
        y_ = p.y;
        w_ = w;
        h_ = h;
    }

    this (T x, T y, TSize!T s)
    {
        x_ = x;
        y_ = y;
        w_ = s.width;
        h_ = s.height;
    }


    @property T x() const { return x_; }
    @property void x(T val) { x_ = val; }

    @property T y() const { return y_; }
    @property void y(T val) { y_ = val; }

    @property T width() const { return w_; }
    @property void width(T val) { w_ = max(0, val); }

    @property T height() const { return h_; }
    @property void height(T val) { h_ = max(0, val); }


    @property TPoint!T point() const { return TPoint!T(x_, y_); }
    @property void point(TPoint!T p) { x_ = p.x; y_ = p.y; }

    @property TSize!T size() const { return TSize!T(width, height); }
    @property void size(TSize!T s) { width = s.width; height = s.height; }


    @property T left() const { return x_; }
    @property void left(T val) {
        w_ = max(0, w_-(val-x_));
        x_ = val;
    }

    @property T top() const { return y_; }
    @property void top(T val) {
        h_ = max(0, h_-(val-y_));
        y_ = val;
    }

    @property T right() const { return x_ + w_; }
    @property void right(T val) {
        w_ = max(0, val-x_);
    }

    @property T bottom() const { return y_ + h_; }
    @property void bottom(T val) {
        h_ = max(0, val-y_);
    }


    @property TPoint!T topLeft() const { return TPoint!T(left, top); }
    @property void topLeft(TPoint!T p) { left = p.x; top = p.y; }

    @property TPoint!T topRight() const { return TPoint!T(right, top); }
    @property void topRight(TPoint!T p) { right = p.x; top = p.y; }

    @property TPoint!T bottomLeft() const { return TPoint!T(left, bottom); }
    @property void bottomLeft(TPoint!T p) { left = p.x; bottom = p.y; }

    @property TPoint!T bottomRight() const { return TPoint!T(right, bottom); }
    @property void bottomRight(TPoint!T p) { right = p.x; bottom = p.y; }



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
        mixin("ret "~op~"= rhs;");
        return ret;
    }


    TRect!T opBinary(string op)(TPoint!T rhs) if (op == "+" || op == "-")
    {
        TRect!T ret = this;
        mixin("ret "~op~"= rhs;");
        return ret;
    }


    U opCast(U : TRect!V, V)() const {
        return TRect!V(cast(V)x, cast(V)y, cast(V)width, cast(V)height);
    }

    static if (is(T == int)) {
        @property Rect toDouble() const {
            return Rect(x, y, width, height);
        }
        alias toDouble this;
    }

}



bool contains(T)(in TRect!T r, in TPoint!T p)
{
    return p.x >= r.left &&
        p.x <= r.right &&
        p.y >= r.top &&
        p.y <= r.bottom;
}

bool contains(T)(in TRect!T rl, in TRect!T rr)
{
    // is rr fully within rl?
    return rr.left >= rl.left &&
        rr.right <= rl.right &&
        rr.top >= rl.top &&
        rr.bottom <= rl.bottom;
}


bool overlaps(T)(in TRect!T rl, in TRect!T rr)
{
    return rl.right >= rr.left &&
        rl.left <= rr.right &&
        rl.bottom >= rr.top &&
        rl.top <= rr.bottom;
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


unittest {

    auto rd = Rect(3, 5, 5, 6);
    auto ri = IRect(4, 15, 2, 5);

    static assert(   __traits(compiles, rd = ri));
    static assert( ! __traits(compiles, ri = rd));
    static assert(   __traits(compiles, ri = cast(IRect)rd));


    ri.left = 2;
    assert (ri == IRect(2, 15, 4, 5));

    ri.topLeft = ri.topLeft + IPoint(3, 2);
    assert (ri == IRect(5, 17, 1, 3));

    ri -= IPoint(5, 10);
    assert(ri == IRect(0, 7, 1, 3));

    ri.bottomRight = ri.bottomRight + IPoint(5, 3);
    assert(ri == IRect(0, 7, 6, 6));


    assert(ri.overlaps(IRect(5, 5, 3, 3)));
    assert(!ri.overlaps(IRect(5, 14, 3, 3)));
    assert(!ri.overlaps(IRect(7, 5, 3, 3)));
    assert(ri.intersection(IRect(5, 5, 3, 3)) == IRect(5, 7, 1, 1));
}
