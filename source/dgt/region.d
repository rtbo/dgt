/// Screen region manipulation.
module dgt.region;

import dgt.geometry;

import std.exception : assumeUnique;
import std.range;

/// An immutable screen region.
alias Region = immutable(_Region);

Region intersect(in Region lhs, in Region rhs);
Region unite(in Region lhs, in Region rhs);
Region subtract(in Region lhs, in Region rhs);

// y-x sorted and banded region, as X11 and pixman.
// Top is lower y and bottom is higher y
struct _Region
{
    private IRect _extents;
    private IRect[] _rects;

    immutable this(in IRect r)
    {
        _extents = r;
        _rects = [ r ];
    }

    private immutable this(IRect extents, immutable(IRect)[] rects)
    {
        _extents = extents;
        _rects = rects;
    }

    @property bool empty() const
    {
        return _rects.length == 0;
    }

    @property IRect extents() const
    {
        return _extents;
    }

    @property const(IRect)[] rects() const
    {
        return _rects;
    }

    bool contains(in IPoint p) const {
        if (!_extents.contains!int(p)) return false;
        else if (rects.length == 1) return true;

        foreach (ref r; _rects) {
            if (r.contains!int(p)) return true;
        }
        return false;
    }
}


Region intersect(in Region lhs, in Region rhs)
{
    import std.algorithm : min, max;

    if (lhs.empty || rhs.empty) {
        return Region.init;
    }
    else if (lhs._rects.length == 1 && rhs._rects.length == 1) {
        immutable r = lhs.extents.intersection(rhs.extents);
        return Region(r);
    }
    else if (lhs._rects.length == 1 && lhs.extents.contains(rhs.extents)) {
        return rhs;
    }
    else if (rhs._rects.length == 1 && rhs.extents.contains(lhs.extents)) {
        return lhs;
    }
    else if (lhs._rects is rhs._rects) {
        return lhs;
    }
    else {
        void intersectOp(ref IRect[] rects,
                        const(IRect)[] band1,
                        const(IRect)[] band2,
                        int top, int bot)
        {
            while (band1.length && band2.length) {
                immutable left = max(band1[0].left, band2[0].left);
                immutable right = min(band1[0].right, band2[0].right);
                if (left < right) {
                    rects ~= IRect(IPoint(left, top), IPoint(right, bot));
                }
                if (band1[0].right == right)
                    band1 = band1[1 .. $];
                if (band2[0].right == right)
                    band2 = band2[1 .. $];
            }
        }
        immutable rects = assumeUnique(
            operator(lhs.rects, rhs.rects, false, false, &intersectOp)
        );
        immutable extents = computeExtents(rects);
        return Region(extents, rects);
    }
}

unittest
{
    immutable reg1 = Region(IRect(IPoint(2, 3), ISize(5, 4)));
    immutable reg2 = Region(IRect(IPoint(4, 5), ISize(5, 4)));
    immutable res = intersect(reg1, reg2);

    assert( ! res.contains(IPoint(3, 4))  );
    assert( ! res.contains(IPoint(5, 4))  );
    assert( ! res.contains(IPoint(8, 4))  );
    assert( ! res.contains(IPoint(3, 6))  );
    assert(   res.contains(IPoint(5, 6))  );
    assert( ! res.contains(IPoint(8, 6))  );
    assert( ! res.contains(IPoint(3, 8))  );
    assert( ! res.contains(IPoint(5, 8))  );
    assert( ! res.contains(IPoint(8, 8))  );
}

Region unite(in Region lhs, in Region rhs)
{
    import std.algorithm : min, max;

    if (lhs.empty && rhs.empty) {
        return Region.init;
    }
    else if (lhs.empty) {
        return rhs;
    }
    else if (rhs.empty) {
        return lhs;
    }
    else if (lhs._rects.length == 1 && lhs.extents.contains(rhs.extents)) {
        return lhs;
    }
    else if (rhs._rects.length == 1 && rhs.extents.contains(lhs.extents)) {
        return rhs;
    }
    else if (lhs.rects is rhs.rects) {
        return lhs;
    }
    else {
        void unionOp(ref IRect[] rects,
                     const(IRect)[] band1,
                     const(IRect)[] band2,
                     int top, int bot)
        {
            assert(band1.length && band2.length);
            assert(top < bot);

            int l=void, r=void;

            if (band1[0].left < band2[0].left) {
                l = band1[0].left;
                r = band1[0].right;
                band1 = band1[1 .. $];
            }
            else {
                l = band2[0].left;
                r = band2[0].right;
                band2 = band2[1 .. $];
            }

            const(IRect)[] mergeRect(const(IRect)[] band)
            {
                if (band[0].left <= r) {
                    if (r < band[0].right)
                        r = band[0].right;
                }
                else {
                    rects ~= IRect(IPoint(l, top), IPoint(r, bot));
                }
                return band[1 .. $];
            }

            while (band1.length && band2.length) {
                if (band1[0].left < band2[0].left) {
                    band1 = mergeRect(band1);
                }
                else {
                    band2 = mergeRect(band2);
                }
            }

            while (band1.length)
                band1 = mergeRect(band1);

            while (band2.length)
                band2 = mergeRect(band2);

            rects ~= IRect(IPoint(l, top), IPoint(r, bot));
        }

        immutable rects = assumeUnique (
            operator(lhs.rects, rhs.rects, true, true, &unionOp)
        );
        IRect extents = void;
        extents.top = min(lhs.extents.top, rhs.extents.top);
        extents.bottom = max(lhs.extents.bottom, rhs.extents.bottom);
        extents.left = min(lhs.extents.left, rhs.extents.left);
        extents.right = max(lhs.extents.right, rhs.extents.right);
        return Region(extents, rects);
    }
}


