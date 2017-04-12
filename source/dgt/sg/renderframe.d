module dgt.sg.renderframe;

import dgt.sg.rendernode;
import dgt.geometry;
import dgt.math;

import std.typecons;

class RenderFrame
{
    IRect _viewport;
    Nullable!FVec4 _clearColor;
    Rebindable!(immutable(RenderNode)) _root;

    this(IRect viewport)
    {
        _viewport = viewport;
    }

    @property IRect viewport() const { return _viewport; }

    @property Nullable!FVec4 clearColor() const { return _clearColor; }
    @property void clearColor(Nullable!FVec4 clearColor)
    {
        _clearColor = clearColor;
    }

    @property immutable(RenderNode) root() const
    {
        return _root;
    }
    @property void root(immutable(RenderNode) root)
    {
        _root = root;
    }
}
