/// Geometric primitives module
module dgt.core.geometry;

import gfx.math.mat : isMat;
import gfx.math.transform : transform;
public import gfx.math.vec;

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

    Vec2!T asVec() const {
        return Vec2!T(width, height);
    }

    ref Size!T opOpAssign(string op)(in Margins!T rhs) if (op == "+" || op == "-")
    {
        mixin("width "~op~"= rhs.horizontal;");
        mixin("height "~op~"= rhs.vertical;");
        return this;
    }

    Size!T opBinary(string op)(in Margins!T rhs) const if (op == "+" || op == "-")
    {
        Size!T ret = this;
        mixin("ret " ~ op ~ "= rhs;");
        return ret;
    }

    ref Size!T opOpAssign(string op)(in Padding!T rhs) if (op == "+" || op == "-")
    {
        mixin("width "~op~"= rhs.horizontal;");
        mixin("height "~op~"= rhs.vertical;");
        return this;
    }

    Size!T opBinary(string op)(in Padding!T rhs) const if (op == "+" || op == "-")
    {
        Size!T ret = this;
        mixin("ret " ~ op ~ "= rhs;");
        return ret;
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

    assert(FMargins.init.left == 0f);
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

/// A rectangular area, represented by its top-left position and its size
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
        assert(bottomRight.x >= topLeft.x);
        assert(bottomRight.y >= topLeft.y);
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
        import std.algorithm : max;

        _w = cast(T)max(0, val);
    }

    @property T height() const
    {
        return _h;
    }

    @property void height(T val)
    {
        import std.algorithm : max;

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
        _w = s.width;
        _h = s.height;
    }

    @property T left() const
    {
        return _x;
    }

    // Set the left coordinate without changing the width. (moves the right coordinate)
    @property void left(T val)
    {
        _x = val;
    }

    @property T top() const
    {
        return _y;
    }

    // Set the left coordinate without changing the height. (moves the bottom coordinate)
    @property void top(T val)
    {
        _y = val;
    }

    @property T right() const
    {
        return cast(T)(_x + _w);
    }

    // Set the right coordinate by adjusting the width.
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

    @property Point!T topLeft() const
    {
        return Point!T(left, top);
    }

    @property void topLeft(Point!T p)
    {
        _x = p.x;
        _y = p.y;
    }

    @property Point!T topRight() const
    {
        return Point!T(right, top);
    }

    @property Point!T bottomLeft() const
    {
        return Point!T(left, bottom);
    }

    @property Point!T bottomRight() const
    {
        return Point!T(right, bottom);
    }

    @property Point!T center() const
    {
        return Point!T(centerX, centerY);
    }

    @property T centerX() const
    {
        return cast(T)(_x + _w/2);
    }

    @property T centerY() const
    {
        return cast(T)(_y + _h/2);
    }

    ref Rect!T opOpAssign(string op)(in Margins!T rhs) if (op == "+")
    {
        _x -= rhs.left;
        _y -= rhs.top;
        _w += rhs.horizontal;
        _h += rhs.vertical;
        return this;
    }

    ref Rect!T opOpAssign(string op)(in Margins!T rhs) if (op == "-")
    {
        _x += rhs.left;
        _y += rhs.top;
        _w -= rhs.horizontal;
        _h -= rhs.vertical;
        return this;
    }

    ref Rect!T opOpAssign(string op)(in Padding!T rhs) if (op == "+")
    {
        _x -= rhs.left;
        _y -= rhs.top;
        _w += rhs.horizontal;
        _h += rhs.vertical;
        return this;
    }

    ref Rect!T opOpAssign(string op)(in Padding!T rhs) if (op == "-")
    {
        _x += rhs.left;
        _y += rhs.top;
        _w -= rhs.horizontal;
        _h -= rhs.vertical;
        return this;
    }

    ref Rect!T opOpAssign(string op : "+")(in Point!T rhs)
    {
        point = point + rhs;
        return this;
    }

    ref Rect!T opOpAssign(string op : "-")(in Point!T rhs)
    {
        point = point - rhs;
        return this;
    }

    Rect!T opBinary(string op)(in Margins!T rhs) const if (op == "+" || op == "-")
    {
        Rect!T ret = this;
        mixin("ret " ~ op ~ "= rhs;");
        return ret;
    }

    Rect!T opBinary(string op)(in Padding!T rhs) const if (op == "+" || op == "-")
    {
        Rect!T ret = this;
        mixin("ret " ~ op ~ "= rhs;");
        return ret;
    }

    Rect!T opBinary(string op)(in Point!T rhs) const if (op == "+" || op == "-")
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

/// Round FRect components into a IRect such as each corner is rounded to the
/// closest integer coordinate
IRect roundRect(in FRect rect)
{
    import std.math : round;

    const l = cast(int)round(rect.left);
    const t = cast(int)round(rect.top);
    const r = cast(int)round(rect.right);
    const b = cast(int)round(rect.bottom);
    return IRect(l, t, r-l, b-t);
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
    return r1.right > r2.left && r1.left < r2.right && r1.bottom > r2.top && r1.top < r2.bottom;
}

/// Computes the intersection of r1 with r2
auto intersection(R1, R2)(in R1 r1, in R2 r2)
if (isRect!R1 && isRect!R2)
in (overlaps(r1, r2))
{
    import std.algorithm : max, min;
    import std.traits : CommonType;

    Rect!(CommonType!(R1.Scalar, R2.Scalar)) r = void;
    r._x = max(r1.left, r2.left);
    r._w = min(r1.right, r2.right) - r._x;
    r._y = max(r1.top, r2.top);
    r._h = min(r1.bottom, r2.bottom) - r._y;
    return r;
}

