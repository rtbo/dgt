/// Label view module

module dgt.ui.label;

import dgt.core.enums;
import dgt.core.geometry;
import dgt.core.image;
import dgt.ui.img;
import dgt.ui.layout;
import dgt.ui.text;
import dgt.ui.view;

import gfx.core.log;

/// Label is a widget to display a line of text and/or an icon
class Label : View
{
    /// build a new label
    this()
    {
        padding = IPadding(6);
        _iconNode = new ImageView;
        _iconNode.name = "img";
        _textNode = new TextView;
        _textNode.name = "txt";

        appendView(_iconNode);
        appendView(_textNode);
    }

    override @property string cssType()
    {
        return "label";
    }

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
        requestLayoutPass();
    }

    /// Optional text
    @property string text()
    {
        return _textNode.text;
    }

    /// ditto
    @property void text(in string text)
    {
        _textNode.text = text;
    }

    /// Optional icon
    @property immutable(Image) icon()
    {
        return _iconNode.image;
    }

    /// ditto
    @property void icon(immutable(Image) icon)
    {
        _iconNode.image = icon;
    }

    /// Space between text and icon
    enum spacing = 6;

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        _textNode.measure(MeasureSpec.makeUnspecified(), MeasureSpec.makeUnspecified());
        _iconNode.measure(MeasureSpec.makeUnspecified(), MeasureSpec.makeUnspecified());

        int width, height;
        if (text.length) {
            const m = _textNode.measurement;
            width += m.width;
            height += m.height;
        }
        if (icon) {
            import std.algorithm : max;
            const m = _iconNode.measurement;
            width += m.width;
            height = max(m.height, height);
            if (text.length) {
                width += spacing;
            }
        }
        measurement = ISize(width+padding.horizontal, height+padding.vertical);
    }

    override void layout(in IRect rect)
    {
        const mes = measurement;

        // mes includes padding
        int left;
        if (alignment & Alignment.centerH) {
            left = padding.left + (rect.width - mes.width) / 2;
        }
        else if (alignment & Alignment.right) {
            left = padding.left + (rect.width - mes.width);
        }
        else {
            left = padding.left;
        }

        int topAlignment(in int height) {
            // height does not include padding
            int top;
            if (alignment & Alignment.centerV) {
                top = (rect.height - height + padding.top - padding.bottom) / 2;
            }
            else if (alignment & Alignment.bottom) {
                top = rect.height - height - padding.bottom;
            }
            else {
                top = padding.top;
            }
            return top;
        }

        if (icon) {
            const m = _iconNode.measurement;
            const top = topAlignment(m.height);
            _iconNode.layout(IRect(left, top, m));
            left += icon.width + spacing;
        }
        if (text.length) {
            const m = _textNode.measurement;
            const top = topAlignment(m.height);
            _textNode.layout(IRect(left, top, m));
        }
        this.rect = rect;
    }

    private Alignment _alignment = Alignment.top | Alignment.left;
    private ImageView _iconNode;
    private TextView _textNode;
}
