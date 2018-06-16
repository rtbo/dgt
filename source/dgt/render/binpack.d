/// Module that define and implement rectangle bin packing algorithms
/// SeeAlso: https://github.com/juj/RectangleBinPack
module dgt.render.binpack;

import dgt.core.geometry : ISize;


/// Interface that packs rectangles in a rectangular bin using a defined algorithm.
/// The low coordinates X and Y of packed rectangles are respectively left and top.
interface BinPack
{
    import dgt.core.geometry : IRect;

    /// The size of the bin
    @property ISize binSize() const;

    /// Whether the algorithm is allowed, or support the flipping of rectangles
    /// to improve packing efficiency
    @property bool allowFlip() const;

    /// Whether the underlying algorithm support bin extension without repacking all rectangles.
    @property bool extensible() const;

    /// Extends the bin size. Only a size larger in one or the two dimensions
    /// is accepted.
    /// The extension is done without repacking already packed rects.
    void extend(in ISize newBinSize)
    in
    {
        assert(newBinSize.width >= binSize.width && newBinSize.height >= binSize.height);
        assert(newBinSize != binSize);
    }

    /// pack a rectangle of the given size.
    /// Returns: whether the rectangle was succesfully packed or if the bin is full.
    bool pack(in ISize size, out IRect rect);

    /// pack rectangles of the given sizes.
    /// Returns: whether all rectangles could be packed.
    /// If false is returned, rects must be inspected. Rectangles of null area are
    /// the ones that could not be packed.
    /// Rectangles are not necessarily packed in order, so it can't be assumed
    /// that if a rectangle is not packed, the subsequent ones are also not packed.
    bool pack(in ISize[] sizes, ref IRect[] rects);

    /// The occupancy rate of the bin
    @property float occupancy() const;

    /// The rectangles packed in this bin
    @property const(IRect)[] packedRects() const;

    /// Reset the bin to a clear state with binSize size
    void reset(in ISize binSize);
}

/// A bin-pack factory
alias BinPackFactory = BinPack delegate (in ISize size, in bool allowFlip);

BinPackFactory maxRectsBinPackFactory(in MaxRectsBinPack.Heuristic heuristic)
{
    BinPack make (in ISize size, in bool allowFlip) {
        return new MaxRectsBinPack(heuristic, size, allowFlip);
    }
    return &make;
}

// virtual coordinate of rect edges on bin bounds to
// allow resize of bin without repacking all rects
private enum int boundCoord = 1024 * 1024;

/// Maximum rectangles BinPack implementation
class MaxRectsBinPack : BinPack
{
    import dgt.core.geometry : IRect;

    private Heuristic _heuristic;
    private ISize _binSize;
    private bool _allowFlip;
    private IRect[] _freeRects;
    private IRect[] _packedRects;

    /// Heuristic used to place new rectangles
    enum Heuristic
    {
        /// -BSSF: Positions the rectangle against the short side of a free rectangle into which it fits the best.
        bestShortSideFit,
        /// -BLSF: Positions the rectangle against the long side of a free rectangle into which it fits the best.
        bestLongSideFit,
        /// -BAF: Positions the rectangle into the smallest free rect into which it fits.
        bestAreaFit,
        /// Does the Tetris placement. This is originally known as bottom left rule, but
        /// renamed here as the y low coordinates are on the top
        topLeftRule,
        /// -CP: Choosest the placement where the rectangle touches other rects as much as possible.
        contactPointRule
    }

    /// Build a new MaxRects bin packing algorithm
    this(in Heuristic heuristic, in ISize binSize, in bool allowFlip)
    {
        _heuristic = heuristic;
        _binSize = binSize;
        _allowFlip = allowFlip;

        _freeRects ~= IRect(0, 0, boundCoord, boundCoord);
    }

    /// The heuristic used by the algorithm
    @property Heuristic heuristic() const
    {
        return _heuristic;
    }

    override @property ISize binSize() const
    {
        return _binSize;
    }

    override @property bool allowFlip() const
    {
        return _allowFlip;
    }

    override @property bool extensible() const
    {
        return true;
    }

    override void extend(in ISize newBinSize)
    {
        assert(newBinSize.width <= boundCoord && newBinSize.height < boundCoord);
        // nothing to do here
        _binSize = newBinSize;
    }

    override bool pack(in ISize size, out IRect rect)
    {
        // unused in this function
        int score1 = void, score2 = void;

        final switch (_heuristic)
        {
        case Heuristic.bestShortSideFit:
            rect = findPosBestShortSideFit(size, score1, score2);
            break;
        case Heuristic.bestLongSideFit:
            rect = findPosBestLongSideFit(size, score1, score2);
            break;
        case Heuristic.bestAreaFit:
            rect = findPosBestAreaFit(size, score1, score2);
            break;
        case Heuristic.topLeftRule:
            rect = findPosBestTopLeft(size, score1, score2);
            break;
        case Heuristic.contactPointRule:
            rect = findPosContactPoint(size, score1);
            break;
        }

        if (rect.height == 0)
            return false;

        placeRect(rect);

        return true;
    }

