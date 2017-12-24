module dgt.font.msdfgen;

import dgt.core.image;
import dgt.font.msdfgen.arithmetic;
import dgt.font.msdfgen.edges;
import dgt.font.msdfgen.shape;
import dgt.font.msdfgen.sd;
import dgt.font.typeface;
import dgt.math.vec;

import std.algorithm;
import std.array;
import std.math;
import std.parallelism;
import std.range;
import std.typecons;

public import dgt.font.msdfgen.coloring : edgeColoringSimple;


Shape buildShape(ScalingContext sc, GlyphId glyphId)
{
    static class OutlineAcc : OutlineAccumulator {
        override void moveTo(in FVec2 to) {
            if (contour.length) {
                shape ~= contour;
            }
            contour = [];
            pos = to;
        }
        override void lineTo(in FVec2 to) {
            contour ~= Edge(new immutable LinearSegment(pos, to));
            pos = to;
        }
        override void conicTo(in FVec2 control, in FVec2 to) {
            contour ~= Edge(new immutable QuadraticSegment(pos, control, to));
            pos = to;
        }
        override void cubicTo(in FVec2 control1, in FVec2 control2, in FVec2 to) {
            contour ~= Edge(new immutable CubicSegment(pos, control1, control2, to));
            pos = to;
        }

        Shape shape;
        Contour contour;
        FVec2 pos;
    }

    auto oa = new OutlineAcc;
    sc.getOutline(glyphId, oa);
    oa.shape ~= oa.contour;
    return oa.shape;
}


void generateMSDF(Image output, const(Shape) shape, in float range, in FVec2 scale,
                  in FVec2 translate, in float edgeThreshold=1f)
in {
    assert(output.format == ImageFormat.xrgb || output.format == ImageFormat.argb);
}
body {

    const w = output.width;
    const h = output.height;

    const windings = shape.map!(contour => contour.winding).array;

    auto contourSD = uninitializedArray!(MultiDistance[])(shape.length);

    foreach (y; 0 .. h) {

        const row = h - y - 1;
        auto line = output.line(row);

        foreach (x; 0 .. w) {

            const p = vec(x+.5f, y+.5f) / scale - translate;

            EdgePoint sr;
            EdgePoint sg;
            EdgePoint sb;

            float d = float.max;
            float negDist = float.max;
            float posDist = -float.max;
            Winding winding = Winding.undetermined;

            foreach (i, contour; shape) {
                EdgePoint r;
                EdgePoint g;
                EdgePoint b;

                foreach (edge; contour) {

                    float param = void;
                    const distance = edge.seg.signedDistance(p, param);

                    if (edge.col & EdgeColor.red && distance < r.minDistance) {
                        r.minDistance = distance;
                        r.nearEdge = edge.seg;
                        r.nearParam = param;
                    }
                    if (edge.col & EdgeColor.green && distance < g.minDistance) {
                        g.minDistance = distance;
                        g.nearEdge = edge.seg;
                        g.nearParam = param;
                    }
                    if (edge.col & EdgeColor.blue && distance < b.minDistance) {
                        b.minDistance = distance;
                        b.nearEdge = edge.seg;
                        b.nearParam = param;
                    }
                }
                if (r.minDistance < sr.minDistance) {
                    sr = r;
                }
                if (g.minDistance < sg.minDistance) {
                    sg = g;
                }
                if (b.minDistance < sb.minDistance) {
                    sb = b;
                }

                auto medMinDist = abs(median(r.minDistance.distance, g.minDistance.distance, b.minDistance.distance));
                if (medMinDist < d) {
                    d = medMinDist;
                    winding = windings[i].opposite;
                }

                if (r.nearEdge) {
                    r.minDistance = r.nearEdge.distanceToPseudoDistance(r.minDistance, p, r.nearParam);
                }
                if (g.nearEdge) {
                    g.minDistance = g.nearEdge.distanceToPseudoDistance(g.minDistance, p, g.nearParam);
                }
                if (b.nearEdge) {
                    b.minDistance = b.nearEdge.distanceToPseudoDistance(b.minDistance, p, b.nearParam);
                }

                medMinDist = median(r.minDistance.distance, g.minDistance.distance, b.minDistance.distance);
                contourSD[i].r = r.minDistance.distance;
                contourSD[i].g = g.minDistance.distance;
                contourSD[i].b = b.minDistance.distance;
                contourSD[i].med = medMinDist;

                if (windings[i].positive && medMinDist >= 0 && abs(medMinDist) < abs(posDist)) {
                    posDist = medMinDist;
                }
                if (windings[i].negative && medMinDist <= 0 && abs(medMinDist) < abs(negDist)) {
                    negDist = medMinDist;
                }
            }

            if (sr.nearEdge) {
                sr.minDistance = sr.nearEdge.distanceToPseudoDistance(sr.minDistance, p, sr.nearParam);
            }
            if (sg.nearEdge) {
                sg.minDistance = sg.nearEdge.distanceToPseudoDistance(sg.minDistance, p, sg.nearParam);
            }
            if (sb.nearEdge) {
                sb.minDistance = sb.nearEdge.distanceToPseudoDistance(sb.minDistance, p, sb.nearParam);
            }

            MultiDistance msd;

            if (posDist >= 0 && abs(posDist) <= abs(negDist)) {
                msd.med = -float.max;
                winding = Winding.positive;
                foreach (i; 0 .. shape.length) {
                    if (windings[i].positive && contourSD[i].med > msd.med && abs(contourSD[i].med) < abs(negDist)) {
                        msd = contourSD[i];
                    }
                }
            }
            else if (negDist <= 0 && abs(negDist) <= abs(posDist)) {
                msd.med = float.max;
                winding = Winding.negative;
                foreach (i; 0 .. shape.length) {
                    if (windings[i].negative && contourSD[i].med < msd.med && abs(contourSD[i].med) < abs(posDist)) {
                        msd = contourSD[i];
                    }
                }
            }
            foreach (i; 0 .. shape.length) {
                if (windings[i] != winding && abs(contourSD[i].med) < abs(msd.med)) {
                    msd = contourSD[i];
                }
            }

            if (median(sr.minDistance.distance, sg.minDistance.distance, sb.minDistance.distance) == msd.med) {
                msd.r = sr.minDistance.distance;
                msd.g = sg.minDistance.distance;
                msd.b = sb.minDistance.distance;
            }

            float mapChannel(in float val) {
                float res = val/range + 0.5f;
                if (res < 0) res = 0;
                if (res > 1) res = 1;
                return res;
            }

            import dgt.core.color : Color;
            const rgb = Color(mapChannel(msd.r), mapChannel(msd.g), mapChannel(msd.b));
            line.setArgb(x, rgb.argb);
        }
    }

    if (edgeThreshold > 0) {
        msdfErrorCorrection(output, vec(
            edgeThreshold/(range*scale.x), edgeThreshold/(range*scale.y)
        ));
    }
}

