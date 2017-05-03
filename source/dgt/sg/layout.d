/// layout module
module dgt.sg.layout;

import dgt.enums;
import dgt.geometry;
import dgt.math;
import dgt.sg.node;
import dgt.sg.parent;

import gfx.foundation.typecons;

import std.exception;
import std.experimental.logger;

/// Specifies how a node should measure itself
struct MeasureSpec
{
    enum {
        /// node should measure its content
        content,
        /// node should measure its content bounded to the given size
        bounded,
        /// node should assign its measurement to the given size regardless of its content
        fixed,
    }

    int mode;
    float size;

    this (int mode, float size) pure {
        this.mode = mode;
        this.size = size;
    }

    /// make a content spec
    static MeasureSpec makeContent(in float size=0f) pure {
        return MeasureSpec(content, size);
    }

    /// make a bounded spec
    static MeasureSpec makeBounded(in float size) pure {
        return MeasureSpec(bounded, size);
    }

    /// make a fixed spec
    static MeasureSpec makeFixed(in float size) pure {
        return MeasureSpec(fixed, size);
    }
}

/// Special value for Layout.Params.width and height.
enum float wrapContent = -1f;
/// ditto
enum float fitParent = -2f;

/// general layout class
class SgLayout : SgParent
{
    /// Params attached to each node for use with their parent
    static class Params {
        /// Either an actual dimension in pixels, or special values wrapContent or fitParent
        float width=wrapContent;
        /// Either an actual dimension in pixels, or special values wrapContent or fitParent
        float height=wrapContent;
    }

    /// Build a new layout
    this() {}

    override void appendChild(SgNode node)
    {
        ensureLayout(node);
        super.appendChild(node);
    }

    override public void prependChild(SgNode node)
    {
        ensureLayout(node);
        super.prependChild(node);
    }

    override public void insertChildBefore(SgNode node, SgNode child)
    {
        ensureLayout(node);
        super.insertChildBefore(node, child);
    }

    override public void removeChild(SgNode child)
    {
        super.removeChild(child);
    }

    /// Ensure that this node has layout params and that they are compatible
    /// with this layout. If not, default params are assigned.
    protected void ensureLayout(SgNode node)
    {
        auto lp = cast(SgLayout.Params)node.layoutParams;
        if (!lp) {
            node.layoutParams = new SgLayout.Params;
        }
    }

    /// Ask a child to measure itself taking into account the measureSpecs
    /// given to this layout, the padding and the size that have been consumed
    /// by other children.
    protected void measureChild(SgNode node, in MeasureSpec parentWidthSpec,
                                in MeasureSpec parentHeightSpec,
                                in float usedWidth=0f, in float usedHeight=0f)
    {
        auto lp = cast(SgLayout.Params)node.layoutParams;

        immutable ws = childMeasureSpec(parentWidthSpec,
                    margins.left+margins.right+usedWidth, lp.width);
        immutable hs = childMeasureSpec(parentHeightSpec,
                    margins.top+margins.bottom+usedHeight, lp.height);

        node.measure(ws, hs);
    }


}

/// layout its children in a linear way
class SgLinearLayout : SgLayout
{
    /// Build a new linear layout
    this() {}

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
        if (isHorizontal) {
            measureHorizontal(widthSpec, heightSpec);
        }
        else {
            measureVertical(widthSpec, heightSpec);
        }
    }

    private void measureVertical(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        import std.algorithm : max;
        import std.range : enumerate;

        // compute vertical space that all children want to have
        float totalHeight =0;
        float largestWidth = 0;
        foreach(i, c; enumerate(children)) {
            if (i != 0) totalHeight += spacing;
            measureChild(c, widthSpec, heightSpec, 0f, totalHeight);
            totalHeight += c.measurement.height;
            largestWidth = max(largestWidth, c.measurement.width);
        }
        largestWidth += margins.left + margins.right;
        totalHeight += margins.top + margins.bottom;

        bool wTooSmall, hTooSmall;
        measurement = FSize(
            resolveSize(largestWidth, widthSpec, wTooSmall),
            resolveSize(totalHeight, heightSpec, hTooSmall),
        );
        if (wTooSmall || hTooSmall) {
            warningf("layout too small for %s", name);
        }
    }

    private void measureHorizontal(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        import std.algorithm : max;
        import std.range : enumerate;

        // compute vertical space that all children want to have
        float totalWidth = 0;
        float largestHeight = 0;
        foreach(i, c; enumerate(children)) {
            if (i != 0) totalWidth += spacing;
            measureChild(c, widthSpec, heightSpec, totalWidth, 0f);
            totalWidth += c.measurement.width;
            largestHeight = max(largestHeight, c.measurement.height);
        }
        totalWidth += margins.left + margins.right;
        largestHeight += margins.top + margins.bottom;

        bool wTooSmall, hTooSmall;
        measurement = FSize(
            resolveSize(totalWidth, widthSpec, wTooSmall),
            resolveSize(largestHeight, heightSpec, hTooSmall),
        );
        if (wTooSmall || hTooSmall) {
            warningf("layout too small for %s", name);
        }
    }

    override void layout(in FRect rect)
    {
        import std.range : enumerate;
        FPoint pos = FPoint(margins.left, margins.top);
        foreach (i, c; enumerate(children, 1)) {
            immutable m = c.measurement;
            c.layout(FRect(pos, m));
            float add = m.get(orientation);
            if (i != childCount) {
                add += spacing;
            }
            pos += isHorizontal ? FVec2(add, 0f) : FVec2(0f, add);
        }
        layoutRect = rect;
    }

    private Orientation _orientation;
    private float _spacing=0f;
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
        return MeasureSpec.makeFixed(childLayoutSize);
    }
    enforce(childLayoutSize == wrapContent || childLayoutSize == fitParent);

    immutable size = max(0f, parentSpec.size - removed);

    switch (parentSpec.mode) {
    case MeasureSpec.fixed:
        if (childLayoutSize == wrapContent) {
            return MeasureSpec.makeBounded(size);
        }
        else {
            assert(childLayoutSize == fitParent);
            return MeasureSpec.makeFixed(size);
        }
    case MeasureSpec.bounded:
        return MeasureSpec.makeBounded(size);
    case MeasureSpec.content:
        return MeasureSpec.makeContent();
    default:
        assert(false);
    }
}

/// Reconciliate a measure spec and children dimensions.
/// This will give the final dimension to be shared amoung the children.
float resolveSize(in float size, in MeasureSpec measureSpec, out bool tooSmall) pure
{
    switch (measureSpec.mode) {
    case MeasureSpec.bounded:
        if (size > measureSpec.size) {
            tooSmall = true;
            return measureSpec.size;
        }
        else {
            return size;
        }
    case MeasureSpec.fixed:
        return measureSpec.size;
    case MeasureSpec.content:
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

private float[2] get(in FMargins m, in Orientation orientation) pure
{
    return orientation.isHorizontal ? [m.left, m.right] : [m.top, m.bottom];
}

// private void measureNode(SgNode n, in Orientation orientation,
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