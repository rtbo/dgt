/// This module is about comparison of floating point arithmetics.
/// Supported by this very informative article:
/// https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/
module dgt.math.approx;

import dgt.math.vec : Vec;
import dgt.math.mat : Mat;
import dgt.core.typecons : StaticRange;

import std.traits : isFloatingPoint;


/// Compute the ULPS difference between two floating point numbers
/// Negative result indicates that b has higher ULPS value than a.
template ulpsDiff(T) if (isFloatingPoint!T)
{
    int ulpsDiff(in T a, in T b)
    {
        immutable fnA = FloatNum!T(a);
        immutable fnB = FloatNum!T(b);

        return (fnA.i - fnB.i);
    }
}

/// Determines if two floating point scalars are maxUlps close to each other.
template approx(T) if (isFloatingPoint!T)
{
    bool approx(in T a, in T b, in int maxUlps = 4)
    {
        import std.math : abs;

        immutable fnA = FloatNum!T(a);
        immutable fnB = FloatNum!T(b);

        if (fnA.negative != fnB.negative)
        {
            return a == b; // check for +0 / -0
        }

        return (abs(fnA.i - fnB.i) <= maxUlps);
    }
}

/// Check whether the relative error between a and b is smaller than maxEps
template approxEps(T) if (isFloatingPoint!T)
{
    bool approx (in T a, in T b, in T maxEps=4*T.epsilon)
    {
        import std.math : abs;
        import std.algorithm : max;
        immutable diff = abs(b-a);
        immutable absA = abs(a);
        immutable absB = abs(b);
        immutable largest = max(absA, absB);
        return diff <= eps*largest;
    }
}

/// Determines if two floating point scalars are maxUlps close to each other.
/// If the absolute error is less than maxAbs, the test succeeds however.
/// This is useful when comparing against zero the result of a subtraction.
template approxUlpsAndAbs(T) if (isFloatingPoint!T)
{
    bool approxUlpsAndAbs(in T a, in T b, in T maxAbs, in size_t maxUlps=4)
    {
        import std.math : abs;
        if (diff(b-a) <= maxAbs) return true;
        return approx(a, b, maxUlps);
    }
}

/// Check whether the relative error between a and b is smaller than maxEps.
/// If the absolute error is less than maxAbs, the test succeeds however.
/// This is useful when comparing against zero the result of a subtraction.
template approxEpsAndAbs(T) if (isFloatingPoint!T)
{
    bool approxEpsAndAbs(in T a, in T b, in T maxAbs, in T maxEps=4*T.epsilon)
    {
        import std.math : abs;
        if (diff(b-a) <= maxAbs) return true;
        return approxEps(a, b, maxEps);
    }
}


/// Determines if two floating point vectors are maxUlps close to each other
template approx(T, int N) if (isFloatingPoint!T && N > 0)
{
    bool approx(in T[N] v1, in T[N] v2, in int maxUlps = 4)
    {
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
template approx(T, size_t R, size_t C) if (isFloatingPoint!T && R > 0 && C > 0)
{
    bool approx(in T[R][C] m1, in T[R][C] m2, in int maxUlps=4)
    {
        foreach (r; StaticRange!(0, R))
        {
            foreach (c; StaticRange!(0, C))
            {
                if (!approx(m1[r][c], m2[r][c]))
                    return false;
            }
        }
        return true;
    }
    bool approx(in Mat!(T, R, C) m1, in Mat!(T, R, C) m2, in int maxUlps=4)
    {
        foreach (r; StaticRange!(0, R))
        {
            foreach (c; StaticRange!(0, C))
            {
                if (!approx(m1[r, c], m2[r, c]))
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
        enum ExponentMask = 0x7f80_0000;
    }

    template FloatTraits(T : double)
    {
        alias IntType = long;
        enum ExponentMask = 0x7ff0_0000_0000_0000;
    }

    template FloatNum(T) if (isFloatingPoint!T)
    {
        union FloatNum
        {
            alias F = FloatTraits!T;

            alias FloatType = T;
            alias IntType = F.IntType;

            this (FloatType f)
            {
                this.f = f;
            }

            FloatType f;
            IntType i;

            @property bool negative() const
            {
                return i < 0;
            }

            debug @property IntType mantissa() const
            {
                enum IntType one = 1;
                return i & ((one << T.mant_dig) - one);
            }

            debug @property IntType exponent() const
            {
                return ((i & F.ExponentMask) >> T.mant_dig);
            }
        }
    }
}
