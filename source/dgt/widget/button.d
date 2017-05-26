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
        onMouseClick = (MouseEvent /+ev+/) {
            _onClick.fire();
        };
        onMouseDown = (MouseEvent /+ev+/) {
            addPseudoState(PseudoState.active);
        };
        onMouseUp = (MouseEvent /+ev+/) {
            remPseudoState(PseudoState.active);
        };
        onMouseDrag = (MouseEvent ev) {
            if (FRect(0, 0, bounds.size).contains(ev.pos)) {
                addPseudoState(PseudoState.active);
            }
            else {
                remPseudoState(PseudoState.active);
            }
        };
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


    private FireableSignal!() _onClick;
}
