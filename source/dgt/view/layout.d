/// layout module
module dgt.view.layout;

import dgt.enums;
import dgt.geometry;
import dgt.math;
import dgt.view.view;

import gfx.foundation.typecons;

import std.exception;
import std.experimental.logger;


/// Specifies how a widget should measure itself
struct MeasureSpec
{
    enum {
        /// widget should measure its content
        unspecified,
        /// widget should measure its content bounded to the given size
        atMost,
        /// widget should assign its measurement to the given size regardless of its content
        exactly,
    }

    int mode;
    float size;

    this (int mode, float size) pure {
        this.mode = mode;
        this.size = size;
    }

    /// make an unspecified spec
    static MeasureSpec makeUnspecified(in float size=0f) pure {
        return MeasureSpec(unspecified, size);
    }

    /// make an atMost spec
    static MeasureSpec makeAtMost(in float size) pure {
        return MeasureSpec(atMost, size);
    }

    /// make an exactly spec
    static MeasureSpec makeExactly(in float size) pure {
        return MeasureSpec(exactly, size);
    }
}

/// Describe how ui elements should be placed and stretched when there is additional space
/// This enum treats gravity in both axis
enum Gravity {
    /// No gravity applied
    none            = 0x00,
    /// Content should be centered within container
    centerBit       = 0x01,
    /// State how left and top edge should be placed
    pullBeforeBit   = 0x02,
    /// State how right and bottom edge should be placed
    pullAfterBit    = 0x04,
    /// Whether the right and bottom edge should be clipped to the container
    clipBit         = 0x08,

    /// Mask for the gravity of one axis
    mask            = 0x0f,
    /// ditto
    horMask         = 0x0f,
    /// ditto
    verMask         = 0xf0,

    /// Shift value to apply to get the the horizontal gravity
    horShift        = 0,
    /// Shift value to apply to get the the horizontal gravity
    verShift        = 4,

    /// whether top edge should fit the parent
    left            = pullBeforeBit << horShift,
    /// whether top edge should fit the parent
    top             = pullBeforeBit << verShift,
    /// whether top edge should fit the parent
    right           = pullAfterBit << horShift,
    /// whether top edge should fit the parent
    bottom          = pullAfterBit << verShift,

    /// whether the child should be centered horizontally
    centerHor       = centerBit << horShift,
    /// whether the child should be centered vertically
    centerVer       = centerBit << verShift,
    /// whether the child should be centered on both axis
    center          = centerHor | centerVer,

    /// whether the child should be filled horizontally
    fillHor         = left | right,
    /// whether the child should be filled vertically
    fillVer         = top | bottom,
    /// whether the child should be filled on both axis
    fill            = fillHor | fillVer,

    /// whether the child should be clipped horizontally
    clipHor         = clipBit << horShift,
    /// whether the child should be clipped vertically
    clipVer         = clipBit << verShift,
    /// whether the child should be clipped on both axis
    clip            = clipHor | clipVer,
}


/// Treats gravity in one axis
enum AxisGravity
{
    none            = 0x00,

    center          = 0x01,
    pullBefore      = 0x02,
    pullAfter       = 0x04,
    clip            = 0x08,

    mask            = 0x0f,

    fill            = pullBefore | pullAfter,
}

/// Extract horizontal gravity
@property AxisGravity horizontal(in Gravity grav) pure
{
    return cast(AxisGravity)(grav & Gravity.horMask);
}
/// Extract vertical gravity
@property AxisGravity vertical(in Gravity grav) pure
{
    return cast(AxisGravity)((grav >> Gravity.verShift) & Gravity.mask);
}
/// Extract gravity for the orientation given
AxisGravity extract(in Gravity gravity, in Orientation orientation) pure
{
    return orientation.isHorizontal ? gravity.horizontal : gravity.vertical;
}

/// Implemented by layout params that have a gravity field.
interface HasGravity
{
    @property Gravity gravity();
    @property void gravity(in Gravity gravity);
}

/// Special value for Layout.Params.width and height.
enum float wrapContent = -1f;
/// ditto
enum float matchParent = -2f;

/// general layout class
class Layout : View
{
    /// Params attached to each view for use with their parent
    static class Params {
        /// Either an actual dimension in pixels, or special values wrapContent or matchParent
        float width     = wrapContent;
        /// Either an actual dimension in pixels, or special values wrapContent or matchParent
        float height    = wrapContent;
    }

    /// Build a new layout
    this() {}

    public override void appendChild(View view)
    {
        ensureLayout(view);
        super.appendChild(view);
    }

