module dgt.sg.rendernode;

import dgt.geometry;
import dgt.math;
import dgt.image;

// One problem to solve is how to cache rendering data between frames
// and avoid unuseful cycle and data transfer.
// A possibility is to add a cache flag to some types (like the Image node)
// that will instruct the renderer to keep the texure in cache.
// Later on, when the reference to the image is dropped, a msg can be sent to the renderer
// requiring to free the resource.

/// Transient render node tree
/// A graph structure that tells a renderer what to render, no more, no less.
/// Is meant to be collected as immutable during frame construct and sent to a renderer
/// that can reside peacefully in a dedicated thread and perform lock-free rendering.
/// Application (or widgets or whatever) can still cache the nodes in their immutable form.
abstract class RenderNode
{
    enum Type
    {
        group,
        transform,
        color,
        image,
    }

    private Rect _bounds;
    private Type _type;

    this(in Type type)
    {
        _type = type;
    }
    this(in Type type, in Rect bounds)
    {
        _type = type;
        _bounds = bounds;
    }

    @property Type type() const { return _type; }

    @property Rect bounds() const { return _bounds; }
}


class GroupRenderNode : RenderNode
{
    private immutable(RenderNode)[] _children;

    this(in Rect bounds, immutable(RenderNode)[] children)
    {
        _children = children;
        super(Type.group, bounds);
    }
    this(immutable(RenderNode)[] children)
    {
        import std.algorithm : map;
        _children = children;
        super(Type.group, computeRectsExtents(
            children.map!(c => c.bounds)
        ));
    }

    immutable(RenderNode)[] children() const { return _children; }
}

class TransformRenderNode : RenderNode
{
    private FMat4 _transform;
    private immutable(RenderNode) _child;

    this(in FMat4 transform, immutable(RenderNode) child)
    {
        _transform = transform;
        _child = child;
        super(Type.transform, transformBounds(child.bounds, transform)); // bounds
    }
}


class ColorRenderNode : RenderNode
{
    private FVec4 _color;

    this(in FVec4 color, in Rect bounds)
    {
        _color = color;
        super(Type.color, bounds);
    }
}

class ImageRenderNode : RenderNode
{
    private immutable(Image) _img;

    this (in Point topLeft, immutable(Image) img)
    {
        _img = img;
        super(Type.image, Rect(topLeft, cast(Size)img.size));
    }
}


