module dgt.math.approx;

import dgt.math.vec : Vec;

import std.traits : isFloatingPoint;

// this module is about comparison of floating arithmetics

/// Determines if two floating point scalars are maxUlps close to each other
template approx(T) if (isFloatingPoint!T)
{
    bool approx(in T a, in T b, in int maxUlps = 4)
    {
        import std.math : abs;

        if (a == b)
            return true;

        immutable FloatNum!T fnA = {f: a};
        immutable FloatNum!T fnB = {f: b};
        return (abs(fnA.i - fnB.i) <= maxUlps);
    }
}

/// Determines if two floating point vectors are maxUlps close to each other
template approx(T, int N) if (isFloatingPoint!T && N > 0)
{
    bool approx(in T[N] v1, in T[N] v2, in int maxUlps = 4)
    {
        import dgt.core.typecons : StaticRange;

        foreach (i; StaticRange!(0, N))
        {
            if (!approx(v1[i], v2[i]))
                return false;
        }
        return true;
    }
}

/// ditto
template approx(T, int N) if (isFloatingPoint!T)
{
    bool approx(in Vec!(T, N) v1, in Vec!(T, N) v2)
    {
        return approx(v1.data, v2.data);
    }
}

/// Determines if two floating point matrices are maxUlps close to each other
template approx(T, int M, int N) if (isFloatingPoint!T && M > 0 && N > 0)
{
    bool approx(in T[M][N] v1, in T[M][N] v2, in int maxUlps = 4)
    {
        import dgt.core.typecons : StaticRange;

        foreach (n; StaticRange!(0, N))
        {
            foreach (m; StaticRange!(0, M))
            {
                if (!approx(v1[m][n], v2[m][n]))
                    return false;
            }
        }
        return true;
    }
}

private
{
    template FloatTraits(T) if (isFloatingPoint!T)
    {
        import std.traits : fullyQualifiedName;

        static assert(0, "approx does not support " ~ fullyQualifiedName!T);
    }

    template FloatTraits(T : float)
    {
        alias IntType = int;
        enum MantissaLen = 23;
        enum ExponentMask = 0x7f80_0000;
    }

    template FloatTraits(T : double)
    {
        alias IntType = long;
        enum MantissaLen = 52;
        enum ExponentMask = 0x7ff0_0000_0000_0000;
    }

    template FloatNum(T) if (isFloatingPoint!T)
    {
        union FloatNum
        {
            alias F = FloatTraits!T;

            alias FloatType = T;
            alias IntType = F.IntType;

            FloatType f;
            IntType i;

            @property bool negative() const
            {
                return i < 0;
            }

            @property IntType mantissa() const
            {
                enum IntType one = 1;
                return i & ((one << F.MantissaLen) - one);
            }

            @property IntType exponent() const
            {
                return ((i & F.ExponentMask) >> F.MantissaLen);
            }
        }
    }
}
