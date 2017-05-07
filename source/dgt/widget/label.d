/// label module
module dgt.widget.label;

import dgt.enums;
import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.render.node;
import dgt.sg.miscnodes;
import dgt.text.font;
import dgt.text.fontcache;
import dgt.text.layout;
import dgt.widget.layout;
import dgt.widget.widget;

import std.experimental.logger;
import std.typecons : Rebindable;

/// Label is a widget to display a line of text and/or an icon
class Label : Widget
{
    /// build a new label
    this() {}

    /// Alignment that is applied when the container has too much space,
    /// and/or when both icon and text are requested and do not have the same
    /// height
    @property Alignment alignment() const
    {
        return _alignment;
    }

    /// ditto
    @property void alignment(in Alignment alignment)
    {
        _alignment = alignment;
    }

    /// Optional text
    @property string text() const
    {
        return _text;
    }

    /// ditto
    @property void text(in string text)
    {
        _text = text;
    }

    /// Optional icon
    @property immutable(Image) icon() const
    {
        return _icon;
    }

    /// ditto
    @property void icon(immutable(Image) icon)
    {
        _icon = icon;
    }

    /// Space between text and icon
    enum spacing = 6f;

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        float width = padding.left + padding.right;
        float height = padding.top + padding.bottom;
        if (_text.length) {
            ensureLayout();
            width += _metrics.size.x;
            height += _metrics.size.y;
        }
        if (_icon) {
            import std.algorithm : max;
            width += _icon.width;
            height = max(_icon.height, height);
            if (_text.length) {
                width += spacing;
            }
        }
        measurement = FSize(width, height);
    }

    override immutable(RenderNode) collectRenderNode()
    {
        immutable r = rect;
        immutable mes = measurement;

        float left;
        if (alignment & Alignment.centerH) {
            left = (r.width - mes.width) / 2f;
        }
        else if (alignment & Alignment.right) {
            left = (r.width - mes.width);
        }
        else {
            left = padding.left;
        }

        float topAlignment(in float height) {
            float top;
            if (alignment & Alignment.centerV) {
                top = (r.height - height) / 2f;
            }
            else if (alignment & Alignment.bottom) {
                top = (r.height - height);
            }
            else {
                top = padding.top;
            }
            return top;
        }

        Rebindable!(immutable(RenderNode)) iconNode;
        Rebindable!(immutable(RenderNode)) textNode;

        if (_icon) {
            auto top = topAlignment(_icon.height);
            iconNode = new immutable(ImageRenderNode)(
                FVec2(left, top), _icon
            );
            left += _icon.width + spacing;
        }
        if (_text.length) {
            ensureLayout();
            auto top = topAlignment(_metrics.size.y);
            textNode = new immutable(TextRenderNode)(
                _layout.render(), fvec(left, top)+_metrics.bearing, fvec(0, 0, 0, 1)  // FIXME: CSS
            );
        }

        if (iconNode && textNode) {
            return new immutable(GroupRenderNode)(
                rect, [iconNode, textNode]
            );
        }
        else if (textNode) {
            return textNode;
        }
        else if (iconNode) {
            return iconNode;
        }
        else {
            return null;
        }
    }

    private void ensureLayout()
    {
        assert(_text.length);
        if (!_layout) {
            // FIXME: CSS font
            _layout = new TextLayout(_text, TextFormat.plain, FontRequest.init);
            _layout.layout();
            _layout.prepareGlyphRuns();
            _metrics = _layout.metrics;
        }
    }

    private Alignment _alignment = Alignment.top | Alignment.left;
    private string _text;
    private Rebindable!(immutable(Image)) _icon;

    private TextLayout _layout;
    private TextMetrics _metrics;
}
