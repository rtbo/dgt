module dgt.region;

import dgt.geometry;

Region intersect(const(Region) lhs, const(Region)rhs);
Region unite(const(Region) lhs, const(Region)rhs);
Region subtract(const(Region) lhs, const(Region)rhs);

// y-x sorted and banded region, as X11 and pixman.
// Top is lower y and bottom is higher y
class Region
{
    private IRect _extents;
    private IRect[] _rects;

    this() {}

    this(in IRect r)
    {
        _extents = r;
        _rects = [ r ];
    }

    @property bool empty() const
    {
        return _rects.length == 0;
    }

    @property IRect extents() const
    {
        return _extents;
    }

    @property size_t numRects()  const
    {
        return _rects.length;
    }

    @property const(IRect)[] rects() const
    {
        return _rects;
    }

    void assign(in Region oth)
    in {
        assert(oth);
    }
    body
    {
        _extents = oth._extents;
        _rects = oth._rects.dup;
    }

    bool contains(in IPoint p) const {
        if (!_extents.contains!int(p)) return false;
        else if (numRects == 1) return true;

        foreach (ref r; _rects) {
            if (r.contains!int(p)) return true;
        }
        return false;
    }


    /// Merges the current band with the previous one if possible.
    /// The current band must be the last one.
    /// Returns the index of the new last band.
    private size_t coalesce(in size_t prevBand, in size_t curBand)
    in {
        assert(prevBand < _rects.length);
        assert(curBand >= prevBand);
    }
    body
    {
        immutable numRects = curBand-prevBand;
        if (!numRects)
            return curBand;
        if (numRects != _rects.length-curBand)
            return curBand;


        auto prev = _rects[prevBand .. curBand];
        auto cur = _rects[curBand .. $];

        if (prev[0].bottom != cur[0].top)
            return curBand;

        // check if merge is feasible
        foreach (i; 0 .. numRects) {
            if (prev[i].left != cur[i].left ||
                    prev[i].right != cur[i].right)
                return curBand;
        }

        // let's merge
        immutable bottom = cur[0].bottom;
        foreach (ref r; prev)
            r.bottom = bottom;
        _rects = _rects[0 .. curBand];

        return prevBand;
    }

    /// Find a band.
    /// return a slice of the passed rectangles that have the same top as first rect
    private static const(IRect)[] findBand(in IRect[] rects, out int top)
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
    private void appendNonOverlap(in IRect[] rects, in int top, in int bottom)
    {
        _rects.reserve(rects.length);
        foreach (r; rects) {
            _rects ~= IRect(IPoint(r.left, top), IPoint(r.right, bottom));
        }
    }

    private alias OverlapFn = void delegate (const(IRect)[] lband,
                                            const(IRect)[] rband,
                                            int ytop, int ybot);

    /// Generic operator function that compute operation between reg1 and reg2
    /// and store the result into this.
    /// nonOverlap1 and 2 are called for non-overlapping rects of respectively
    /// reg1 and reg2, and overlapFn is called for overlapping region between
    /// both.
    private void operator (const Region reg1, const Region reg2,
                           in bool appendNonO1, in bool appendNonO2,
                           OverlapFn overlapFn)
    {
        import std.algorithm : min, max;
        assert(!reg1.empty);
        assert(!reg2.empty);

        const(IRect)[] r1 = reg1._rects;
        const(IRect)[] r2 = reg2._rects;

        IRect[] oldRects;
        if (reg1 is this && r1.length>1 ||
            reg2 is this && r2.length>1) {
            oldRects = _rects;
        }

        _rects = [];

        immutable newSize = 2 * max(r1.length, r2.length);
        if (newSize > _rects.capacity)
            _rects.reserve(newSize - _rects.capacity);

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
                        immutable curBand = _rects.length;
                        appendNonOverlap(band1, top, bot);
                        prevBand = coalesce(prevBand, curBand);
                    }
                }
                ytop = top2;
            }
            else if (top2 < top1) {
                if (appendNonO2) {
                    immutable top = max(top2, ybot);
                    immutable bot = min(band2[0].bottom, top1);
                    if (bot > top) {
                        immutable curBand = _rects.length;
                        appendNonOverlap(band2, top, bot);
                        prevBand = coalesce(prevBand, curBand);
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
                immutable curBand = _rects.length;
                overlapFn(band1, band2, ytop, ybot);
                prevBand = coalesce(prevBand, curBand);
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
            immutable curBand = _rects.length;
            appendNonOverlap(band, max(top, ybot), band[0].bottom);
            prevBand = coalesce(prevBand, curBand);

            if (band.length < r1.length)
                _rects ~= r1[band.length .. $];
        }

        if (r2.length && appendNonO2) {
            int top;
            const band = findBand(r2, top);
            immutable curBand = _rects.length;
            appendNonOverlap(band, max(top, ybot), band[0].bottom);
            prevBand = coalesce(prevBand, curBand);

            if (band.length < r2.length)
                _rects ~= r2[band.length .. $];
        }

        if (_rects.length == 1) {
            _extents = _rects[0];
        }
        else if (_rects.length) {
            downsize();
        }
    }

    private void downsize()
    {
        if (_rects.capacity > 2 * _rects.length && _rects.length > 50) {
            _rects = _rects.dup; // GC will collect the high capacity one
        }
    }

    private void resetExtents()
    {
        if (_rects.length == 0) {
            _extents = IRect.init;
        }
        else {
            auto ext = _rects[0];
            foreach (r; _rects[1 .. $]) {
                if (r.top < ext.top) ext.top = r.top;
                if (r.bottom > ext.bottom) ext.bottom = r.bottom;
                if (r.left < ext.left) ext.left = r.left;
                if (r.right > ext.right) ext.right = r.right;
            }
            _extents = ext;
        }
    }
}


