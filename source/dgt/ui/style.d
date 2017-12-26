/// Module gathering CSS properties implemented by DGT for views
module dgt.ui.style;

import dgt.css.style;
import dgt.css.token;
import dgt.ui.layout;
import dgt.ui.view;

import std.range;

class LayoutWidthMetaProperty : LayoutSizeMetaProperty
{
    mixin StyleSingleton!(typeof(this));

    this() { super("layout-width"); }
}
class LayoutHeightMetaProperty : LayoutSizeMetaProperty
{
    mixin StyleSingleton!(typeof(this));

    this() { super("layout-height"); }
}

/// layout-width / layout-height
/// Value:      number | match-parent | wrap-content
/// Inherited:  no
/// Initial:    wrap-content
class LayoutSizeMetaProperty : StyleMetaProperty!float
{
    this(string name)
    {
        super(name, false, wrapContent, false);
    }

    override bool parseValueImpl(ref Token[] tokens, out float sz)
    {
        popSpaces(tokens);
        if (tokens.empty) {
            return false;
        }
        else if (tokens.front.tok == Tok.number) {
            sz = tokens.front.num;
            tokens.popFront();
            return true;
        }
        else if (tokens.front.tok == Tok.ident) {
            switch (tokens.front.str) {
            case "match-parent":
                tokens.popFront();
                sz = matchParent;
                return true;
            case "wrap-content":
                tokens.popFront();
                sz = wrapContent;
                return true;
            default:
                return false;
            }
        }
        else {
            return false;
        }
    }
}

/// layout-gravity
/// Value:      <gravity> [ '|' <gravity> ]
/// Inherited:  no
/// Initial:    none
/// <gravity>:  left | right | bottom | top | center | center-h | center-v
///             fill | fill-h | fill-v | clip | clip-h | clip-v | none
///
/// Gravity applied to layout params that implement HasGravity
class LayoutGravityMetaProperty : StyleMetaProperty!Gravity
{
    mixin StyleSingleton!(typeof(this));

    this()
    {
        super("layout-gravity", false, Gravity.none, false);
    }

    override bool parseValueImpl(ref Token[] tokens, out Gravity grav)
    {
        popSpaces(tokens);
        if (tokens.empty) return false;
        immutable g1 = parseGravity(tokens.front);
        if (g1 == Gravity.none) return false;
        else tokens.popFront();

        popSpaces(tokens);
        if (!tokens.empty &&
                tokens.front.tok == Tok.delim &&
                tokens.front.delimCP == '|') {
            tokens.popFront();
            popSpaces(tokens);
            if (tokens.empty) return false;
            immutable g2 = parseGravity(tokens.front);
            if (g2 == Gravity.none) return false;
            else tokens.popFront();

            grav = g1 | g2;
            return true;
        }
        else {
            grav = g1;
            return true;
        }
    }

    private Gravity parseGravity(Token tok)
    {
        if (tok.tok == Tok.ident) {
            switch(tok.str) {
            case "left":        return Gravity.left;
            case "right":       return Gravity.right;
            case "top":         return Gravity.top;
            case "bottom":      return Gravity.bottom;
            case "center":      return Gravity.center;
            case "center-h":    return Gravity.centerHor;
            case "center-v":    return Gravity.centerVer;
            case "fill":        return Gravity.fill;
            case "fill-h":      return Gravity.fillHor;
            case "fill-v":      return Gravity.fillVer;
            case "clip":        return Gravity.clip;
            case "clip-h":      return Gravity.clipHor;
            case "clip-v":      return Gravity.clipVer;
            default: break;
            }
        }
        return Gravity.none;
    }
}
