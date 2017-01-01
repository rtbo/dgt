/// Geometric transformation module
module dgt.math.transform;

import dgt.math.vec;
import dgt.math.mat;

version (unittest)
{
    import dgt.math.approx : approxUlp;
}

import std.traits;
import std.typecons : Flag, Yes, No;

/// Build a translation matrix.
auto translation(U, V)(in U x, in V y)
{
    alias ResMat = Mat3x3!(CommonType!(U, V));
    return ResMat(
        1, 0, x,
        0, 1, y,
        0, 0, 1,
    );
}

/// ditto
Mat3x3!T translation(T)(in Vec2!T v)
{
    return Mat3x3!T (
        1, 0, v.x,
        0, 1, v.y,
        0, 0, 1,
    );
}

/// ditto
auto translation(U, V, W)(in U x, in V y, in W z)
{
    alias ResMat = Mat4x4!(CommonType!(U, V, W));
    return ResMat(
        1, 0, 0, x,
        0, 1, 0, y,
        0, 0, 1, z,
        0, 0, 0, 1,
    );
}

/// ditto
Mat4x4!T translation(T)(in Vec3!T v)
{
    return Mat4x4!T (
        1, 0, 0, v.x,
        0, 1, 0, v.y,
        0, 0, 1, v.z,
        0, 0, 0, 1,
    );
}

unittest
{
    immutable v2 = dvec(4, 6);
    assert( approxUlp(translation(2, 7) * dvec(v2, 1), dvec(6, 13, 1)) );

    immutable v3 = dvec(5, 6, 7);
    assert( approxUlp(translation(7, 4, 1) * dvec(v3, 1), dvec(12, 10, 8, 1)) );
}



/// Build a rotation matrix.
/// angle in radians.
Mat3x3!T rotation(T) (in real angle)
{
    import std.math : cos, sin;
    immutable c = cast(T) cos(angle);
    immutable s = cast(T) sin(angle);
    return Mat3x3!T (
        c, -s, 0,
        s, c, 0,
        0, 0, 1
    );
}

/// ditto
Mat4x4!T rotation(T) (in real angle, in Vec3!T axis)
{
    import std.math : cos, sin;
    immutable u = normalize(axis);
    immutable c = cast(T) cos(angle);
    immutable s = cast(T) sin(angle);
    immutable c1 = 1 - c;
    return Mat4x4!T (
        c1 * u.x * u.x  +  c,
        c1 * u.x * u.y  -  s * u.z,
        c1 * u.x * u.z  +  s * u.y,
        0,
        c1 * u.y * u.x  +  s * u.z,
        c1 * u.y * u.y  +  c,
        c1 * u.y * u.z  -  s * u.x,
        0,
        c1 * u.z * u.x  -  s * u.y,
        c1 * u.z * u.y  +  s * u.x,
        c1 * u.z * u.z  +  c,
        0, 0, 0, 1
    );
}

/// ditto
auto rotation(U, V, W) (in real angle, in U x, in V y, in W z)
{
    return rotation(angle, vec(x, y, z));
}


/// Build a scale matrix.
Mat3!(CommonType!(U, V)) scale(U, V) (in U x, in V y)
{
    return Mat3!(CommonType!(U, V))(
        x, 0, 0,
        0, y, 0,
        0, 0, 1,
    );
}

/// ditto
Mat3!T scale(T) (in Vec2!T v)
{
    return Mat3!T (
        v.x, 0, 0,
        0, v.y, 0,
        0, 0, 1,
    );
}

/// ditto
Mat4!(CommonType!(U, V, W)) scale (U, V, W) (in U x, in V y, in W, z)
{
    return Mat4!(CommonType!(U, V, W))(
        x, 0, 0, 0,
        0, y, 0, 0,
        0, 0, z, 0,
        0, 0, 0, 1,
    );
}

/// ditto
Mat4!T scale(T) (in Vec3!T v)
{
    return Mat4!T (
        v.x, 0, 0, 0,
        0, v.y, 0, 0,
        0, 0, v.z, 0,
        0, 0, 0, 1,
    );
}

/// Transform a vector by a matrix in homogenous coordinates.
auto transform(V, M)(in V v, in M m)
if (isVec!(2, V) && isMat!(3, 3, M))
{
    return (m * vec(v, 1)).xy;
}
/// ditto
auto transform(V, M)(in V v, in M m)
if (isVec!(2, V) && isMat!(2, 3, M))
{
    return (m * vec(v, 1)).xy;
}
/// ditto
auto transform(V, M)(in V v, in M m)
if (isVec!(3, V) && isMat!(4, 4, M))
{
    return (m * vec(v, 1)).xyz;
}
/// ditto
auto transform(V, M)(in V v, in M m)
if (isVec!(3, V) && isMat!(3, 4, M))
{
    return (m * vec(v, 1)).xyz;
}

unittest
{
    // 2x3 matrix can hold affine 2D transforms
    immutable transl = DMat2x3(
        1, 0, 3,
        0, 1, 2,
    );
    assert( approxUlp(transform(dvec(3, 5), transl), dvec(6, 7)) );
}
