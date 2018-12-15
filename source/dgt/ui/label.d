/// Label view module

module dgt.ui.label;

import dgt.core.enums;
import dgt.gfx.geometry;
import dgt.gfx.image;
import dgt.ui.img;
import dgt.ui.layout;
import dgt.ui.text;
import dgt.ui.view;

/// Label is a widget to display a line of text and/or an icon
class Label : View
{
    /// build a new label
    this()
    {
        padding = FPadding(6);
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
    enum spacing = 6f;

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        _textNode.measure(MeasureSpec.makeUnspecified(), MeasureSpec.makeUnspecified());
        _iconNode.measure(MeasureSpec.makeUnspecified(), MeasureSpec.makeUnspecified());

        float width=0f, height=0f;
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
        measurement = FSize(width+padding.horizontal, height+padding.vertical);
    }

    override void layout(in FRect rect)
    {
        float left=void;
        if (alignment & Alignment.centerH) {
            left = (rect.width - contentWidth) / 2f;
        }
        else if (alignment & Alignment.right) {
            left = (rect.width - contentWidth) - padding.right;
        }
        else {
            left = padding.left;
        }

        float topAlignment(in float height) {
            // height does not include padding
            float top=void;
            if (alignment & Alignment.centerV) {
                top = (rect.height - height + padding.top - padding.bottom) / 2f;
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
            _iconNode.layout(FRect(left, top, m));
            left += icon.width + spacing;
        }
        if (text.length) {
            const m = _textNode.measurement;
            const top = topAlignment(m.height);
            _textNode.layout(FRect(left, top, m));
        }
        this.rect = rect;
    }

    private @property float contentWidth()
    {
        float w = icon && text.length ? spacing : 0f;
        if (icon) {
            w += _iconNode.measurement.width;
        }
        if (text.length) {
            w += _textNode.measurement.width;
        }
        return w;
    }

    private Alignment _alignment = Alignment.topLeft;
    private ImageView _iconNode;
    private TextView _textNode;
}
