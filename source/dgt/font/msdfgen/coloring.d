module dgt.font.msdfgen.coloring;

import dgt.font.msdfgen.arithmetic;
import dgt.font.msdfgen.edges;
import dgt.font.msdfgen.shape;
import dgt.math.vec : FVec2;

void edgeColoringSimple(Shape shape, in float angleThreshold, ulong seed=0) {
    import dgt.math.vec : normalize;
    import std.algorithm : each;
    import std.math : sin;

    const crossThreshold = sin(angleThreshold);

    foreach (ref contour; shape) {

        assert(contour.length);

        // Identify corners
        size_t[] corners;
        {
            auto prevDirection = contour[$-1].seg.direction(1);
            foreach (const i, const edge; contour) {
                if (isCorner(normalize(prevDirection), normalize(edge.seg.direction(0)), crossThreshold)) {
                    corners ~= i;
                }
                prevDirection = edge.seg.direction(1);
            }
        }

        // Smooth contour
        if (!corners.length) {
            foreach (ref e; contour) {
                e.col = EdgeColor.white;
            }
        }
        // "Teardrop" case
        else if (corners.length == 1) {
            EdgeColor[3] colors = [
                EdgeColor.white, EdgeColor.white, EdgeColor.init
            ];
            colors[0] = switchColor(colors[0], seed);
            colors[2] = switchColor(colors[0], seed);

            const corner = corners[0];

            if (contour.length >= 3) {
                const m = contour.length;
                foreach (i; 0 .. m) {
                    contour[(corner+i) % m].col =
                            colors[cast(int)(3 + 2.875*i/(m-1) - 1.4375 + 0.5) - 2];
                }
            }
            // Less than three edge segments for three colors => edges must be split
            else if (contour.length == 1) {
                const segs = contour[0].seg.thirds;
                contour = [
                    Edge(segs[0], colors[0]),
                    Edge(segs[1], colors[1]),
                    Edge(segs[2], colors[2]),
                ];
            }
            else if (contour.length == 2) {
                assert(corner <= 1);
                const segs0 = contour[0].seg.thirds;
                const segs1 = contour[1].seg.thirds;
                const segs = segs0[] ~ segs1[];
                contour = [
                    Edge(segs[0+3*corner], colors[0]),
                    Edge(segs[1+3*corner], colors[0]),
                    Edge(segs[2+3*corner], colors[1]),
                    Edge(segs[3-3*corner], colors[1]),
                    Edge(segs[4-3*corner], colors[2]),
                    Edge(segs[5-3*corner], colors[2]),
                ];
            }
        }
        // Multiple corners
        else {
            auto color = switchColor(EdgeColor.white, seed);
            const initialColor = color;
            const start = corners[0];
            int spline = 0;
            const m = contour.length;
            foreach (i; 0 .. m) {
                const index = (start + i) % m;
                if (spline+1 < corners.length && corners[spline+1] == index) {
                    ++spline;
                    color = switchColor(color, seed,
                            (spline == corners.length-1) ? initialColor : EdgeColor.black);
                }
                contour[index].col = color;
            }
        }
    }
}

private bool isCorner(in FVec2 aDir, in FVec2 bDir, in float crossThreshold) {
    import dgt.math.vec : dot;
    import std.math : abs;
    return dot(aDir, bDir) <= 0 || abs(cross2d(aDir, bDir)) > crossThreshold;
}

private EdgeColor switchColor(in EdgeColor color, ref ulong seed, in EdgeColor banned = EdgeColor.black) {
    const combined = color & banned;
    if (combined == EdgeColor.red || combined == EdgeColor.green || combined == EdgeColor.blue) {
        return combined ^ EdgeColor.white;
    }
    if (color == EdgeColor.black || color == EdgeColor.white) {
        const EdgeColor[3] start = [ EdgeColor.cyan, EdgeColor.magenta, EdgeColor.yellow ];
        const c = start[seed%3];
        seed /= 3;
        return c;
    }
    const shifted = color<<(1+(seed&1));
    const c = (shifted | shifted>>3) & EdgeColor.white;
    seed >>= 1;
    return c;
}
