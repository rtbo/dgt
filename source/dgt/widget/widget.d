/// Widget module
module dgt.widget.widget;

import dgt.geometry;
import dgt.math;
import dgt.render.node;
import dgt.sg.node;
import dgt.widget.layout;

import std.experimental.logger;

/// The widget class is a node that is subjected to layout
class Widget : SgNode
{
    /// Builds a new widget
    this() {}

    /// The layout parameters of this node
    @property inout(Layout.Params) layoutParams() inout
    {
        return _layoutParams;
    }

    /// ditto
    @property void layoutParams(Layout.Params params)
    {
        _layoutParams = params;
    }

    /// The padding of the node, that is, how much empty space is required
    /// around the content.
    /// Padding is always within the node's rect.
    @property FPadding padding() const
    {
        return _padding;
    }

    /// ditto
    @property void padding(in FPadding padding)
    {
        _padding = padding;
    }

    /// Ask this node to measure itself by assigning the measurement property.
    void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        measurement = FSize(widthSpec.size, heightSpec.size);
    }

    /// Size set by the node during measure phase
    final @property FSize measurement() const
    {
        return _measurement;
    }

    final protected @property void measurement(in FSize sz)
    {
        _measurement = sz;
    }

    /// Ask the node to layout itself in the given rect
    void layout(in FRect rect)
    {
        this.rect = rect;
    }

    // layout
    private FPadding        _padding;
    private Layout.Params   _layoutParams;
    private FSize           _measurement;
    private FSize           _size;
}