/// Compute the extents of r1 and r2
auto extents(R1, R2)(in R1 r1, in R2 r2)
if (isRect!R1 && isRect!R2)
{
    import std.algorithm : max, min;
    import std.traits : CommonType;

    Rect!(CommonType!(R1.Scalar, R2.Scalar)) r = void;
    r._x = min(r1.left, r2.left);
    r._w = max(r1.right, r2.right) - r._x;
    r._y = min(r1.top, r2.top);
    r._h = max(r1.bottom, r2.bottom) - r._y;
    return r;
}

/// Extend rect.left to x if x is on the left of rect.left.
/// Does not affect the right side of rect.
void extendLeft(R, T)(ref R rect, in T x)
if (isRect!R && is(T : R.Scalar))
{
    if (rect._x > x) rect._x = x;
}

/// Extend rect.top to y if y is higher than rect.top.
/// Does not affect the bottom side of rect.
void extendTop(R, T)(ref R rect, in T y)
if (isRect!R && is(T : R.Scalar))
{
    if (rect._y > y) rect._y = y;
}

/// Extend rect.right to x if x is on the right of rect.right.
/// Does not affect the left side of rect.
void extendRight(R, T)(ref R rect, in T x)
if (isRect!R && is(T : R.Scalar))
{
    const r = rect.right;
    if (r < x) {
        rect._w += x - r;
    }
}

/// Extend rect.bottom to y if y is lower than rect.bottom.
/// Does not affect the top side of rect.
void extendBottom(R, T)(ref R rect, in T y)
if (isRect!R && is(T : R.Scalar))
{
    const b = rect.bottom;
    if (b < y) {
        rect._h += y - b;
    }
}

/// call extendLeft and extendTop with v coordinates
void extendTopLeft(R, P)(ref R rect, in P p)
if (isRect!R && isPoint!P && is(P.Component : R.Scalar))
{
    extendLeft(rect, p.x);
    extendTop(rect, p.y);
}

/// call extendRight and extendTop with v coordinates
void extendTopRight(R, P)(ref R rect, in P p)
if (isRect!R && isPoint!P && is(P.Component : R.Scalar))
{
    extendRight(rect, p.x);
    extendTop(rect, p.y);
}

/// call extendRight and extendBottom with v coordinates
void extendBottomRight(R, P)(ref R rect, in P p)
if (isRect!R && isPoint!P && is(P.Component : R.Scalar))
{
    extendRight(rect, p.x);
    extendBottom(rect, p.y);
}

/// call extendLeft and extendBottom with v coordinates
void extendBottomLeft(R, P)(ref R rect, in P p)
if (isRect!R && isPoint!P && is(P.Component : R.Scalar))
{
    extendLeft(rect, p.x);
    extendBottom(rect, p.y);
}

/// Extend a rect to englobe the given point
void extend(R, P)(ref R r, in P p)
if (isRect!R && isPoint!P)
{
    extendLeft(r, p.x);
    extendTop(r, p.y);
    extendRight(r, p.x);
    extendBottom(r, p.y);
}

/// Extend a rect to englobe the given rect
void extend(R)(ref R rect, in R r)
if (isRect!R)
{
    extendTopLeft(rect, r.topLeft);
    extendBottomRight(rect, r.bottomRight);
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
    // auto rd = FRect(3, 5, 5, 6);
    // auto ri = IRect(4, 15, 2, 5);

    // static assert(__traits(compiles, rd = cast(FRect) ri));
    // static assert(__traits(compiles, ri = cast(IRect) rd));

    // ri.left = 2;
    // assert(ri == IRect(2, 15, 4, 5));

    // ri.topLeft = ri.topLeft + IPoint(3, 2);
    // assert(ri == IRect(5, 17, 1, 3));

    // ri -= IPoint(5, 10);
    // assert(ri == IRect(0, 7, 1, 3));

    // ri.size = ri.size + IMargins(0, 0, 5, 3);
    // assert(ri == IRect(0, 7, 6, 6));

    // assert(ri.overlaps(IRect(5, 5, 3, 3)));
    // assert(!ri.overlaps(IRect(5, 14, 3, 3)));
    // assert(!ri.overlaps(IRect(7, 5, 3, 3)));
    // assert(ri.intersection(IRect(5, 5, 3, 3)) == IRect(5, 7, 1, 1));
}


/// Compute the extents of an input range of rects.
/// Returns the rect init value if the range is empty
auto computeRectsExtents(R)(R rects)
if (isInputRange!R && isRect!(ElementType!R))
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
R transformBounds(R, M)(in R bounds, in M mat)
if (isRect!R && isMat!M &&  (is(typeof(transform(bounds.topLeft, mat))) ||
                             is(typeof(transform(fvec(bounds.topLeft, 0), mat)))) &&
    is(R.Scalar == M.Component))
{
    import std.algorithm : max, min;

    static if (is(typeof(transform(bounds.topLeft, mat)))) {
        const tl = transform(bounds.topLeft, mat).xy;
        const tr = transform(bounds.topRight, mat).xy;
        const bl = transform(bounds.bottomLeft, mat).xy;
        const br = transform(bounds.bottomRight, mat).xy;
    }
    else {
        const tl = transform(fvec(bounds.topLeft, 0), mat).xy;
        const tr = transform(fvec(bounds.topRight, 0), mat).xy;
        const bl = transform(fvec(bounds.bottomLeft, 0), mat).xy;
        const br = transform(fvec(bounds.bottomRight, 0), mat).xy;
    }

    const minX = min(tl.x, tr.x, bl.x, br.x);
    const maxX = max(tl.x, tr.x, bl.x, br.x);
    const minY = min(tl.y, tr.y, bl.y, br.y);
    const maxY = max(tl.y, tr.y, bl.y, br.y);

    return R(minX, minY, maxX-minX, maxY-minY);
}
