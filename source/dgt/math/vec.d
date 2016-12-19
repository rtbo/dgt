module dgt.math.vec;

import dgt.util : StaticRange;

import std.traits;

alias TVec2(T) = TVecN!(T, 2);
alias TVec3(T) = TVecN!(T, 3);
alias TVec4(T) = TVecN!(T, 4);

alias DVecN(int N) = TVecN!(double, N);
alias FVecN(int N) = TVecN!(float, N);
alias IVecN(int N) = TVecN!(int, N);

alias DVec2 = TVecN!(double, 2);
alias DVec3 = TVecN!(double, 3);
alias DVec4 = TVecN!(double, 4);

alias FVec2 = TVecN!(float, 2);
alias FVec3 = TVecN!(float, 3);
alias FVec4 = TVecN!(float, 4);

alias IVec2 = TVecN!(int, 2);
alias IVec3 = TVecN!(int, 3);
alias IVec4 = TVecN!(int, 4);

struct TVecN(T, int N) if (N >= 0 && N <= 4 && __traits(isArithmetic, T))
{
    T[N] rep = 0;

    this(T...)(in T vals) if (T.length == N)
    {
        foreach (i, v; vals)
        {
            rep[i] = v;
        }
    }

    this(in T[N] vec)
    {
        rep = vec;
    }

    this(in T s)
    {
        foreach (ref v; rep)
        {
            v = s;
        }
    }

    static if (N >= 2 && N <= 4)
    {

        @property T x() const
        {
            return rep[0];
        }

        @property void x(in T val)
        {
            rep[0] = val;
        }

        @property T y() const
        {
            return rep[1];
        }

        @property void y(in T val)
        {
            rep[1] = val;
        }

    }

    static if (N >= 3 && N <= 4)
    {
        @property T z() const
        {
            return rep[2];
        }

        @property void z(in T val)
        {
            rep[2] = val;
        }
    }

    static if (N == 4)
    {
        @property T w() const
        {
            return rep[3];
        }

        @property void w(in T val)
        {
            rep[3] = val;
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

    TVecN!(T, N) opUnary(string op : "+")() const
    {
        return this;
    }

    TVecN!(T, N) opUnary(string op : "-")() const
    {
        TVecN!(T, N) res = this;
        foreach (ref v; res)
        {
            v = -v;
        }
        return res;
    }

    // term by term operator
    ref TVecN!(T, N) opOpAssign(string op, U)(in TVecN!(U, N) oth)
            if ((op == "+" || op == "-" || op == "*" || op == "/") && isNumeric!U)
    {
        foreach (i, ref v; rep)
        {
            mixin("v " ~ op ~ "= oth[i];");
        }
        return this;
    }

    ref TVecN!(T, N) opOpAssign(string op, U)(in U val)
            if ((op == "+" || op == "-" || op == "*" || op == "/" || (op == "%"
                && __traits(isIntegral, U))) && isNumeric!U)
    {
        foreach (ref v; rep)
        {
            mixin("v " ~ op ~ "= val;");
        }
        return this;
    }

    // term by term operator
    TVecN!(T, N) opBinary(string op, U)(in TVecN!(T, U) oth) const
            if ((op == "+" || op == "-" || op == "*" || op == "/") && isNumeric!U)
    {
        TVecN!(T, N) res = this;
        mixin("res " ~ op ~ "= oth;");
        return res;
    }

    TVecN!(T, N) opBinary(string op, U)(in U val) const
            if ((op == "+" || op == "-" || op == "*" || op == "/" || (op == "%"
                && __traits(isIntegral, U))) && isNumeric!U)
    {
        TVecN!(T, N) res = this;
        mixin("res " ~ op ~ "= val;");
        return res;
    }

    // term by term operator
    TVecN!(T, N) opBinaryRight(string op, U)(in TVecN!(U, N) oth) const
            if ((op == "+" || op == "-" || op == "*" || op == "/") && isNumeric!U)
    {
        TVecN!(T, N) res = void;
        foreach (i, ref r; res)
        {
            mixin("r = oth[i] " ~ op ~ " rep[i];");
        }
        return res;
    }

    TVecN!(T, N) opBinaryRight(string op, U)(in U val) const
            if ((op == "+" || op == "-" || op == "*" || op == "/" || (op == "%"
                && __traits(isIntegral, U))) && isNumeric!U)
    {
        TVecN!(T, N) res = void;
        foreach (i, ref r; res)
        {
            mixin("r = val " ~ op ~ " rep[i];");
        }
        return res;
    }

    int opApply(int delegate(size_t i, ref T) dg)
    {
        int res;
        foreach (i, ref v; rep)
        {
            res = dg(i, v);
            if (res)
                break;
        }
        return res;
    }

    int opApply(int delegate(ref T) dg)
    {
        int res;
        foreach (ref v; rep)
        {
            res = dg(v);
            if (res)
                break;
        }
        return res;
    }

    ref inout(T) opIndex(in size_t index) inout
    in
    {
        assert(index < N);
    }
    body
    {
        return rep[index];
    }

    int opDollar()
    {
        return N;
    }
}

unittest
{

    DVec3 v;

    assert(v.rep[0] == 0);
    assert(v.rep[1] == 0);
    assert(v.rep[2] == 0);

    v = DVec3(4, 5, 6);

    assert(v.rep[0] == 4);
    assert(v.rep[1] == 5);
    assert(v.rep[2] == 6);
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

template dot(T, int N)
{

    T dot(in TVecN!(T, N) v1, in TVecN!(T, N) v2)
    {
        T sum = 0;
        foreach (i; StaticRange!(0, N))
        {
            sum += v1[i] * v2[i];
        }
        return sum;
    }

}

template magnitude(T, int N)
{
    T magnitude(in TVecN!(T, N) v)
    {
        return sqrt(squaredMag(v));
    }
}

template squaredMag(T, int N)
{
    T squaredMag(in TVecN!(T, N) v)
    {
        T sum = 0;
        foreach (i; StaticRange!(0, N))
        {
            sum += v[i] * v[i];
        }
        return sum;
    }
}

template normalize(T, int N) if (isFloatingPoint!T)
{
    TVecN!(T, N) normalize(in TVecN!(T, N) v)
    {
        import std.math : sqrt;

        return v / sqrt(dot(v, v));
    }
}

static assert(DVec2.sizeof == 16);
static assert(DVec3.sizeof == 24);
static assert(DVec4.sizeof == 32);

///
unittest
{
    import dgt.math.approx : approx;

    auto v1 = DVec3(12, 4, 3);
    auto v2 = DVec3(-5, 3, 7);

    assert(approx(dot(v1, v2), -27));

    auto v = DVec3(3, 4, 5);
    assert(approx(squaredMag(v), 50));

    assert(approx(normalize(FVec3(4, 0, 0)), FVec3(1, 0, 0)));
}
