module dgt.sg.group;

import dgt.sg.node;
import dgt.sg.parent;


class SgGroup : SgParent
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
}
