/// layout module
module dgt.sg.layout;

import dgt.enums;
import dgt.geometry;
import dgt.math;
import dgt.sg.node;
import dgt.sg.parent;

import std.experimental.logger;

/// general layout class
class SgLayout : SgParent
{
    this() {}
}

/// layout its children in a linear way
class SgLinearLayout : SgLayout
{
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

    /// The margins of the layout, that is, how much empty space is required
    /// around the layout children.
    @property FMargins margins() const
    {
        return _margins;
    }

    /// ditto
    @property void margins(in FMargins margins)
    {
        _margins = margins;
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

    override void appendChild(SgNode node)
    {
        super.appendChild(node);
    }

    override public void prependChild(SgNode node)
    {
        super.prependChild(node);
    }

    override public void insertChildBefore(SgNode node, SgNode child)
    {
        super.insertChildBefore(node, child);
    }

    override public void removeChild(SgNode child)
    {
        super.removeChild(child);
    }

    override void measure(in FSize sz)
    {
        immutable m = margins.get(orientation);
        immutable om = margins.get(orientation.other);
        immutable totSpacing = childCount ? (childCount-1)*spacing : 0f;
        immutable float[2] emptySpace = [
            m[0] + m[1] + totSpacing,
            om[0] + om[1]
        ];
        float s = sz.get(orientation) - emptySpace[0];
        float os = sz.get(orientation.other) - emptySpace[1];

        if (s <= 0 || os <=0) {
            warningf("not enough space for linearlayout %s", name);
            if (s < 0) s = 0;
            if (os < 0) os = 0;
        }

        immutable perChild = childCount ? s / childCount : 0f;

        import std.algorithm : each, max;

        if (isHorizontal) {
            auto res = FSize(emptySpace[0], sz.height);
            children.each!((SgNode c) {
                c.measure(FSize(perChild, os));
                res = FSize(
                    res.width + c.measurement.width,
                    max(res.height, c.measurement.height),
                );
            });
            measurement = res;
        }
        else {
            auto res = FSize(sz.width, emptySpace[1]);
            children.each!((SgNode c) {
                c.measure(FSize(os, perChild));
                res = FSize(
                    max(res.width, c.measurement.width),
                    res.height + c.measurement.height,
                );
            });
            measurement = res;
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
    private FMargins _margins;
    private float _spacing=0f;
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
