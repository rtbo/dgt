/// This module is about comparison of floating point arithmetics.
/// Supported by this very informative article:
/// https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/
module dgt.math.approx;

import dgt.math.vec : Vec;
import dgt.math.mat : Mat;
import dgt.core.typecons : StaticRange;

import std.traits : isFloatingPoint;

/// Different methods to check if two floating point values are close to each other.
enum ApproxMethod
{
    ulp,
    eps,
    ulpAndAbs,
    epsAndAbs,
}

/// Check with method given at runtime with default parameters
/// a and b can be any data sets supported by the approx template
bool approx(T)(ApproxMethod method, in T a, in T b)
{
    final switch(method)
    {
        case ApproxMethod.ulp:
            return approxUlp(a, b);
        case ApproxMethod.eps:
            return approxEps(a, b);
        case ApproxMethod.ulpAndAbs:
            return approxUlpAndAbs(a, b);
        case ApproxMethod.epsAndAbs:
            return approxEpsAndAbs(a, b);
    }
}

/// Compare two data sets with ApproxMethod.ulp.
/// That is call scalarApproxUlp on each couple of the data sets.
alias approxUlp = approx!(ApproxMethod.ulp);
/// Compare two data sets with ApproxMethod.eps.
/// That is call scalarApproxEps on each couple of the data sets.
alias approxEps = approx!(ApproxMethod.eps);
/// Compare two data sets with ApproxMethod.ulpAndAbs.
/// That is call scalarApproxUlpAndAbs on each couple of the data sets.
alias approxUlpAndAbs = approx!(ApproxMethod.ulpAndAbs);
/// Compare two data sets with ApproxMethod.epsAndAbs.
/// That is call scalarApproxEpsAndAbs on each couple of the data sets.
alias approxEpsAndAbs = approx!(ApproxMethod.epsAndAbs);


/// Compute the ULP difference between two floating point numbers
/// Negative result indicates that b has higher ULP value than a.
template ulpDiff(T) if (isFloatingPoint!T)
{
    int ulpDiff(in T a, in T b)
    {
        immutable fnA = FloatNum!T(a);
        immutable fnB = FloatNum!T(b);

        return (fnA.i - fnB.i);
    }
}

/// Determines if two floating point scalars are maxUlps close to each other.
template scalarApproxUlp(T) if (isFloatingPoint!T)
{
    bool scalarApproxUlp(in T a, in T b, in int maxUlps=4)
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
template scalarApproxEps(T) if (isFloatingPoint!T)
{
    bool scalarApproxEps (in T a, in T b, in T maxEps=4*T.epsilon)
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
template scalarApproxUlpAndAbs(T) if (isFloatingPoint!T)
{
    bool scalarApproxUlpAndAbs(in T a, in T b, in T maxAbs=0.0001, in size_t maxUlps=4)
    {
        import std.math : abs;
        if (diff(b-a) <= maxAbs) return true;
        return scalarApproxUlp(a, b, maxUlps);
    }
}

/// Check whether the relative error between a and b is smaller than maxEps.
/// If the absolute error is less than maxAbs, the test succeeds however.
/// This is useful when comparing against zero the result of a subtraction.
template scalarApproxEpsAndAbs(T) if (isFloatingPoint!T)
{
    bool scalarApproxEpsAndAbs(in T a, in T b, in T maxAbs=0.0001, in T maxEps=4*T.epsilon)
    {
        import std.math : abs;
        if (diff(b-a) <= maxAbs) return true;
        return scalarApproxEps(a, b, maxEps);
    }
}

/// Generic template to check approx method on different sets of data.
template approx(ApproxMethod method)
{
    /// Apply method on scalar
    bool approx(T, Args...)(in T a, in T b, Args args)
    if (isFloatingPoint!T)
    {
        static if (method == ApproxMethod.ulp)
        {
            return scalarApproxUlp(a, b, args);
        }
        else static if (method == ApproxMethod.eps)
        {
            return scalarApproxEps(a, b, args);
        }
        else static if (method == ApproxMethod.ulpAndAbs)
        {
            return scalarApproxUlpAndAbs(a, b, args);
        }
        else static if (method == ApproxMethod.epsAndAbs)
        {
            return scalarApproxEpsAndAbs(a, b, args);
        }
        else
        {
            static assert(false, "unimplemented");
        }
    }
    /// Apply method check on vectors
    bool approx(T, size_t N, Args...)(in T[N] v1, in T[N] v2, Args args)
    if (isFloatingPoint!T)
    {
        foreach (i; StaticRange!(0, N))
        {
            if (!approx(v1[i], v2[i], args))
                return false;
        }
        return true;
    }
    /// ditto
    bool approx(T, size_t N, Args...)(in Vec!(T, N) v1, in Vec!(T, N) v2, Args args)
    if (isFloatingPoint!T)
    {
        return approx(v1.data, v2.data, args);
    }
    /// Apply method check on arrays
    bool approx(T, Args...)(in T[] arr1, in T[] arr2, Args args)
    if (isFloatingPoint!T)
    {
        if (arr1.length != arr2.length) return false;
        foreach (i; 0 .. arr1.length)
        {
            if (!approx(arr1[i], arr2[i], args))
                return false;
        }
        return true;
    }
    /// Apply method check on matrices
    bool approx(T, size_t R, size_t C, Args...)(in T[R][C] m1, in T[R][C] m2, Args args)
    if (isFloatingPoint!T)
    {
        foreach (r; StaticRange!(0, R))
        {
            foreach (c; StaticRange!(0, C))
            {
                if (!approx(m1[r][c], m2[r][c], args))
                    return false;
            }
        }
        return true;
    }
    /// ditto
    bool approx(T, size_t R, size_t C, Args...)(in Mat!(T, R, C) m1, in Mat!(T, R, C) m2, Args args)
    if (isFloatingPoint!T)
    {
        foreach (r; StaticRange!(0, R))
        {
            foreach (c; StaticRange!(0, C))
            {
                if (!approx(m1.ctComp!(r, c), m2.ctComp!(r, c), args))
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

        static assert(0, "approxUlp does not support " ~ fullyQualifiedName!T);
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
