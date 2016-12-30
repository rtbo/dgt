module dgt.math.vec;

import dgt.core.typecons : StaticRange;

import std.traits;

alias TVec2(T) = Vec!(T, 2);
alias TVec3(T) = Vec!(T, 3);
alias TVec4(T) = Vec!(T, 4);

alias DVecN(int N) = Vec!(double, N);
alias FVecN(int N) = Vec!(float, N);
alias IVecN(int N) = Vec!(int, N);

alias DVec2 = Vec!(double, 2);
alias DVec3 = Vec!(double, 3);
alias DVec4 = Vec!(double, 4);

alias FVec2 = Vec!(float, 2);
alias FVec3 = Vec!(float, 3);
alias FVec4 = Vec!(float, 4);

alias IVec2 = Vec!(int, 2);
alias IVec3 = Vec!(int, 3);
alias IVec4 = Vec!(int, 4);

struct Vec(T, size_t N) if (N > 0 && isNumeric!T)
{
    private T[N] _rep = 0;

    /// The length of the vector.
    enum length = N;
    /// The vector components type.
    alias Component = T;

    /// Build a vector from its components
    this(Comps...)(in Comps comps)
    if (Comps.length == length)
    {
        foreach(C; Comps)
        {
            static assert(is(C : T), "Component must convert to "~T.stringof);
        }
        _rep = [ comps ];
    }

    /// Build a vector from an array.
    this(V)(in V vec)
    if (isArray!V)
    {
        static if (isStaticArray!(typeof(vec)))
        {
            static assert(vec.length == length);
        }
        else
        {
            assert(vec.length == length);
        }
        _rep[] = vec;
    }

    /// Build a vector with all components assigned to one value
    this(in T comp)
    {
        _rep = comp;
    }

    /// Return the data of the array
    @property T[length] data() const
    {
        return _rep;
    }

    static if (N >= 2 && N <= 4)
    {
        /// Access the X component of the vector.
        @property T x() const
        {
            return _rep[0];
        }
        /// Assign the X component of the vector.
        @property void x(in T val)
        {
            _rep[0] = val;
        }

        /// Access the Y component of the vector.
        @property T y() const
        {
            return _rep[1];
        }
        /// Assign the Y component of the vector.
        @property void y(in T val)
        {
            _rep[1] = val;
        }

    }

    static if (N >= 3 && N <= 4)
    {
        /// Access the Z component of the vector.
        @property T z() const
        {
            return _rep[2];
        }
        /// Assign the Z component of the vector.
        @property void z(in T val)
        {
            _rep[2] = val;
        }
    }

    static if (N == 4)
    {
        /// Access the W component of the vector.
        @property T w() const
        {
            return _rep[3];
        }
        /// Assign the W component of the vector.
        @property void w(in T val)
        {
            _rep[3] = val;
        }
    }

    static if (isFloatingPoint!T)
    {
        // aliases for color and texture mapping

        // uv defined for Vec2
        // st defined for Vec2 and Vec4
        // stpq defined Vec4
        // rgb defined for Vec3 and Vec4
        // rgba defined for Vec4
        static if (N == 2)
        {
            alias u = x;
            alias v = y;
        }
        static if (N == 2 || N == 4)
        {
            alias s = x;
            alias t = y;
        }
        static if (N == 3 || N == 4)
        {
            alias r = x;
            alias g = y;
            alias b = z;
        }
        static if (N == 4)
        {
            alias a = w;
            alias p = z;
            alias q = w;
        }

        // TODO: swizzling properties
    }

    /// Unary "+" operation.
    Vec!(T, N) opUnary(string op : "+")() const
    {
        return this;
    }
    /// Unary "-" operation.
    Vec!(T, N) opUnary(string op : "-")() const
    {
        Vec!(T, N) res = this;
        foreach (ref v; res)
        {
            v = -v;
        }
        return res;
    }

