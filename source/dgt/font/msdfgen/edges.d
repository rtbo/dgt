module dgt.font.msdfgen.edges;

import dgt.font.msdfgen.algebra;
import dgt.font.msdfgen.arithmetic;
import dgt.font.msdfgen.sd;
import dgt.math.vec : FVec2;

abstract class EdgeSegment {

    abstract FVec2 point(in float param) const;
    abstract FVec2 direction(in float param) const;
    abstract SignedDistance signedDistance(in FVec2 origin, out float param) const;

    SignedDistance distanceToPseudoDistance(in SignedDistance distance,
                                            in FVec2 origin,
                                            in float param) const {
        import dgt.math.vec : dot, normalize;
        import std.math : abs;
        if (param < 0) {
            const dir = normalize(direction(0));
            const aq = origin-point(0);
            const ts = dot(aq, dir);
            if (ts < 0) {
                const pseudoDistance = cross2d(aq, dir);
                if (abs(pseudoDistance) <= abs(distance.distance)) {
                    return SignedDistance(pseudoDistance, 0);
                }
            }
        } else if (param > 1) {
            const dir = normalize(direction(1));
            const bq = origin-point(1);
            const ts = dot(bq, dir);
            if (ts > 0) {
                const pseudoDistance = cross2d(bq, dir);
                if (abs(pseudoDistance) <= abs(distance.distance)) {
                    return SignedDistance(pseudoDistance, 0);
                }
            }
        }
        return distance;
    }

    abstract void bounds(ref float l, ref float b, ref float r, ref float t) const;

    abstract @property immutable(EdgeSegment)[3] thirds() const;

    abstract string asString() const;

}


final class LinearSegment : EdgeSegment {
    FVec2[2] p;

    immutable this (in FVec2 start, in FVec2 end) {
        p = [start, end];
    }

    @property FVec2 start() const {
        return p[0];
    }

    @property FVec2 end() const {
        return p[1];
    }

    override FVec2 point(in float param) const {
        return mix(start, end, param);
    }

    override FVec2 direction(in float param) const {
        return end - start;
    }

    override SignedDistance signedDistance(in FVec2 origin, out float param) const {
        import dgt.math.vec : dot, magnitude, normalize;
        import std.math : abs;
        const aq = origin-start;
        const ab = end - start;
        param = dot(aq, ab)/dot(ab, ab);
        const eq = p[(param > 0.5f) ? 1 : 0] - origin;
        const endpointDistance = magnitude(eq);
        if (param > 0 && param < 1) {
            const orthoDistance = dot(ab.orthonormal(false), aq);
            if (abs(orthoDistance) < endpointDistance) {
                return SignedDistance(orthoDistance, 0);
            }
        }
        return SignedDistance(nonZeroSign(cross2d(aq, ab))*endpointDistance,
                              abs(dot(normalize(ab), normalize(eq))));
    }


    override void bounds(ref float l, ref float b, ref float r, ref float t) const
    {
        pointBounds(start, l, b, r, t);
        pointBounds(end, l, b, r, t);
    }

    override @property immutable(EdgeSegment)[3] thirds() const {
        const p13 = point(1.0/3.0);
        const p23 = point(2.0/3.0);
        return [
            new immutable LinearSegment(start, p13),
            new immutable LinearSegment(p13, p23),
            new immutable LinearSegment(p23, end),
        ];
    }

    override string asString() const {
        import std.format : format;
        return format("LinearSegment(%s, %s)", fvecStr(start), fvecStr(end));
    }
}

final class QuadraticSegment : EdgeSegment {
    FVec2[3] p; // start, control, end

    immutable this(in FVec2 start, in FVec2 control, in FVec2 end) {
        p = [
            start,
            (start == control || control == end) ? 0.5*(start+end) : control,
            end
        ];
    }

    @property FVec2 start() const {
        return p[0];
    }

    @property FVec2 control() const {
        return p[1];
    }

    @property FVec2 end() const {
        return p[2];
    }

    override FVec2 point(in float param) const {
        return mix(mix(p[0], p[1], param), mix(p[1], p[2], param), param);
    }

    override FVec2 direction (in float param) const {
        return mix(p[1]-p[0], p[2]-p[1], param);
    }