    override bool pack(in ISize[] sizes, ref IRect[] rects)
    {
        import std.algorithm : initializeAll;

        rects.length = sizes.length;
        initializeAll(rects);

        auto done = new bool[sizes.length]; // argh! can we avoid this to return ordered rects?
        size_t numDone;

        while (numDone < sizes.length)
        {
            int bestScore1 = int.max;
            int bestScore2 = int.max;
            size_t bestInd = size_t.max;
            IRect bestRect;

            foreach (i, sz; sizes)
            {

                if (done[i])
                    continue;

                int score1 = void, score2 = void;
                const rect = scoreRect(sizes[i], score1, score2);

                if (score1 < bestScore1 || (score1 == bestScore1 && score2 < bestScore2))
                {
                    bestScore1 = score1;
                    bestScore2 = score2;
                    bestInd = i;
                    bestRect = rect;
                }
            }

            if (bestInd == size_t.max)
                return false;

            placeRect(bestRect);
            rects[bestInd] = bestRect;
            done[bestInd] = true;
            ++numDone;
        }

        return true;
    }



    override @property float occupancy() const
    {
        import dgt.core.geometry : area;
        import std.algorithm : map, sum;

        const ulong packedArea = _packedRects
                .map!(r => cast(ulong)r.area)
                .sum();

        return packedArea / cast(float)_binSize.area;
    }

    override @property const(IRect)[] packedRects() const {
        return _packedRects;
    }

    override void reset (in ISize binSize) {
        _binSize = binSize;
        _freeRects = [ IRect(0, 0, boundCoord, boundCoord) ];
        _packedRects = [];
    }

private:

    bool consistentCoords() const
    {
        bool check(in IRect rect) {
            return (rect.right < _binSize.width || rect.right == boundCoord) &&
                   (rect.bottom < _binSize.height || rect.bottom == boundCoord);
        }

        import std.algorithm : all;
        import std.range : chain;

        return _freeRects.chain(_packedRects).all!check();
    }

    bool noCollision() const
    {
        import dgt.core.geometry : overlaps;
        import std.stdio : writeln;

        bool res = true;

        foreach (r1; _freeRects) {
            foreach (r2; _packedRects) {
                if (overlaps(r1, r2)) {
                    writeln(r1, " (free) overlaps with ", r2, " (packed)");
                    res = false;
                }
            }
        }

        foreach (i1, r1; _packedRects) {
            foreach (i2, r2; _packedRects) {
                if (i1 >= i2) continue;
                if (overlaps(r1, r2)) {
                    writeln(r1, " (packed) overlaps with ", r2, " (packed)");
                    res = false;
                }
            }
        }
        return res;
    }

    void placeRect(in IRect rect)
    {
        import std.algorithm : remove, SwapStrategy;

        const numToProcess=_freeRects.length;
        for (size_t i=0; i<numToProcess; ++i) {
            if (splitFreeRect(_freeRects[i], rect)) {
                /// the last rect appended in splitFreeRect comes back to i
                /// and is not checked at the end
                _freeRects = _freeRects.remove!(SwapStrategy.unstable)(i);
            }
        }
        pruneFreeList();
        _packedRects ~= rect;

        assert(consistentCoords, "non consistent coords");
        assert(noCollision, "rect collision");
    }

    IRect scoreRect(in ISize sz, out int score1, out int score2) const
    {
        IRect rect;

        final switch (_heuristic)
        {
        case Heuristic.bestShortSideFit:
            rect = findPosBestShortSideFit(sz, score1, score2);
            break;
        case Heuristic.bestLongSideFit:
            rect = findPosBestLongSideFit(sz, score1, score2);
            break;
        case Heuristic.bestAreaFit:
            rect = findPosBestAreaFit(sz, score1, score2);
            break;
        case Heuristic.topLeftRule:
            rect = findPosBestTopLeft(sz, score1, score2);
            break;
        case Heuristic.contactPointRule:
            rect = findPosContactPoint(sz, score1);
            // for contact rule, bigger is better
            score1 = -score1;
            break;
        }

        if (rect.height == 0)
        {
            // could not pack
            score1 = int.max;
            score2 = int.max;
        }

        return rect;
    }

    IRect actualRect(in IRect r) const {
        return IRect (
            r.point,
            ISize(
                r.right == boundCoord ? _binSize.width - r.left : r.width,
                r.bottom == boundCoord ? _binSize.height - r.top : r.height
            )
        );
    }