private struct MultiDistance {
    float r = -float.max;
    float g = -float.max;
    float b = -float.max;
    float med = -float.max;
}

private struct EdgePoint {
    SignedDistance minDistance;
    Rebindable!(immutable(EdgeSegment)) nearEdge;
    float nearParam = 0;
}

private bool pixelClash(in uint a, in uint b, in ubyte threshold) {

    const ared = a.red;
    const agreen = a.green;
    const ablue = a.blue;
    const bred = b.red;
    const bgreen = b.green;
    const bblue = b.blue;

    // Only consider pair where both are on the inside or both are on the outside
    const bool aIn = (ared > 127)+(agreen > 127)+(ablue > 127) >= 2;
    const bool bIn = (bred > 127)+(bgreen > 127)+(bblue > 127) >= 2;
    if (aIn != bIn) return false;
    // If the change is 0 <-> 1 or 2 <-> 3 channels and not 1 <-> 1 or 2 <-> 2, it is not a clash
    if ((ared > 127 && agreen > 127 && ablue > 127) || (ared < 127 && agreen < 127 && ablue < 127)
        || (bred > 127 && bgreen > 127 && bblue > 127) || (bred < 127 && bgreen < 127 && bblue < 127))
        return false;
    // Find which color is which: _a, _b = the changing channels, _c = the remaining one
    int aa, ab, ba, bb, ac, bc;
    if ((ared > 127) != (bred > 127) && (ared < 127) != (bred < 127)) {
        aa = ared, ba = bred;
        if ((agreen > 127) != (bgreen > 127) && (agreen < 127) != (bgreen < 127)) {
            ab = agreen, bb = bgreen;
            ac = ablue, bc = bblue;
        } else if ((ablue > 127) != (bblue > 127) && (ablue < 127) != (bblue < 127)) {
            ab = ablue, bb = bblue;
            ac = agreen, bc = bgreen;
        } else
            return false; // this should never happen
    } else if ((agreen > 127) != (bgreen > 127) && (agreen < 127) != (bgreen < 127)
        && (ablue > 127) != (bblue > 127) && (ablue < 127) != (bblue < 127)) {
        aa = agreen, ba = bgreen;
        ab = ablue, bb = bblue;
        ac = ared, bc = bred;
    } else
        return false;
    // Find if the channels are in fact discontinuous
    return (abs(aa-ba) >= threshold)
        && (abs(ab-bb) >= threshold)
        && abs(ac-127) >= abs(bc-127); // Out of the pair, only flag the pixel farther from a shape edge
}

private void msdfErrorCorrection(Image output, in FVec2 threshold) {
    size_t[2][] clashes;
    const w = output.width;
    const h = output.height;
    const stride = output.stride;
    auto data = output.data;

    uint pixel(in size_t x, in size_t y) {
        return data[y*stride .. (y+1)*stride].getArgb(x);
    }
    void setPixel(in size_t x, in size_t y, in uint pix) {
        data[y*stride .. (y+1)*stride].setArgb(x, pix);
    }

    foreach (y; 0 .. h) {
        foreach (x; 0 .. w) {
            if ((x > 0 && pixelClash(pixel(x, y), pixel(x-1, y), cast(ubyte)(threshold.x*255)))
                || (x < w-1 && pixelClash(pixel(x, y), pixel(x+1, y), cast(ubyte)(threshold.x*255)))
                || (y > 0 && pixelClash(pixel(x, y), pixel(x, y-1), cast(ubyte)(threshold.y*255)))
                || (y < h-1 && pixelClash(pixel(x, y), pixel(x, y+1), cast(ubyte)(threshold.y*255)))) {
                clashes ~= [x, y];
            }
        }
    }

    foreach (c; clashes) {
        const pix = pixel(c[0], c[1]);
        const med = median(pix.red, pix.green, pix.blue);
        setPixel(c[0], c[1], argb(0xff, med, med, med));
    }
}
