module dgt.font.msdfgen.algebra;

import std.traits : isFloatingPoint;

F[] solveQuadratic(F)(in F a, in F b, in F c, F[] x)
if (isFloatingPoint!F)
in {
    assert(x.length >= 2);
}
body {
    import std.math : abs, sqrt;

    if (abs(a) < 1e-14) {
        if (abs(b) < 1e-14) {
            assert(c != 0);
            return [];
        }
        x[0] = -c/b;
        return x[0 .. 1];
    }
    F dscr = b*b-4*a*c;
    if (dscr > 0) {
        dscr = sqrt(dscr);
        x[0] = (-b+dscr)/(2*a);
        x[1] = (-b-dscr)/(2*a);
        return x[0 .. 2];
    } else if (dscr == 0) {
        x[0] = -b/(2*a);
        return x[0 .. 1];
    } else
        return [];
}

private F[] solveCubicNormed(F)(F a, F b, F c, F[] x) {
    import std.math : abs, acos, cos, PI, pow, sqrt;
    const a2 = a*a;
    float q  = (a2 - 3*b)/9;
    const r  = (a*(2*a2-9*b) + 27*c)/54;
    const r2 = r*r;
    const q3 = q*q*q;
    float A, B;
    if (r2 < q3) {
        float t = r/sqrt(q3);
        if (t < -1) t = -1;
        if (t > 1) t = 1;
        t = acos(t);
        a /= 3; q = -2*sqrt(q);
        x[0] = q*cos(t/3)-a;
        x[1] = q*cos((t+2*PI)/3)-a;
        x[2] = q*cos((t-2*PI)/3)-a;
        return x[0 .. 3];
    } else {
        A = -pow(abs(r)+sqrt(r2-q3), 1/3.);
        if (r < 0) A = -A;
        B = A == 0 ? 0 : q/A;
        a /= 3;
        x[0] = (A+B)-a;
        x[1] = -0.5*(A+B)-a;
        x[2] = 0.5*sqrt(3.)*(A-B);
        if (abs(x[2]) < 1e-14) {
            return x[0 .. 2];
        }
        return x[0 .. 1];
    }
}

F[] solveCubic(F)(in F a, in F b, in F c, in F d, F[] x)
in {
    assert(x.length >= 3);
}
body {
    import std.math : abs;
    if (abs(a) < 1e-14) {
        return solveQuadratic(b, c, d, x);
    }
    return solveCubicNormed(b/a, c/a, d/a, x);
}