    public override void prependChild(View view)
    {
        ensureLayout(view);
        super.prependChild(view);
    }

    public override void insertChildBefore(View view, View child)
    {
        ensureLayout(view);
        super.insertChildBefore(view, child);
    }

    public override void removeChild(View view)
    {
        super.removeChild(view);
    }

    /// Ensure that this child has layout params and that they are compatible
    /// with this layout. If not, default params are assigned.
    protected void ensureLayout(View child)
    {
        if (!child.style.layoutParams) {
            child.style.layoutParams = new Layout.Params;
        }
    }

    /// Ask a child to measure itself taking into account the measureSpecs
    /// given to this layout, the padding and the size that have been consumed
    /// by other children.
    protected void measureChild(View child, in MeasureSpec parentWidthSpec,
                                in MeasureSpec parentHeightSpec,
                                in float usedWidth=0f, in float usedHeight=0f)
    {
        auto lp = cast(Layout.Params)child.style.layoutParams;

        immutable ws = childMeasureSpec(parentWidthSpec,
                    padding.left+padding.right+usedWidth, lp.width);
        immutable hs = childMeasureSpec(parentHeightSpec,
                    padding.top+padding.bottom+usedHeight, lp.height);

        child.measure(ws, hs);
    }
}


/// layout its children in a linear way
class LinearLayout : Layout
{
    /// Params for linear layout
    final static class Params : Layout.Params, HasGravity
    {
        /// Specify how much of the layout extra space will be allocated
        /// to a child
        float weight    = 0f;

        /// Specify a possible per-child override for where to attach the child
        /// the orthogonal direction of this layout
        override @property Gravity gravity()
        {
            return _gravity;
        }
        /// ditto
        override @property void gravity(in Gravity gravity)
        {
            _gravity = gravity;
        }

        /// Build a default value
        this() {}

        /// Build a value from an existing object of type Layout.Params
        this(Layout.Params params)
        {
            this.width = params.width;
            this.height = params.height;
        }

        private Gravity _gravity = Gravity.none;
    }

    /// Build a new linear layout
    this() {}

    override protected void ensureLayout(View view) {
        auto llp = cast(Params)view.style.layoutParams;
        if (!llp) {
            auto lp = cast(Layout.Params)view.style.layoutParams;
            if (lp) view.style.layoutParams = new Params(lp);
            else view.style.layoutParams = new Params;
        }
    }

    /// The orientation of the layout.
    @property Orientation orientation() const
    {
        return _orientation;
    }

    /// ditto
    @property void orientation(in Orientation orientation)
    {
        _orientation = orientation;
    }

    /// ditto
    @property bool isHorizontal() const
    {
        return _orientation.isHorizontal;
    }

    /// ditto
    @property bool isVertical() const
    {
        return _orientation.isVertical;
    }

    /// ditto
    void setHorizontal()
    {
        _orientation = Orientation.horizontal;
    }

    /// ditto
    void setVertical()
    {
        _orientation = Orientation.vertical;
    }

    @property Gravity gravity() const
    {
        return _gravity;
    }

    /// ditto
    @property void gravity(in Gravity gravity)
    {
        _gravity = gravity;
    }

    /// The spacing between the elements of this layout.
    @property float spacing() const
    {
        return _spacing;
    }

