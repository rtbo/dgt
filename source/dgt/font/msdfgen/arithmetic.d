module dgt.font.msdfgen.arithmetic;

import dgt.math.vec : FVec2;

T mix(T)(in T a, in T b, in float weight) {
    return (1-weight)*a + weight*b;
}

/// Returns 1 for non-negative values and -1 for negative values.
int nonZeroSign(T)(in T n) {
    return 2*(n > T(0))-1;
}

FVec2 orthogonal(in FVec2 input, in bool polarity) {
    return polarity ? FVec2(-input.y, input.x) : FVec2(input.y, -input.x);
}

float cross2d(in FVec2 a, in FVec2 b) {
    return a.x*b.y - a.y*b.x;
}

/// Returns the middle out of three values
T median(T)(in T a, in T b, in T c) {
    import std.algorithm : min, max;
    return max(min(a, b), min(max(a, b), c));
}
