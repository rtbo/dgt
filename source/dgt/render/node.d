module dgt.render.node;

import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.text.layout;

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
        text,
    }

    private Type _type;
    private FRect _bounds;

    immutable this(in Type type, in FRect bounds)
    {
        _type = type;
        _bounds = bounds;
    }

    @property Type type() const { return _type; }

    @property FRect bounds() const { return _bounds; }

}

class GroupRenderNode : RenderNode
{
    private immutable(RenderNode)[] _children;

    immutable this(in FRect bounds, immutable(RenderNode)[] children)
    {
        _children = children;
        super(Type.group, bounds);
    }
    immutable this(immutable(RenderNode)[] children)
    {
        import std.algorithm : map;
        _children = children;
        super(Type.group, computeRectsExtents(children.map!(c => c.bounds)));
    }

    @property immutable(RenderNode)[] children() const { return _children; }
}

class TransformRenderNode : RenderNode
{
    private FMat4 _transform;
    private immutable(RenderNode) _child;

    immutable this(in FMat4 transform, immutable(RenderNode) child)
    {
        _transform = transform;
        _child = child;
        super(Type.transform, transformBounds(child.bounds, transform));
    }

    @property FMat4 transform() const { return _transform; }
    @property immutable(RenderNode) child() const { return _child; }
}


class ColorRenderNode : RenderNode
{
    private FVec4 _color;

    immutable this(in FVec4 color, in FRect bounds)
    {
        _color = color;
        super(Type.color, bounds);
    }

    @property FVec4 color() const { return _color; }
}

class ImageRenderNode : RenderNode
{
    private immutable(Image) _img;
    private ulong _cacheCookie;

    immutable this (in FPoint topLeft, immutable(Image) img, in ulong cacheCookie=0)
    {
        _img = img;
        _cacheCookie = cacheCookie;
        super(Type.image, FRect(topLeft, cast(FSize)img.size));
    }

    @property immutable(Image) image() const { return _img; }
    @property ulong cacheCookie() const { return _cacheCookie; }
}

class TextRenderNode : RenderNode
{
    private immutable(ShapedGlyph)[] _glyphs;
    private FVec4 _color;

    immutable this (immutable(ShapedGlyph)[] glyphs, in FVec4 color)
    {
        _glyphs = glyphs;
        _color = color;
        super(Type.text, FRect(0, 0, 0, 0));
    }

    @property immutable(ShapedGlyph)[] glyphs() const { return _glyphs; }
    @property FVec4 color() const { return _color; }
}