    /// ditto
    @property void spacing(in float spacing)
    {
        _spacing = spacing;
    }

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        if (isVertical) measureVertical(widthSpec, heightSpec);
        else measureHorizontal(widthSpec, heightSpec);
    }

    private void measureVertical(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        import dgt.math.approx : approxUlpAndAbs;
        import std.algorithm : max;
        import std.range : enumerate;

        float totalHeight = 0;
        float largestWidth = 0;
        float totalWeight = 0;

        // compute vertical space that all children want to have
        foreach(i, c; enumerate(children)) {
            if (i != 0) totalHeight += spacing;

            measureChild(c, widthSpec, heightSpec, 0f, totalHeight);
            totalHeight += c.measurement.height;
            largestWidth = max(largestWidth, c.measurement.width);

            auto lp = cast(Params)style.layoutParams;
            if (lp) totalWeight += lp.weight;
        }
        totalHeight += padding.top + padding.bottom;

        bool wTooSmall, hTooSmall;
        immutable finalHeight = resolveSize(totalHeight, heightSpec, hTooSmall);
        auto remainExcess = finalHeight - totalHeight;
        enum pixelTol = 0.1f;
        // share remain excess (positive or negative) between all weighted children
        if (!approxUlpAndAbs(remainExcess, 0f, pixelTol) && totalWeight > 0f) {
            totalHeight = 0f;
            foreach(c; children) {
                auto lp = cast(LinearLayout.Params)style.layoutParams;
                immutable weight = lp ? lp.weight : 0f;
                if (weight > 0f) {
                    immutable share = remainExcess * weight / totalWeight;
                    totalWeight -= weight;
                    remainExcess -= share;
                    immutable childHeight = c.measurement.height + share;
                    immutable childHeightSpec = MeasureSpec.makeExactly(childHeight);
                    immutable childWidthSpec = childMeasureSpec(widthSpec, padding.left + padding.right, lp.width);
                    c.measure(childHeightSpec, childWidthSpec);
                }
                totalHeight += c.measurement.height;
                largestWidth = max(largestWidth, c.measurement.width);
            }
            totalHeight += padding.top + padding.bottom;
        }

        largestWidth += padding.left + padding.right;
        measurement = FSize(
            resolveSize(largestWidth, widthSpec, wTooSmall),
            resolveSize(totalHeight, heightSpec, hTooSmall),
        );
        if (wTooSmall || hTooSmall) {
            warningf("layout too small for '%s'", name);
        }

        _totalLength = totalHeight;
    }

    private void measureHorizontal(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        import dgt.math.approx : approxUlpAndAbs;
        import std.algorithm : max;
        import std.range : enumerate;

        float totalWidth = 0;
        float largestHeight = 0;
        float totalWeight = 0;

        // compute horizontal space that all children want to have
        foreach(i, c; enumerate(children)) {
            if (i != 0) totalWidth += spacing;

            measureChild(c, widthSpec, heightSpec, totalWidth, 0f);
            totalWidth += c.measurement.width;
            largestHeight = max(largestHeight, c.measurement.height);

            auto lp = cast(LinearLayout.Params)style.layoutParams;
            if (lp) totalWeight += lp.weight;
        }
        totalWidth += padding.left + padding.right;

        bool wTooSmall, hTooSmall;
        immutable finalWidth = resolveSize(totalWidth, widthSpec, wTooSmall);
        auto remainExcess = finalWidth - totalWidth;
        enum pixelTol = 0.1f;
        // share remain excess (positive or negative) between all weighted children
        if (!approxUlpAndAbs(remainExcess, 0f, pixelTol) && totalWeight > 0f) {
            totalWidth = 0f;
            foreach(c; children) {
                auto lp = cast(Params)style.layoutParams;
                immutable weight = lp ? lp.weight : 0f;
                if (weight > 0f) {
                    immutable share = remainExcess * weight / totalWeight;
                    totalWeight -= weight;
                    remainExcess -= share;
                    immutable childWidth = c.measurement.height + share;
                    immutable childWidthSpec = MeasureSpec.makeExactly(childWidth);
                    immutable childHeightSpec = childMeasureSpec(heightSpec, padding.top + padding.bottom, lp.height);
                    c.measure(childWidthSpec, childHeightSpec);
                }
                totalWidth += c.measurement.width;
                largestHeight = max(largestHeight, c.measurement.height);
            }
            totalWidth += padding.left + padding.right;
        }

        largestHeight += padding.top + padding.bottom;
        measurement = FSize(
            resolveSize(totalWidth, widthSpec, wTooSmall),
            resolveSize(largestHeight, heightSpec, hTooSmall),
        );
        if (wTooSmall || hTooSmall) {
            warningf("layout too small for '%s'", name);
        }

        _totalLength = totalWidth;
    }

    override void layout(in FRect rect)
    {
        if (isVertical) layoutVertical(rect);
        else layoutHorizontal(rect);
        this.rect = rect;
    }

    private void layoutVertical(in FRect rect)
    {
        import std.range : enumerate;

        immutable childRight = rect.width - padding.right;
        immutable childSpace = rect.width - padding.right - padding.left;

        float childTop;
        switch (_gravity & Gravity.verMask) {
        case Gravity.bottom:
            childTop = padding.top + rect.height - _totalLength;
            break;
        case Gravity.centerVer:
            childTop = padding.top + (rect.height - _totalLength) / 2f;
            break;
        case Gravity.top:
        default:
            childTop = padding.top;
            break;
        }

        foreach(i, c; enumerate(children)) {

            auto lp = cast(Params)c.style.layoutParams;
            immutable og = (lp && (lp.gravity != Gravity.none)) ?
                    lp.gravity : _gravity;

            immutable mes = c.measurement;
            float childLeft;
            switch (og & Gravity.horMask) {
            case Gravity.right:
                childLeft = childRight - mes.width;
                break;
            case Gravity.centerHor:
                childLeft = padding.left + (childSpace - mes.width) / 2f;
                break;
            case Gravity.left:
            default:
                childLeft = padding.left;
                break;
            }

            if (i != 0) childTop += spacing;
            c.layout(FRect(FPoint(childLeft, childTop), mes));
            childTop += mes.height;
        }
    }

    private void layoutHorizontal(in FRect rect)
    {
        import std.range : enumerate;

        immutable childBottom = rect.height - padding.bottom;
        immutable childSpace = rect.height - padding.bottom - padding.top;

        float childLeft;
        switch (_gravity & Gravity.horMask) {
        case Gravity.right:
            childLeft = padding.left + rect.width - _totalLength;
            break;
        case Gravity.centerHor:
            childLeft = padding.left + (rect.width - _totalLength) / 2f;
            break;
        case Gravity.left:
        default:
            childLeft = padding.left;
            break;
        }

        foreach(i, c; enumerate(children)) {

            auto lp = cast(Params)c.style.layoutParams;
            immutable og = (lp && (lp.gravity != Gravity.none)) ?
                    lp.gravity : _gravity;

            immutable mes = c.measurement;
            float childTop;
            switch (og & Gravity.verMask) {
            case Gravity.bottom:
                childTop = childBottom - mes.height;
                break;
            case Gravity.centerVer:
                childTop = padding.top + (childSpace - mes.height) / 2f;
                break;
            case Gravity.top:
            default:
                childTop = padding.top;
                break;
            }

            if (i != 0) childLeft += spacing;
            c.layout(FRect(FPoint(childLeft, childTop), mes));
            childLeft += mes.width;
        }
    }

    private Orientation _orientation;
    private Gravity _gravity            = Gravity.left | Gravity.top;
    private float _spacing              = 0f;

    private float _totalLength          = 0f;
}


