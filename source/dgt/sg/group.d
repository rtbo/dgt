module dgt.sg.group;

import dgt.geometry;
import dgt.sg.layout;
import dgt.sg.node;
import dgt.sg.parent;
import dgt.sg.widget;


class Group : Widget
{
    this() {}

    override public void appendChild(SgNode node)
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

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        measurement = transformedBounds.size;
    }

    override void layout(in FRect rect)
    {
        layoutRect = rect;
    }

    override protected FRect computeBounds()
    {
        import std.algorithm : map;
        return computeRectsExtents(
            children.map!(c => c.transformedBounds)
        );
    }
}
