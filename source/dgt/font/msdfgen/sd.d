/// Signed distance representation
module dgt.font.msdfgen.sd;

struct SignedDistance {
    float distance = -float.max;
    float dot = 1;

    enum infinite = SignedDistance.init;

    this(float distance, float dot) {
        this.distance = distance;
        this.dot = dot;
    }

    int opCmp(ref const SignedDistance sd) const {
        import std.math : abs, cmp;

        const aDist = abs(distance);
        const aDot = dot;
        const bDist = abs(sd.distance);
        const bDot = sd.dot;

        if (aDist != bDist) return cmp(aDist, bDist);
        else return cmp(aDot, bDot);
    }
}