    IRect findPosBestTopLeft(in ISize sz, out int bestY, out int bestX) const
    {
        import dgt.core.geometry : contains;
        import std.algorithm : map, max, min;

        IRect bestRect;
        bestX = int.max;
        bestY = int.max;

        const flippedSz = ISize(sz.height, sz.width);

        foreach (fr; _freeRects.map!(r => actualRect(r)))
        {
            // try to place in non-flipped position
            if (fr.size.contains(sz))
            {
                const bottomSide = fr.top + sz.height;
                if (bottomSide < bestY || (bottomSide == bestY && fr.left < bestX))
                {
                    bestRect = IRect(fr.point, sz);
                    bestY = bottomSide;
                    bestX = fr.left;
                }
            }
            if (_allowFlip && fr.size.contains(flippedSz))
            {
                const bottomSide = fr.top + flippedSz.height;
                if (bottomSide < bestY || (bottomSide == bestY && fr.left < bestX))
                {
                    bestRect = IRect(fr.point, flippedSz);
                    bestY = bottomSide;
                    bestX = fr.left;
                }
            }
        }
        return bestRect;
    }

    IRect findPosBestShortSideFit(in ISize sz, out int bestShortSideFit, out int bestLongSideFit) const
    {
        import dgt.core.geometry : contains;
        import std.algorithm : map, max, min;

        IRect bestRect;
        bestShortSideFit = int.max;
        bestLongSideFit = int.max;

        const flippedSz = ISize(sz.height, sz.width);

        foreach (fr; _freeRects.map!(r => actualRect(r)))
        {
            // try to place in non-flipped position
            if (fr.size.contains(sz))
            {
                const leftoverW = fr.width - sz.width;
                const leftoverH = fr.height - sz.height;
                const shortSideFit = min(leftoverW, leftoverH);
                const longSideFit = max(leftoverW, leftoverH);
                if (shortSideFit < bestShortSideFit
                        || (shortSideFit == bestShortSideFit && longSideFit < bestLongSideFit))
                {
                    bestRect = IRect(fr.point, sz);
                    bestShortSideFit = shortSideFit;
                    bestLongSideFit = longSideFit;
                }
            }

            if (_allowFlip && fr.size.contains(flippedSz))
            {
                const leftoverW = fr.width - flippedSz.width;
                const leftoverH = fr.height - flippedSz.height;
                const shortSideFit = min(leftoverW, leftoverH);
                const longSideFit = max(leftoverW, leftoverH);
                if (shortSideFit < bestShortSideFit
                        || (shortSideFit == bestShortSideFit && longSideFit < bestLongSideFit))
                {
                    bestRect = IRect(fr.point, flippedSz);
                    bestShortSideFit = shortSideFit;
                    bestLongSideFit = longSideFit;
                }
            }
        }
        return bestRect;
    }

    IRect findPosBestLongSideFit(in ISize sz, out int bestLongSideFit, out int bestShortSideFit) const
    {
        import dgt.core.geometry : contains;
        import std.algorithm : map, max, min;

        IRect bestRect;
        bestLongSideFit = int.max;
        bestShortSideFit = int.max;

        const flippedSz = ISize(sz.height, sz.width);

        foreach (fr; _freeRects.map!(r => actualRect(r)))
        {
            // try to place in non-flipped position
            if (fr.size.contains(sz))
            {
                const leftoverW = fr.width - sz.width;
                const leftoverH = fr.height - sz.height;
                const shortSideFit = min(leftoverW, leftoverH);
                const longSideFit = max(leftoverW, leftoverH);
                if (longSideFit < bestLongSideFit || (longSideFit == bestLongSideFit
                        && shortSideFit < bestShortSideFit))
                {
                    bestRect = IRect(fr.point, sz);
                    bestShortSideFit = shortSideFit;
                    bestLongSideFit = longSideFit;
                }
            }

            if (_allowFlip && fr.size.contains(flippedSz))
            {
                const leftoverW = fr.width - flippedSz.width;
                const leftoverH = fr.height - flippedSz.height;
                const shortSideFit = min(leftoverW, leftoverH);
                const longSideFit = max(leftoverW, leftoverH);
                if (longSideFit < bestLongSideFit || (longSideFit == bestLongSideFit
                        && shortSideFit < bestShortSideFit))
                {
                    bestRect = IRect(fr.point, flippedSz);
                    bestShortSideFit = shortSideFit;
                    bestLongSideFit = longSideFit;
                }
            }
        }
        return bestRect;
    }

