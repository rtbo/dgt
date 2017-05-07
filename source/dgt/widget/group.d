module dgt.widget.group;

import dgt.geometry;
import dgt.sg.node;
import dgt.sg.parent;
import dgt.widget.layout;
import dgt.widget.widget;


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

    override protected FRect computeBounds()
    {
        import std.algorithm : map;
        immutable cr = computeRectsExtents(
            children.map!(c => c.transformedBounds)
        );
        return FRect(pos + cr.point, cr.size);
    }
}