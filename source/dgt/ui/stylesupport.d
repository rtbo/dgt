module dgt.ui.stylesupport;

import dgt.core.color;
import dgt.css.style;
import dgt.ui.style;
import dgt.ui.view;

import std.typecons : Flag, Yes, No;

/// Give support to a style instance to a view.
/// Params:
///     - view:             the view that supports the CSS property
///     - metaProp:         the meta property instance of the supported CSS property
///     - ignoresShorthand  if the meta property has shorthand and the flag is not set, it is assumed
///                         that addShorthandStyleSupport is called for this very view and shorthand.
auto addStyleSupport(SMP)(View view, SMP metaProp, in Flag!"ignoresShorthand" ignoresShorthand = Yes.ignoresShorthand)
if (is(SMP : IStyleMetaProperty) && !SMP.isShorthand)
{
    auto sp = new SMP.Property(view, metaProp);
    view._styleProperties[metaProp.name] = sp;

    // the cascade algorithm visits recursively the meta props of each node to check for matching declarations
    // when it sees a shorthand meta prop, it will automatically check for the subproperties of this shorthand.
    // Thus, if a prop has a shorthand, it does not need to be listed in the meta props.
    // However, some views may prefer to ignore the shorthand and only support a subset of the sub properties.
    // In such case the ignoresShorthand flag is passed and the property is listed in the meta props regardless
    // of its shorthand.

    //    hasShorthand      ignoresShorthand     shouldVisit
    //          0                   0               1
    //          0                   1               1
    //          1                   0               0
    //          1                   1               1

    if (!metaProp.hasShorthand || ignoresShorthand) view._styleMetaProperties ~= metaProp;

    return sp;
}

/// give support to a shorthand style instance to a view
void addShorthandStyleSupport(SMP)(View view, SMP metaProp)
if (is(SMP : IStyleMetaProperty) && SMP.isShorthand)
{
    view._styleMetaProperties ~= metaProp;
}

struct FontStyleSupport
{
    import dgt.font.style : FontWeight, FontSlant;

    StyleProperty!(string[])    fontFamily;
    StyleProperty!FontWeight    fontWeight;
    StyleProperty!FontSlant     fontSlant;
    StyleProperty!int           fontSize;

    void initialize(View view)
    {
        addShorthandStyleSupport(view, FontMetaProperty.instance);
        fontFamily = addStyleSupport(view, FontFamilyMetaProperty.instance, No.ignoresShorthand);
        fontWeight = addStyleSupport(view, FontWeightMetaProperty.instance, No.ignoresShorthand);
        fontSlant = addStyleSupport(view, FontSlantMetaProperty.instance, No.ignoresShorthand);
        fontSize = addStyleSupport(view, FontSizeMetaProperty.instance, No.ignoresShorthand);
    }
}

struct BorderStyleSupport
{
    StyleProperty!Color borderColor;
    StyleProperty!int   borderWidth;
    StyleProperty!float borderRadius;

    void initialize(View view) {
        borderColor = addStyleSupport(view, BorderColorMetaProperty.instance);
        borderWidth = addStyleSupport(view, BorderWidthMetaProperty.instance);
        borderRadius = addStyleSupport(view, BorderRadiusMetaProperty.instance);
    }
}

struct BackgroundBorderStyleSupport
{
    import dgt.core.geometry : FRect;
    import dgt.core.paint : RPaint;
    import dgt.render.framegraph;
    import std.typecons : Rebindable;

    StyleProperty!RPaint background;
    StyleProperty!Color borderColor;
    StyleProperty!int   borderWidth;
    StyleProperty!float borderRadius;
    bool dirty;
    Rebindable!(immutable(FGRectNode)) node; // combination of background and border

    void initialize(View view)
    {
        background = addStyleSupport(view, BackgroundMetaProperty.instance);
        borderColor = addStyleSupport(view, BorderColorMetaProperty.instance);
        borderWidth = addStyleSupport(view, BorderWidthMetaProperty.instance);
        borderRadius = addStyleSupport(view, BorderRadiusMetaProperty.instance);

        void doDirty() {
            view.invalidate();
            dirty = true;
        }

        background.onChange += &doDirty;
        borderColor.onChange += &doDirty;
        borderWidth.onChange += &doDirty;
        borderRadius.onChange += &doDirty;
    }

    immutable(FGNode) frame (FrameContext fc, in FRect rect, immutable(FGNode) viewNode)
    {
        import gfx.core.typecons : Option, some;

        if (dirty) {
            immutable bg = background.value.get;
            immutable bcol = borderColor.value;

            if (node) {
                // release resource held by previous frame node
                fc.prune(node.cookie);
                node = null;
            }

            if (bg || !bcol.isTransparent) {

                Option!RectBorder border;
                if (!bcol.isTransparent) {
                    border = some(RectBorder(bcol.asVec, borderWidth.value));
                }

                node = new immutable FGRectNode(rect, borderRadius.value,
                    bg, border, CacheCookie.next());
            }

            dirty = false;
        }

        if (node && viewNode) {
            return new immutable FGGroupNode([
                node.get, viewNode
            ]);
        }
        else if (node) {
            return node.get;
        }
        else if (viewNode) {
            return viewNode;
        }
        else {
            return null;
        }
    }
}