unittest
{
    immutable reg1 = Region(IRect(IPoint(2, 3), ISize(5, 4)));
    immutable reg2 = Region(IRect(IPoint(4, 5), ISize(5, 4)));
    immutable res = unite(reg1, reg2);

    assert(   res.contains(IPoint(3, 4))  );
    assert(   res.contains(IPoint(5, 4))  );
    assert( ! res.contains(IPoint(8, 4))  );
    assert(   res.contains(IPoint(3, 6))  );
    assert(   res.contains(IPoint(5, 6))  );
    assert(   res.contains(IPoint(8, 6))  );
    assert( ! res.contains(IPoint(3, 8))  );
    assert(   res.contains(IPoint(5, 8))  );
    assert(   res.contains(IPoint(8, 8))  );
}


Region subtract(in Region lhs, in Region rhs)
{
    if (lhs.empty && rhs.empty) {
        return Region.init;
    }
    else if (lhs.empty) {
        return Region.init;
    }
    else if (rhs.empty) {
        return lhs;
    }
    else if (!lhs.extents.overlaps(rhs.extents)) {
        return lhs;
    }
    else {

        // implements band1 minus band2
        void subtractOp(ref IRect[] rects,
                        const(IRect)[] band1,
                        const(IRect)[] band2,
                        int top, int bot)
        {
            auto l = band1[0].left;
            while(band1.length && band2.length) {
                if (band2[0].right <= l) {
                    // band2 is completely left of band1
                    band2 = band2[1 .. $];
                }
                else if (band2[0].left <= l) {
                    // band2 precedes band1
                    l = band2[0].right;
                    if (l >= band1[0].right) {
                        // band1 is completely covered
                        band1 = band1[1 .. $];
                        if (band1.length) {
                            l = band1[0].left;
                        }
                    }
                    else {
                        // band2 does not extend beyond band1
                        band2 = band2[1 .. $];
                    }
                }
                else if (band2[0].left < band1[0].right) {
                    assert(l < band2[0].left);
                    rects ~= IRect(IPoint(l, top), IPoint(band2[0].left, bot));
                    l = band2[0].right;
                    if (l >= band1[0].right) {
                        band1 = band1[1 .. $];
                        if (band1.length) {
                            l = band1[0].left;
                        }
                    }
                    else {
                        band2 = band2[1 .. $];
                    }
                }
                else {
                    if (band1[0].right > l) {
                        rects ~= IRect(IPoint(l, top), IPoint(band1[0].right, bot));
                    }
                    band1 = band1[1 .. $];
                    if (band1.length) {
                        l = band1[0].left;
                    }
                }
            }

            while (band1.length) {
                rects ~= IRect(IPoint(l, top), IPoint(band1[0].right, bot));
                band1 = band1[1 .. $];
                if (band1.length) {
                    l = band1[0].left;
                }
            }
        }

        immutable rects = assumeUnique (
            operator(lhs.rects, rhs.rects, true, false, &subtractOp)
        );
        immutable extents = rects.computeExtents();
        return Region(extents, rects);
    }
}


unittest
{
    immutable reg1 = Region(IRect(IPoint(2, 3), ISize(5, 4)));
    immutable reg2 = Region(IRect(IPoint(4, 5), ISize(5, 4)));
    immutable res = subtract(reg1, reg2);

    assert(   res.contains(IPoint(3, 4))  );
    assert(   res.contains(IPoint(5, 4))  );
    assert( ! res.contains(IPoint(8, 4))  );
    assert(   res.contains(IPoint(3, 6))  );
    assert( ! res.contains(IPoint(5, 6))  );
    assert( ! res.contains(IPoint(8, 6))  );
    assert( ! res.contains(IPoint(3, 8))  );
    assert( ! res.contains(IPoint(5, 8))  );
    assert( ! res.contains(IPoint(8, 8))  );
}

private:

/// Merges the current band with the previous one if possible.
/// The current band must be the last one.
/// Returns the index of the new last band.
size_t coalesce(ref IRect[] rects, in size_t prevBand, in size_t curBand)
in {
    assert(prevBand < rects.length);
    assert(curBand >= prevBand);
}
body
{
    immutable numRects = curBand-prevBand;
    if (!numRects)
        return curBand;
    if (numRects != numRects-curBand)
        return curBand;


    auto prev = rects[prevBand .. curBand];
    auto cur = rects[curBand .. $];

    if (prev[0].bottom != cur[0].top)
        return curBand;

    // check if merge is feasible
    foreach (i; 0 .. rects.length) {
        if (prev[i].left != cur[i].left ||
                prev[i].right != cur[i].right)
            return curBand;
    }

    // let's merge
    immutable bottom = cur[0].bottom;
    foreach (ref r; prev)
        r.bottom = bottom;
    rects = rects[0 .. curBand];

    return prevBand;
}

