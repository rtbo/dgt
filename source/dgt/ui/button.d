/// Button UI module
module dgt.ui.button;

import dgt.core.color;
import dgt.core.geometry;
import dgt.core.paint;
import dgt.core.signal;
import dgt.css.style;
import dgt.render.framegraph;
import dgt.ui.event;
import dgt.ui.label;
import dgt.ui.layout;
import dgt.ui.style;
import dgt.ui.stylesupport;

import gfx.core.typecons : Option, some;

import gfx.core.log;
import std.typecons : Rebindable, rebindable;

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
        _backgroundProperty = addStyleSupport(this, BackgroundMetaProperty.instance);
        _bss.initialize(this);

        _backgroundProperty.onChange += &dirtyBg;
        _bss.borderColor.onChange += &dirtyBg;
        _bss.borderWidth.onChange += &dirtyBg;
        _bss.borderRadius.onChange += &dirtyBg;
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

    override void measure(in MeasureSpec widthSpec, in MeasureSpec heightSpec)
    {
        Label.measure(widthSpec, heightSpec);

        immutable bg = _backgroundProperty.value.get;
        if (bg && bg.type == PaintType.image) {
            import std.algorithm : max;
            immutable ip = cast(immutable(ImagePaint))bg;
            immutable img = ip.image;
            auto m = measurement;
            m = FSize(max(m.width, img.width), max(m.height, img.height));
            measurement = m;
        }
    }

    override immutable(FGNode) render(FrameContext fc) 
    {
        immutable lblNode = Label.render(fc);

        if (_bgDirty) {
            immutable bg = _backgroundProperty.value.get;
            immutable bcol = _bss.borderColor.value;

            if (_bgNode) {
                // release resource held by previous frame node
                fc.prune(_bgNode.cookie);
                _bgNode = null;
            }

            if (bg || !bcol.isTransparent) {

                Option!RectBorder border;
                if (!bcol.isTransparent) {
                    border = some(RectBorder(bcol.asVec, _bss.borderWidth.value));
                }

                _bgNode = new immutable FGRectNode(localRect,
                        _bss.borderRadius.value, bg, border, CacheCookie.next());

            }

            _bgDirty = false;
        }

        if (_bgNode && lblNode) {
            return new immutable FGGroupNode([
                _bgNode.get, lblNode
            ]);
        }
        else if (_bgNode) {
            return _bgNode.get;
        }
        else if (lblNode) {
            return lblNode;
        }
        else {
            return null;
        }
    }

    private void dirtyBg() {
        _bgDirty = true;
        invalidate();
    }

    private FireableSignal!()       _onClick;
    private StyleProperty!RPaint    _backgroundProperty;
    private BorderStyleSupport      _bss;

    private Rebindable!(immutable(FGRectNode)) _bgNode; // combination of background and border
    private bool _bgDirty;
}