/// provide the measure spec to be given to a child
/// Params:
///     parentSpec      =   the measure spec of the parent
///     removed         =   how much has been consumed so far from the parent space
///     childLayoutSize =   the child size given in layout params
public MeasureSpec childMeasureSpec(in MeasureSpec parentSpec, in float removed, in float childLayoutSize) pure
{
    import std.algorithm : max;

    if (childLayoutSize >= 0f) {
        return MeasureSpec.makeExactly(childLayoutSize);
    }
    enforce(childLayoutSize == wrapContent || childLayoutSize == matchParent);

    immutable size = max(0f, parentSpec.size - removed);

    switch (parentSpec.mode) {
    case MeasureSpec.exactly:
        if (childLayoutSize == wrapContent) {
            return MeasureSpec.makeAtMost(size);
        }
        else {
            assert(childLayoutSize == matchParent);
            return MeasureSpec.makeExactly(size);
        }
    case MeasureSpec.atMost:
        return MeasureSpec.makeAtMost(size);
    case MeasureSpec.unspecified:
        return MeasureSpec.makeUnspecified();
    default:
        assert(false);
    }
}

/// Reconciliate a measure spec and children dimensions.
/// This will give the final dimension to be shared amoung the children.
float resolveSize(in float size, in MeasureSpec measureSpec, out bool tooSmall) pure
{
    switch (measureSpec.mode) {
    case MeasureSpec.atMost:
        if (size > measureSpec.size) {
            tooSmall = true;
            return measureSpec.size;
        }
        else {
            return size;
        }
    case MeasureSpec.exactly:
        return measureSpec.size;
    case MeasureSpec.unspecified:
        return size;
    default:
        assert(false);
    }
}

private float get(in FSize s, in Orientation orientation) pure
{
    return orientation.isHorizontal ? s.width : s.height;
}

private float get(in FPoint p, in Orientation orientation) pure
{
    return orientation.isHorizontal ? p.x : p.y;
}

private float[2] get(in FPadding p, in Orientation orientation) pure
{
    return orientation.isHorizontal ? [p.left, p.right] : [p.top, p.bottom];
}

private float[2] get(in FMargins m, in Orientation orientation) pure
{
    return orientation.isHorizontal ? [m.left, m.right] : [m.top, m.bottom];
}

// private void measureNode(View n, in Orientation orientation,
//                         in float main, in float other,
//                         in int mainSpec, in int otherSpec)
// {
//     if (orientation.isHorizontal) {
//         n.measure(FSize(main, other), MeasureSpec(mainSpec, otherSpec));
//     }
//     else {
//         n.measure(FSize(other, main), MeasureSpec(otherSpec, mainSpec));
//     }
// }
