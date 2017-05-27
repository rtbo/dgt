/// Button widget module
module dgt.widget.button;

import dgt.event;
import dgt.geometry;
import dgt.sg.style;
import dgt.widget.label;

// A Button is a label, with a specific default style and reacting to
// :active and :hover pseudo classes

/// A button widget
class Button : Label
{
    public alias ClickSlot = Slot!();
    public alias ClickSignal = Signal!();

    /// build a new button
    this()
    {
        padding = FPadding(6);
        _onClick = new FireableSignal!();
        hoverSensitive = true;
    }

    override @property string cssType()
    {
        return "button";
    }

    @property ClickSignal onClick()
    {
        return _onClick;
    }

    override protected void mouseClickEvent(MouseEvent /+ev+/)
    {
        _onClick.fire();
    }

    override protected void mouseDownEvent(MouseEvent /+ev+/)
    {
        addPseudoState(PseudoState.active);
    }

    override protected void mouseUpEvent(MouseEvent /+ev+/)
    {
        remPseudoState(PseudoState.active);
    }

    override protected void mouseDragEvent(MouseEvent ev)
    {
        if (localRect.contains(ev.pos)) {
            addPseudoState(PseudoState.active);
        }
        else {
            remPseudoState(PseudoState.active);
        }
    }

    private FireableSignal!() _onClick;
}