    /// Perform a term by term assignment operation on the vector.
    ref Vec!(T, N) opOpAssign(string op, U)(in Vec!(U, N) oth)
            if ((op == "+" || op == "-" || op == "*" || op == "/") && isNumeric!U)
    {
        foreach (i, ref v; _rep)
        {
            mixin("v " ~ op ~ "= oth[i];");
        }
        return this;
    }

    /// Perform a scalar assignment operation on the vector.
    ref Vec!(T, N) opOpAssign(string op, U)(in U val)
            if ((op == "+" || op == "-" || op == "*" || op == "/" || (op == "%"
                && __traits(isIntegral, U))) && isNumeric!U)
    {
        foreach (ref v; _rep)
        {
            mixin("v " ~ op ~ "= val;");
        }
        return this;
    }

    /// Perform a term by term operation on the vector.
    Vec!(T, N) opBinary(string op, U)(in Vec!(T, U) oth) const
            if ((op == "+" || op == "-" || op == "*" || op == "/") && isNumeric!U)
    {
        Vec!(T, N) res = this;
        mixin("res " ~ op ~ "= oth;");
        return res;
    }

    /// Perform a scalar operation on the vector.
    Vec!(T, N) opBinary(string op, U)(in U val) const
            if ((op == "+" || op == "-" || op == "*" || op == "/" || (op == "%"
                && __traits(isIntegral, U))) && isNumeric!U)
    {
        Vec!(T, N) res = this;
        mixin("res " ~ op ~ "= val;");
        return res;
    }

    /// Perform a term by term operation on the vector.
    Vec!(T, N) opBinaryRight(string op, U)(in Vec!(U, N) oth) const
            if ((op == "+" || op == "-" || op == "*" || op == "/") && isNumeric!U)
    {
        Vec!(T, N) res = void;
        foreach (i, ref r; res)
        {
            mixin("r = oth[i] " ~ op ~ " _rep[i];");
        }
        return res;
    }

    /// Perform a scalar operation on the vector.
    Vec!(T, N) opBinaryRight(string op, U)(in U val) const
            if ((op == "+" || op == "-" || op == "*" || op == "/" || (op == "%"
                && __traits(isIntegral, U))) && isNumeric!U)
    {
        Vec!(T, N) res = void;
        foreach (i, ref r; res)
        {
            mixin("r = val " ~ op ~ " _rep[i];");
        }
        return res;
    }

    /// Foreach support.
    int opApply(int delegate(size_t i, ref T) dg)
    {
        int res;
        foreach (i, ref v; _rep)
        {
            res = dg(i, v);
            if (res)
                break;
        }
        return res;
    }

    /// Foreach support.
    int opApply(int delegate(ref T) dg)
    {
        int res;
        foreach (ref v; _rep)
        {
            res = dg(v);
            if (res)
                break;
        }
        return res;
    }

    // TODO: const opApply and foreach_reverse

    /// Index a vector component.
    T opIndex(in size_t index) const
    in
    {
        assert(index < N);
    }
    body
    {
        return _rep[index];
    }

    /// Assign a vector component.
    void opIndexAssign(in T val, in size_t index)
    in
    {
        assert(index < N);
    }
    body
    {
        _rep[index] = val;
    }

    /// Assign a vector component.
    void opIndexOpAssign(string op)(in T val, in size_t index)
    if (op == "+" || op == "-" || op == "*" || op == "/")
    in
    {
        assert(index < N);
    }
    body
    {
        mixin("_rep[index] "~op~"= val;");
    }

    /// Slicing support
    size_t[2] opSlice(in size_t start, in size_t end) const
    {
        assert(start <= end && end <= length);
        return [ start, end ];
    }

    /// ditto
    inout(T)[] opIndex(in size_t[2] slice) inout
    {
        return _rep[slice[0] .. slice[1]];
    }

    /// ditto
    void opIndexAssign(U)(in U val, in size_t[2] slice)
    {
        assert(correctSlice(slice));
        _rep[slice[0] .. slice[1]] = val;
    }

