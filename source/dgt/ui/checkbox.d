module dgt.ui.checkbox;

import dgt.core.enums;
import dgt.core.geometry;
import dgt.core.signal;
import dgt.css.style;
import dgt.render.framegraph;
import dgt.ui.event;
import dgt.ui.layout : MeasureSpec;
import dgt.ui.stylesupport;
import dgt.ui.text;
import dgt.ui.view;


class CheckBox : View
{
    this()
    {
        _onToggle = new FireableSignal!bool;
        _onClick = new FireableSignal!();
        padding = FPadding(6);
        _text = new TextView;
        _indicator = new CheckBoxIndicator;
        appendView(_indicator);
        appendView(_text);
    }

    override @property string cssType()
    {
        return "checkbox";
    }

    @property bool checked()
    {
        return _indicator.checked;
    }

    @property void checked(bool checked)
    {
        _indicator.checked = checked;
        invalidate();
    }

    @property void toggle()
    {
        _indicator.checked = !_indicator.checked;
        _onToggle.fire(_indicator.checked);
        invalidate();
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
        return _text.text;
    }

    /// ditto
    @property void text(in string text)
    {
        _text.text = text;
    }

    /// Space between text and icon
    enum spacing = 6f;

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        const unspecified = MeasureSpec.makeUnspecified();
        _indicator.measure(unspecified, unspecified);
        _text.measure(unspecified, unspecified);

        auto sz = _indicator.measurement;
        assert(sz.area > 0f);
        const txtSz = _text.measurement;

        if (txtSz.area > 0f) {
            sz = FSize(sz.width+txtSz.width+spacing, sz.height+txtSz.height);
        }
        measurement = sz + padding;
    }

    override void layout(in FRect rect)
    {
        const mes = measurement;
        const alignment = this.alignment;
        const padding = this.padding;

        // mes includes padding
        float left=void;
        if (alignment & Alignment.centerH) {
            left = padding.left + (rect.width - mes.width) / 2f;
        }
        else if (alignment & Alignment.right) {
            left = padding.left + (rect.width - mes.width);
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

        const indM = _indicator.measurement;
        const indTop = topAlignment(indM.height);
        _indicator.layout(FRect(left, indTop, indM));
        left += indM.width + spacing;
        if (text.length) {
            const m = _text.measurement;
            const top = topAlignment(m.height);
            _text.layout(FRect(left, top, m));
        }
        this.rect = rect;
    }

    override protected void mouseClickEvent(MouseEvent /+ev+/)
    {
        _indicator.checked = !_indicator.checked;
        _onClick.fire();
        _onToggle.fire(_indicator.checked);
    }

    override protected void mouseDownEvent(MouseEvent /+ev+/)
    {
        addPseudoState(PseudoState.active);
        _indicator.addPseudoState(PseudoState.active);
    }

    override protected void mouseUpEvent(MouseEvent /+ev+/)
    {
        remPseudoState(PseudoState.active);
        _indicator.remPseudoState(PseudoState.active);
    }

    override protected void mouseDragEvent(MouseEvent ev)
    {
        if (localRect.contains(ev.pos)) {
            addPseudoState(PseudoState.active);
            _indicator.addPseudoState(PseudoState.active);
        }
        else {
            remPseudoState(PseudoState.active);
            _indicator.remPseudoState(PseudoState.active);
        }
    }

    override protected void mouseEnterEvent(MouseEvent ev)
    {
        addPseudoState(PseudoState.hover);
        _indicator.addPseudoState(PseudoState.hover);
    }

    override protected void mouseLeaveEvent(MouseEvent ev)
    {
        remPseudoState(PseudoState.hover);
        _indicator.remPseudoState(PseudoState.hover);
    }

    private FireableSignal!bool _onToggle;
    private FireableSignal!() _onClick;
    private Alignment _alignment = Alignment.top | Alignment.left;
    private TextView _text;
    private CheckBoxIndicator _indicator;
}


private class CheckBoxIndicator : View
{
    immutable defaultSize = FSize(16, 16);

    this()
    {
        bbss.initialize(this);
    }

    override @property string cssType()
    {
        return "checkbox-indicator";
    }

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        measurement = defaultSize;
    }

    override immutable(FGNode) frame(FrameContext fc)
    {
        import dgt.core.color : Color;
        import dgt.core.paint : ColorPaint;
        import gfx.core.typecons : none;
        import std.typecons : Rebindable;

        Rebindable!(immutable(FGRectNode)) mark;
        const r = localRect;

        if (indeterminate) {
            const margins = FMargins(4);
            immutable indeterminateMark = new immutable FGRectNode(
                r-margins, 0, new immutable ColorPaint(Color.grey), none!RectBorder, CacheCookie.next
            );
            mark = indeterminateMark;
        }
        else if (checked) {
            const margins = FMargins(4);
            immutable checkedMark = new immutable FGRectNode(
                r-margins, 0, new immutable ColorPaint(Color.black), none!RectBorder, CacheCookie.next
            );
            mark = checkedMark;
        }

        return bbss.frame(fc, localRect, mark);
    }

    private BackgroundBorderStyleSupport bbss;
    private bool checked;
    private bool indeterminate;
}