    IRect findPosBestAreaFit(in ISize sz, out int bestAreaFit, out int bestShortSideFit) const
    {
        import dgt.core.geometry : area, contains;
        import std.algorithm : map, max, min;

        IRect bestRect;
        bestShortSideFit = int.max;
        bestAreaFit = int.max;

        const flippedSz = ISize(sz.height, sz.width);

        foreach (fr; _freeRects.map!(r => actualRect(r)))
        {
            if (fr.size.contains(sz))
            {
                const leftoverW = fr.width - sz.width;
                const leftoverH = fr.height - sz.height;
                const areaFit = fr.area - sz.area;
                const shortSideFit = min(leftoverW, leftoverH);

                if (areaFit < bestAreaFit || (areaFit == bestAreaFit
                        && shortSideFit < bestShortSideFit))
                {
                    bestRect = IRect(fr.point, sz);
                    bestAreaFit = areaFit;
                    bestShortSideFit = shortSideFit;
                }
            }

            if (_allowFlip && fr.size.contains(flippedSz))
            {
                const leftoverW = fr.width - flippedSz.width;
                const leftoverH = fr.height - flippedSz.height;
                const areaFit = fr.area - sz.area;
                const shortSideFit = min(leftoverW, leftoverH);

                if (areaFit < bestAreaFit || (areaFit == bestAreaFit
                        && shortSideFit < bestShortSideFit))
                {
                    bestRect = IRect(fr.point, flippedSz);
                    bestAreaFit = areaFit;
                    bestShortSideFit = shortSideFit;
                }
            }
        }
        return bestRect;
    }

    static int commonIntervalLength(in int i1start, in int i1end, in int i2start, in int i2end)
    {
        import std.algorithm : max, min;

        if (i1start > i2end || i2start > i1end)
            return 0;
        return min(i1end, i2end) - max(i1start, i2start);
    }

    int contactPointScore(in IRect rect) const
    {
        int score;
        if (rect.x == 0 || rect.right == _binSize.width)
        {
            score += rect.height;
        }
        if (rect.y == 0 || rect.bottom == _binSize.height)
        {
            score += rect.width;
        }
        foreach (pr; _packedRects)
        {
            if (pr.x == rect.right || pr.right == rect.x)
            {
                score += commonIntervalLength(pr.y, pr.bottom, rect.y, rect.bottom);
            }
            if (pr.y == rect.bottom || pr.bottom == rect.y)
            {
                score += commonIntervalLength(pr.x, pr.right, rect.x, rect.right);
            }
        }
        return score;
    }

    IRect findPosContactPoint(in ISize sz, out int bestContactScore) const
    {
        import dgt.core.geometry : area, contains;
        import std.algorithm : map, max, min;

        IRect bestRect;
        bestContactScore = -1;

        const flippedSz = ISize(sz.height, sz.width);

        foreach (fr; _freeRects.map!(r => actualRect(r)))
        {
            if (fr.size.contains(sz))
            {
                const r = IRect(fr.point, sz);
                const score = contactPointScore(r);

                if (score > bestContactScore)
                {
                    bestRect = r;
                    bestContactScore = score;
                }
            }

            if (_allowFlip && fr.size.contains(flippedSz))
            {
                const r = IRect(fr.point, flippedSz);
                const score = contactPointScore(r);

                if (score > bestContactScore)
                {
                    bestRect = r;
                    bestContactScore = score;
                }
            }
        }
        return bestRect;
    }

    bool splitFreeRect(in IRect freeRect, in IRect rect)
    {
        import dgt.core.geometry : overlaps;

        if (!freeRect.overlaps(rect))
            return false;

        if (rect.top > freeRect.top)
        {
            // top side of freeRect is still free
            IRect newRect = freeRect;
            newRect.height = rect.top - freeRect.top;
            _freeRects ~= newRect;
        }

        if (rect.bottom < freeRect.bottom)
        {
            // bottom side of freeRect is still free
            IRect newRect = freeRect;
            newRect.y = rect.bottom;
            newRect.height = freeRect.bottom - rect.bottom;
            _freeRects ~= newRect;
        }

        if (rect.left > freeRect.left)
        {
            // left side of freeRect is still free
            IRect newRect = freeRect;
            newRect.width = rect.left - freeRect.left;
            _freeRects ~= newRect;
        }

        if (rect.right < freeRect.right)
        {
            // right side of freeRect is still free
            IRect newRect = freeRect;
            newRect.x = rect.right;
            newRect.width = freeRect.right - rect.right;
            _freeRects ~= newRect;
        }

        return true;
    }

    void pruneFreeList()
    {
        import dgt.core.geometry : contains;
        import std.algorithm : remove, SwapStrategy;

        for (size_t i = 0; i < _freeRects.length; ++i)
        {
            for (size_t j = i+1; j < _freeRects.length; ++j)
            {
                if (_freeRects[j].contains(_freeRects[i]))
                {
                    _freeRects = _freeRects.remove!(SwapStrategy.unstable)(i);
                    --i;
                    break;
                }
                if (_freeRects[i].contains(_freeRects[j]))
                {
                    _freeRects = _freeRects.remove!(SwapStrategy.unstable)(j);
                    --j;
                }
            }
        }
    }
}