    /// ditto
    void opIndexAssign(U)(in U[] val, in size_t[2] slice)
    {
        assert(val.length == slice[1]-slice[0] && correctSlice(slice));
        _rep[slice[0] .. slice[1]] = val;
    }

    /// ditto
    void opIndexOpAssign(string op, U)(in U val, in size_t[2] slice)
    if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        foreach (i; slice[0]..slice[1])
        {
            mixin("_rep[i] "~op~"= val;");
        }
    }

    /// Term by term sliced assignement operation.
    void opIndexOpAssign(string op, U)(in U val, in size_t[2] slice)
    if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        foreach (i; slice[0]..slice[1])
        {
            mixin("_rep[i] "~op~"= val;");
        }
    }

    /// End of the vector.
    size_t opDollar()
    {
        return length;
    }

    private static bool correctSlice(size_t[2] slice)
    {
        return slice[0] <= slice[1] && slice[1] <= length;
    }
}

template isVec(VecT)
{
    import std.traits : TemplateOf;
    enum isVec = __traits(isSame, TemplateOf!VecT, Vec);
}

template isVec(size_t N, VecT)
{
    import std.traits : TemplateOf;
    enum isVec = isVec!VecT && VecT.length == N;
}

static assert(isVec!FVec3);

unittest
{

    DVec3 v;

    assert(v._rep[0] == 0);
    assert(v._rep[1] == 0);
    assert(v._rep[2] == 0);

    v = DVec3(4, 5, 6);

    assert(v._rep[0] == 4);
    assert(v._rep[1] == 5);
    assert(v._rep[2] == 6);
    assert(v[1] == 5);
    assert(v.z == 6);
    assert(v[$ - 1] == 6);

    assert(-v == DVec3(-4, -5, -6));

    v.z = 2;
    v[1] = 1;
    assert(v[1] == 1);
    assert(v.z == 2);

    auto c = DVec4(0.2, 1, 0.6, 0.9);
    assert(c.r == 0.2);
    assert(c.g == 1);
    assert(c.b == 0.6);
    assert(c.a == 0.9);
}

/// Compute the dot product of two vectors.
template dot(T, size_t N)
{
    T dot(in Vec!(T, N) v1, in Vec!(T, N) v2)
    {
        T sum = 0;
        foreach (i; StaticRange!(0, N))
        {
            sum += v1[i] * v2[i];
        }
        return sum;
    }
}

/// Compute the magnitude of a vector.
/// This is not to be confused with length which gives the number of components.
template magnitude(T, size_t N)
{
    T magnitude(in Vec!(T, N) v)
    {
        import std.math : sqrt;
        return sqrt(squaredMag(v));
    }
}

/// Compute the squared magnitude of a vector.
template squaredMag(T, size_t N)
{
    T squaredMag(in Vec!(T, N) v)
    {
        T sum = 0;
        foreach (i; StaticRange!(0, N))
        {
            sum += v[i] * v[i];
        }
        return sum;
    }
}

/// Compute the normalization of a vector.
template normalize(T, size_t N) if (isFloatingPoint!T)
{
    import dgt.math.approx : approxUlp;
    Vec!(T, N) normalize(in Vec!(T, N) v)
    in
    {
        assert(!approxUlp(magnitude(v), 0), "Cannot normalize a null vector.");
    }
    out (res)
    {
        assert(approxUlp(magnitude(res), 1));
    }
    body
    {
        import std.math : sqrt;
        return v / magnitude(v);
    }
}

static assert(DVec2.sizeof == 16);
static assert(DVec3.sizeof == 24);
static assert(DVec4.sizeof == 32);

///
unittest
{
    import dgt.math.approx : approxUlp;

    auto v1 = DVec3(12, 4, 3);
    auto v2 = DVec3(-5, 3, 7);

    assert(approxUlp(dot(v1, v2), -27));

    auto v = DVec3(3, 4, 5);
    assert(approxUlp(squaredMag(v), 50));

    assert(approxUlp(normalize(FVec3(4, 0, 0)), FVec3(1, 0, 0)));
}