    override SignedDistance signedDistance(in FVec2 origin, out float param) const {
        import dgt.math.vec : dot, magnitude, normalize;
        import std.math : abs;
        const qa = p[0]-origin;
        const ab = p[1]-p[0];
        const br = p[0]+p[2]-p[1]-p[1];
        const a = dot(br, br);
        const b = 3*dot(ab, br);
        const c = 2*dot(ab, ab) + dot(qa, br);
        const d = dot(qa, ab);
        float[3] buf;
        auto solutions = solveCubic(a, b, c, d, buf[]);

        auto minDistance = nonZeroSign(cross2d(ab, qa)) * magnitude(qa); // distance from A
        param = -dot(qa, ab) / dot(ab, ab);
        {
            const distance = nonZeroSign(cross2d(p[2]-p[1], p[2]-origin)) * magnitude(p[2]-origin); // distance from B
            if (abs(distance) < abs(minDistance)) {
                minDistance = distance;
                param = dot(origin-p[1], p[2]-p[1])/dot(p[2]-p[1], p[2]-p[1]);
            }
        }
        foreach (const s; solutions) {
            if (s > 0 && s < 1) {
                const endpoint = p[0] + 2*s*ab + s*s*br;
                const distance = nonZeroSign(cross2d(p[2]-p[0], endpoint-origin)) * magnitude(endpoint-origin);
                if (abs(distance) <= abs(minDistance)) {
                    minDistance = distance;
                    param = s;
                }
            }
        }

        if (param >= 0 && param <= 1)
            return SignedDistance(minDistance, 0);
        if (param < .5)
            return SignedDistance(minDistance, abs(dot(normalize(ab), normalize(qa))));
        else
            return SignedDistance(minDistance, abs(dot(normalize(p[2]-p[1]), normalize(p[2]-origin))));
    }

    override void bounds(ref float l, ref float b, ref float r, ref float t) const
    {
        pointBounds(p[0], l, b, r, t);
        pointBounds(p[2], l, b, r, t);
        const bot = (p[1]-p[0])-(p[2]-p[1]);
        if (bot.x) {
            const param = (p[1].x-p[0].x)/bot.x;
            if (param > 0 && param < 1) {
                pointBounds(point(param), l, b, r, t);
            }
        }
        if (bot.y) {
            const param = (p[1].y-p[0].y)/bot.y;
            if (param > 0 && param < 1) {
                pointBounds(point(param), l, b, r, t);
            }
        }
    }

    override @property immutable(EdgeSegment)[3] thirds() const {
        return [
            new immutable QuadraticSegment(
                p[0], mix(p[0], p[1], 1/3.), point(1/3.0)),
            new immutable QuadraticSegment(
                point(1/3.), mix(mix(p[0], p[1], 5/9.),
                mix(p[1], p[2], 4/9.), .5), point(2/3.)),
            new immutable QuadraticSegment(
                point(2/3.), mix(p[1], p[2], 2/3.), p[2]),
        ];
    }

    override string asString() const {
        import std.format : format;
        return format("QuadraticSegment(%s, %s)", fvecStr(start), fvecStr(end));
    }

}


final class CubicSegment : EdgeSegment {
    FVec2[4] p; // start, control1, control2, end

    immutable this(in FVec2 start, in FVec2 control1, in FVec2 control2, in FVec2 end) {
        p = [ start, control1, control2, end ];
    }

    @property FVec2 start() const {
        return p[0];
    }

    @property FVec2 control1() const {
        return p[1];
    }

    @property FVec2 control2() const {
        return p[2];
    }

    @property FVec2 end() const {
        return p[3];
    }

    override FVec2 point(in float param) const {
        const p12 = mix(p[1], p[2], param);
        return mix(mix(mix(p[0], p[1], param), p12, param), mix(p12, mix(p[2], p[3], param), param), param);
    }

    override FVec2 direction (in float param) const {
        const tangent = mix(mix(p[1]-p[0], p[2]-p[1], param), mix(p[2]-p[1], p[3]-p[2], param), param);
        if (!tangent.x && !tangent.y) {
            if (param == 0) return p[2]-p[0];
            if (param == 1) return p[3]-p[1];
        }
        return tangent;
    }

