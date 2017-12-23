/// Shape is a vector outline, that can hold several contours
module dgt.font.msdfgen.shape;

import dgt.font.msdfgen.edges;
import dgt.math.vec : FVec2;

// TODO: use a more general path implementation, such the one
// from dgt's master branch: dgt.vg.path

enum EdgeColor : int {
    black = 0,
    red = 1,
    green = 2,
    yellow = 3,
    blue = 4,
    magenta = 5,
    cyan = 6,
    white = 7
};

struct Edge {
    immutable(EdgeSegment) seg;
    EdgeColor col = EdgeColor.white;

    this (immutable EdgeSegment seg) {
        assert(seg);
        this.seg = seg;
        this.col = EdgeColor.white;
    }

    this (immutable EdgeSegment seg, in EdgeColor col) {
        assert(seg);
        this.seg = seg;
        this.col = col;
    }
}

alias Contour = Edge[];

void bounds(in Contour contour, ref float l, ref float b, ref float r, ref float t)
{
    import std.algorithm : each;
    contour.each!(e => e.seg.bounds(l, b, r, t));
}

enum Winding {
    undetermined,
    positive, negative,
}

@property Winding opposite(in Winding winding) {
    final switch (winding) {
        case Winding.undetermined : return Winding.undetermined;
        case Winding.positive : return Winding.negative;
        case Winding.negative : return Winding.positive;
    }
}

@property bool positive(in Winding winding) {
    return winding == Winding.positive;
}

@property bool negative(in Winding winding) {
    return winding == Winding.negative;
}

private float shoelace(in FVec2 a, in FVec2 b) {
    return (b.x-a.x)*(a.y+b.y);
}

@property Winding winding (in Contour contour) {
    if (contour.length == 0)
        return Winding.undetermined;
    float total = 0;
    if (contour.length == 1) {
        const a = contour[0].seg.point(0);
        const b = contour[0].seg.point(1/3.);
        const c = contour[0].seg.point(2/3.);
        total += shoelace(a, b);
        total += shoelace(b, c);
        total += shoelace(c, a);
    }
    else if (contour.length == 2) {
        const a = contour[0].seg.point(0);
        const b = contour[0].seg.point(.5);
        const c = contour[1].seg.point(0);
        const d = contour[1].seg.point(.5);
        total += shoelace(a, b);
        total += shoelace(b, c);
        total += shoelace(c, d);
        total += shoelace(d, a);
    }
    else {
        auto prev = contour[$-1].seg.point(0);
        foreach (const edge; contour) {
            const cur = edge.seg.point(0);
            total += shoelace(prev, cur);
            prev = cur;
        }
    }
    if (total > 0) {
        return Winding.positive;
    }
    else if (total < 0) {
        return Winding.negative;
    }
    else {
        return Winding.undetermined;
    }
}

alias Shape = Contour[];


void normalize(ref Shape shape) {
    foreach (ref contour; shape) {
        if (contour.length == 1) {
            import std.algorithm : map;
            import std.array : array;

            const edge = contour[0];
            const thirds = edge.seg.thirds;
            contour = thirds[].map!(s => Edge(s, edge.col)).array;
        }
    }
}

@property bool valid(in Shape shape) {
    import std.algorithm : filter;
    foreach (const contour; shape.filter!(c => c.length != 0)) {
        auto corner = contour[$-1].seg.point(1);
        foreach (const edge; contour[0 .. $-1]) {
            if (edge.seg.point(0) != corner) return false;
            corner = edge.seg.point(1);
        }
        if (contour[$-1].seg.point(0) != corner) return false;
    }
    return true;
}

void bounds(in Shape shape, ref float l, ref float b, ref float r, ref float t)
{
    import std.algorithm : each;
    shape.each!(c => c.bounds(l, b, r, t));
}
