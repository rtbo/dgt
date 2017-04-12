module dgt.sg.renderframe;

import dgt.sg.rendernode;
import dgt.geometry;
import dgt.math;

import std.typecons;

// TODO builder pattern

class RenderFrame
{
    IRect _viewport;
    size_t _windowHandle;
    Nullable!FVec4 _clearColor;
    immutable(RenderNode) _root=null;

    immutable this(size_t windowHandle, IRect viewport, FVec4 clearColor, immutable(RenderNode) root)
    {
        _windowHandle = windowHandle;
        _viewport = viewport;
        _clearColor = clearColor;
        _root = root;
    }

    immutable this(size_t windowHandle, IRect viewport, FVec4 clearColor)
    {
        _windowHandle = windowHandle;
        _viewport = viewport;
        _clearColor = clearColor;
    }

    immutable this(size_t windowHandle, IRect viewport, immutable(RenderNode) root)
    {
        _windowHandle = windowHandle;
        _viewport = viewport;
        _root = root;
    }

    immutable this(size_t windowHandle, IRect viewport)
    {
        _windowHandle = windowHandle;
        _viewport = viewport;
    }


    @property size_t windowHandle() const { return _windowHandle; }
    @property IRect viewport() const { return _viewport; }

    @property bool hasClearColor() const { return !_clearColor.isNull; }
    @property FVec4 clearColor() const { return _clearColor; }
    @property immutable(RenderNode) root() const { return _root; }
}