Region intersect(const(Region) lhs, const(Region)rhs)
{
    import std.algorithm : min, max;

    Region res = new Region;

    if (!lhs || lhs.empty || !rhs || rhs.empty) return res;

    if (lhs.numRects == 1 && rhs.numRects == 1) {
        IRect r = lhs.extents.intersection(rhs.extents);
        res._extents = r;
        res._rects ~= r;
    }
    else if (lhs.numRects == 1 && lhs.extents.contains(rhs.extents)) {
        res.assign(rhs);
    }
    else if (rhs.numRects == 1 && rhs.extents.contains(lhs.extents)) {
        res.assign(lhs);
    }
    else if (lhs is rhs) {
        res.assign(lhs);
    }
    else {
        void intersectOp(const(IRect)[] band1,
                        const(IRect)[] band2,
                        int top, int bot)
        {
            while (band1.length && band2.length) {
                immutable left = max(band1[0].left, band2[0].left);
                immutable right = min(band1[0].right, band2[0].right);
                if (left < right) {
                    res._rects ~= IRect(IPoint(left, top), IPoint(right, bot));
                }
                if (band1[0].right == right)
                    band1 = band1[1 .. $];
                if (band2[0].right == right)
                    band2 = band2[1 .. $];
            }
        }
        res.operator(lhs, rhs, false, false, &intersectOp);
        res.resetExtents();
    }
    return res;
}

unittest
{
    Region reg1 = new Region(IRect(IPoint(2, 3), ISize(5, 4)));
    Region reg2 = new Region(IRect(IPoint(4, 5), ISize(5, 4)));
    Region res = intersect(reg1, reg2);

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

Region unite(const(Region) lhs, const(Region) rhs)
{
    import std.algorithm : min, max;

    Region res = new Region;

    if ((!lhs || lhs.empty) && (!rhs || rhs.empty)) return res;

    if (!lhs || lhs.empty)
    {
        res.assign(rhs);
    }
    else if (!rhs || rhs.empty)
    {
        res.assign(lhs);
    }
    else if (lhs.numRects == 1 && lhs.extents.contains(rhs.extents))
    {
        res.assign(lhs);
    }
    else if (rhs.numRects == 1 && rhs.extents.contains(lhs.extents))
    {
        res.assign(rhs);
    }
    else if (lhs is rhs) {
        res.assign(lhs);
    }
    else {
        void unionOp(const(IRect)[] band1,
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
                    res._rects ~= IRect(IPoint(l, top), IPoint(r, bot));
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

            res._rects ~= IRect(IPoint(l, top), IPoint(r, bot));
        }

        res.operator(lhs, rhs, true, true, &unionOp);
        res._extents.top = min(lhs.extents.top, rhs.extents.top);
        res._extents.bottom = max(lhs.extents.bottom, rhs.extents.bottom);
        res._extents.left = min(lhs.extents.left, rhs.extents.left);
        res._extents.right = max(lhs.extents.right, rhs.extents.right);

    }

    return res;
}


unittest
{
    Region reg1 = new Region(IRect(IPoint(2, 3), ISize(5, 4)));
    Region reg2 = new Region(IRect(IPoint(4, 5), ISize(5, 4)));
    Region res = unite(reg1, reg2);

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


Region subtract(const(Region) lhs, const(Region)rhs)
{
    Region res = new Region;

    if ((!lhs || lhs.empty) && (!rhs || rhs.empty)) return res;

    if (!lhs || lhs.empty) {
        return res;
    }
    else if (!rhs || rhs.empty) {
        res.assign(lhs);
    }
    else if (!lhs.extents.overlaps(rhs.extents)) {
        res.assign(lhs);
    }
    else {

        // implements band1 minus band2
        void subtractOp(const(IRect)[] band1,
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
                    res._rects ~= IRect(IPoint(l, top), IPoint(band2[0].left, bot));
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
                        res._rects ~= IRect(IPoint(l, top), IPoint(band1[0].right, bot));
                    }
                    band1 = band1[1 .. $];
                    if (band1.length) {
                        l = band1[0].left;
                    }
                }
            }

            while (band1.length) {
                res._rects ~= IRect(IPoint(l, top), IPoint(band1[0].right, bot));
                band1 = band1[1 .. $];
                if (band1.length) {
                    l = band1[0].left;
                }
            }
        }

        res.operator(lhs, rhs, true, false, &subtractOp);
        res.resetExtents();
    }

    return res;
}


unittest
{
    Region reg1 = new Region(IRect(IPoint(2, 3), ISize(5, 4)));
    Region reg2 = new Region(IRect(IPoint(4, 5), ISize(5, 4)));
    Region res = subtract(reg1, reg2);

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