/// Find a band.
/// return a slice of the passed rectangles that have the same top as first rect
const(IRect)[] findBand(in IRect[] rects, out int top)
in {
    assert(rects.length > 0);
}
body
{
    top = rects[0].top;
    size_t right = 1;
    while (right < rects.length && rects[right].top == top)
        ++right;
    return rects[0 .. right];
}


/// Append rects, band-clipped between top and bottom
void appendNonOverlap(ref IRect[] rects, in IRect[] addedRects,
                                in int top, in int bottom)
{
    rects.reserve(addedRects.length);
    foreach (r; addedRects) {
        rects ~= IRect(IPoint(r.left, top), IPoint(r.right, bottom));
    }
}

alias OverlapFn = void delegate (ref IRect[] rects,
                                const(IRect)[] lband,
                                const(IRect)[] rband,
                                int ytop, int ybot);

/// Generic operator function that compute operation between reg1 and reg2
/// and store the result into this.
/// nonOverlap1 and 2 are called for non-overlapping rects of respectively
/// reg1 and reg2, and overlapFn is called for overlapping region between
/// both.
IRect[] operator (const(IRect)[] r1, const(IRect)[] r2,
                in bool appendNonO1, in bool appendNonO2,
                OverlapFn overlapFn)
{
    import std.algorithm : min, max;
    assert(!r1.empty);
    assert(!r2.empty);

    IRect[] rects;
    rects.reserve(r1.length + r2.length);

    // for overlapping bands:
    //   ybot and ytop clip the band
    // for non-overlapping bands:
    //   ybot is the bottom of previous region (clips the top) and ytop
    //   is the top of the next one (clips the bottom)
    int ybot = min(r1[0].top, r2[0].top);
    int ytop = 0;

    size_t prevBand = 0;

    while(r1.length && r2.length)
    {
        int top1, top2;
        const band1 = findBand(r1, top1);
        const band2 = findBand(r2, top2);

        if (top1 < top2) {
            if (appendNonO1) {
                immutable top = max(top1, ybot);
                immutable bot = min(band1[0].bottom, top2);
                if (bot > top) {
                    immutable curBand = rects.length;
                    appendNonOverlap(rects, band1, top, bot);
                    prevBand = coalesce(rects, prevBand, curBand);
                }
            }
            ytop = top2;
        }
        else if (top2 < top1) {
            if (appendNonO2) {
                immutable top = max(top2, ybot);
                immutable bot = min(band2[0].bottom, top1);
                if (bot > top) {
                    immutable curBand = rects.length;
                    appendNonOverlap(rects, band2, top, bot);
                    prevBand = coalesce(rects, prevBand, curBand);
                }
            }
            ytop = top1;
        }
        else {
            ytop = top1;
        }

        ybot = min(band1[0].bottom, band2[0].bottom);
        if (ybot > ytop) {
            // handle overlapping band
            immutable curBand = rects.length;
            overlapFn(rects, band1, band2, ytop, ybot);
            prevBand = coalesce(rects, prevBand, curBand);
        }

        if (band1[0].bottom == ybot)
            r1 = r1[band1.length .. $];
        if (band2[0].bottom == ybot)
            r2 = r2[band2.length .. $];
    }

    // handle remaining bands
    // for the first remaining band, ybot is still relevant, but not for the followings
    if (r1.length && appendNonO1) {
        int top;
        const band = findBand(r1, top);
        immutable curBand = rects.length;
        appendNonOverlap(rects, band, max(top, ybot), band[0].bottom);
        prevBand = coalesce(rects, prevBand, curBand);

        if (band.length < r1.length)
            rects ~= r1[band.length .. $];
    }

    if (r2.length && appendNonO2) {
        int top;
        const band = findBand(r2, top);
        immutable curBand = rects.length;
        appendNonOverlap(rects, band, max(top, ybot), band[0].bottom);
        prevBand = coalesce(rects, prevBand, curBand);

        if (band.length < r2.length)
            rects ~= r2[band.length .. $];
    }
    return downsize(rects);
}

IRect[] downsize(IRect[] rects)
{
    if (rects.capacity > 2 * rects.length && rects.length > 50) {
        return rects.dup; // let GC collect the high capacity one
    }
    else {
        return rects;
    }
}

IRect computeExtents(in IRect[] rects)
{
    if (rects.length == 0) {
        return IRect.init;
    }
    else {
        IRect ext = rects[0];
        foreach (r; rects[1 .. $]) {
            if (r.top < ext.top) ext.top = r.top;
            if (r.bottom > ext.bottom) ext.bottom = r.bottom;
            if (r.left < ext.left) ext.left = r.left;
            if (r.right > ext.right) ext.right = r.right;
        }
        return ext;
    }
}