    override SignedDistance signedDistance(in FVec2 origin, out float param) const {
        import dgt.math.vec : dot, magnitude, normalize;
        import std.math : abs;

        enum searchStarts = 4;
        enum searchSteps = 4;

        const qa = p[0]-origin;
        const ab = p[1]-p[0];
        const br = p[2]-p[1]-ab;
        const as = (p[3]-p[2])-(p[2]-p[1])-br;

        auto epDir = direction(0);
        auto minDistance = nonZeroSign(cross2d(epDir, qa)) * magnitude(qa); // distance from A
        param = -dot(qa, epDir) / dot(epDir, epDir);
        {
            epDir = direction(1);
            const distance = nonZeroSign(cross2d(epDir, p[3]-origin)) * magnitude(p[3]-origin); // distance from B
            if (abs(distance) < abs(minDistance)) {
                minDistance = distance;
                param = dot(origin+epDir-p[3], epDir) / dot(epDir, epDir);
            }
        }
        // Iterative minimum distance search
        foreach (const i; 0 .. searchStarts) {
            auto t = i / cast(float)searchStarts;
            for (int step = 0;; ++step) {
                const qpt = point(t)-origin;
                const distance = nonZeroSign(cross2d(direction(t), qpt)) * magnitude(qpt);
                if (abs(distance) < abs(minDistance)) {
                    minDistance = distance;
                    param = t;
                }
                if (step == searchSteps)
                    break;
                // Improve t
                const d1 = 3*as*t*t + 6*br*t + 3*ab;
                const d2 = 6*as*t + 6*br;
                t -= dot(qpt, d1) / (dot(d1, d1) + dot(qpt, d2));
                if (t < 0 || t > 1)
                    break;
            }
        }

        if (param >= 0 && param <= 1)
            return SignedDistance(minDistance, 0);
        if (param < 0.5)
            return SignedDistance(minDistance, abs(dot(normalize(direction(0)), normalize(qa))));
        else
            return SignedDistance(minDistance, abs(dot(normalize(direction(1)), normalize(p[3]-origin))));
    }

    override void bounds(ref float l, ref float b, ref float r, ref float t) const
    {
        pointBounds(p[0], l, b, r, t);
        pointBounds(p[3], l, b, r, t);
        const a0 = p[1]-p[0];
        const a1 = 2 * (p[2]-p[1]-a0);
        const a2 = p[3] - 3*p[2] + 3*p[1] - p[0];
        float[2] buf;
        auto params = solveQuadratic(a2.x, a1.x, a0.x, buf);
        foreach (const param; params) {
            if (param > 0 && param < 1) {
                pointBounds(point(param), l, b, r, t);
            }
        }

        params = solveQuadratic(a2.y, a1.y, a0.y, buf);
        foreach (const param; params) {
            if (param > 0 && param < 1) {
                pointBounds(point(param), l, b, r, t);
            }
        }
    }

    override @property immutable(EdgeSegment)[3] thirds() const {
        const p13 = point(1/3.);
        const p23 = point(2/3.);
        return [
            new immutable CubicSegment( p[0],
                p[0] == p[1] ? p[0] : mix(p[0], p[1], 1/3.),
                mix(mix(p[0], p[1], 1/3.), mix(p[1], p[2], 1/3.), 1/3.),
                p13),

            new immutable CubicSegment( p13,
                mix(
                    mix(mix(p[0], p[1], 1/3.), mix(p[1], p[2], 1/3.), 1/3.),
                    mix(mix(p[1], p[2], 1/3.), mix(p[2], p[3], 1/3.), 1/3.), 2/3.),
                mix(
                    mix(mix(p[0], p[1], 2/3.), mix(p[1], p[2], 2/3.), 2/3.),
                    mix(mix(p[1], p[2], 2/3.), mix(p[2], p[3], 2/3.), 2/3.), 1/3.),
                p23),

            new immutable CubicSegment( p23,
                mix(mix(p[1], p[2], 2/3.), mix(p[2], p[3], 2/3.), 2/3.),
                p[2] == p[3] ? p[3] : mix(p[2], p[3], 2/3.),
                p[3]),

        ];
    }

    override string asString() const {
        import std.format : format;
        return format("CubicSegment(%s, %s)", fvecStr(start), fvecStr(end));
    }

}

private void pointBounds(in FVec2 p, ref float l, ref float b, ref float r, ref float t) {
    if (p.x < l) l = p.x;
    if (p.y < b) b = p.y;
    if (p.x > r) r = p.x;
    if (p.y > t) t = p.y;
}

private string fvecStr(in FVec2 p) {
    import std.format : format;
    return format("[%s, %s]", p.x, p.y);
}
