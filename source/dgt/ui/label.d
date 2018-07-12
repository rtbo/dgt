/// Label view module

module dgt.ui.label;

import dgt.core.enums;
import dgt.core.geometry;
import dgt.core.image;
import dgt.ui.img;
import dgt.ui.layout;
import dgt.ui.text;
import dgt.ui.view;

import std.experimental.logger;

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

        appendChild(_iconNode);
        appendChild(_textNode);
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
        measurement = computeMeasurement();
    }

    override void layout(in IRect rect)
    {
        // might differ from actual measurement because subclass have larger content
        const mes = computeMeasurement();

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
            const top = topAlignment(icon.height);
            _iconNode.rect = IRect(left, top, icon.size);
            left += icon.width + spacing;
        }
        if (text.length) {
            const ms = _textNode.metrics.size;
            const top = topAlignment(cast(int)ms.y);
            _textNode.rect = IRect(left, top, cast(int)ms.x, cast(int)ms.y);
        }
        this.rect = rect;
    }

    private ISize computeMeasurement()
    {
        int width, height;
        if (text.length) {
            width += cast(int)_textNode.metrics.size.x;
            height += cast(int)_textNode.metrics.size.y;
        }
        if (icon) {
            import std.algorithm : max;
            width += icon.width;
            height = max(icon.height, height);
            if (text.length) {
                width += spacing;
            }
        }
        return ISize(width+padding.horizontal, height+padding.vertical);
    }

    private Alignment _alignment = Alignment.top | Alignment.left;
    private ImageView _iconNode;
    private TextView _textNode;
}
