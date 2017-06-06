/// Module gathering all CSS properties implemented by DGT
module dgt.css.properties;

package:

import dgt.css.color;
import dgt.css.style;
import dgt.css.token;
import dgt.css.value;
import dgt.enums;
import dgt.geometry;
import dgt.view.layout;
import dgt.view.style;

import std.experimental.logger;
import std.range;


final class BackgroundColorMetaProperty :
        TStyleMetaProperty!(Color, "background-color")
{
    this()
    {
        super(false, Color(ColorName.transparent));
    }

    override TCSSValue!Color parseValueImpl(Token[] tokens)
    {
        return new TCSSValue!Color(parseColor(tokens));
    }
}

final class FontFamilyMetaProperty :
        TStyleMetaProperty!(string[], "font-family")
{
    this()
    {
        super(true, ["sans-serif"]);
    }

    override TCSSValue!(string[]) parseValueImpl(Token[] tokens)
    {
        import std.algorithm : filter;
        auto toks = tokens.filter!(t => t.tok != Tok.whitespace);

        string[] families;
        while (!toks.empty) {
            if (toks.front.tok == Tok.ident) {
                string fam = toks.front.str;
                toks.popFront();
                while (!toks.empty && toks.front.tok == Tok.ident) {
                    fam ~= " " ~ toks.front.str;
                    toks.popFront();
                }
                families ~= fam;
            }
            else if (toks.front.tok == Tok.str) {
                families ~= toks.front.str;
                toks.popFront();
            }
            if (!toks.empty && toks.front.tok != Tok.comma) {
                return null; // invalid
            }
            else if (!toks.empty) {
                toks.popFront();
            }
        }
        return new TCSSValue!(string[])(families);
    }
}

final class FontWeightMetaProperty :
        TStyleMetaProperty!(int, "font-weight", FontWeight)
{
    enum initialFW = 400;

    this() {
        super(true, initialFW);
    }

    enum RelativeKwd
    {
        lighter, bolder,
    }

    static struct FontWeight {
        enum Type {
            absolute, relative,
        }
        Type type;
        union {
            int abs;
            RelativeKwd rel;
        }
        this(int w) {
            type = Type.absolute;
            abs = w;
        }
        this(RelativeKwd rel) {
            type = Type.relative;
            this.rel = rel;
        }
    }

    override CSSValue parseValueImpl(Token[] tokens)
    {
        popSpaces(tokens);
        if (tokens.empty) return null;
        auto tok = tokens.front;
        if (tok.tok == Tok.ident) {
            switch (tok.str) {
            case "normal":
                return new CSSValue(400);
            case "bold":
                return new CSSValue(700);
            case "lighter":
                return new CSSValue(RelativeKwd.lighter);
            case "bolder":
                return new CSSValue(RelativeKwd.bolder);
            default:
                return null;
            }
        }
        else if (tok.tok == Tok.number && tok.integer) {
            return new CSSValue(cast(int)tok.num);
        }
        else {
            return null;
        }
    }

    override int convert(FontWeight fw, Style target)
    {
        if (fw.type == FontWeight.Type.absolute) {
            return fw.abs;
        }
        else {
            auto p = getProperty(target.parent);
            immutable pfw = p ? p.value : initialFW;

            if (pfw >= 100 && pfw <= 300) {
                return fw.rel == RelativeKwd.lighter ? 100 : 400;
            }
            else if (pfw >= 301 && pfw <= 599) {
                return fw.rel == RelativeKwd.lighter ? 100 : 700;
            }
            else if (pfw >= 600 && pfw <= 799) {
                return fw.rel == RelativeKwd.lighter ? 400 : 900;
            }
            else if (pfw >= 800 && pfw <= 900) {
                return fw.rel == RelativeKwd.lighter ? 700 : 900;
            }
            else {
                warningf("out of range font-weight: %s", pfw);
                return getProperty(target).value;
            }
        }
    }
}

final class FontStyleProperty :
        TStyleMetaProperty!(FontStyle, "font-style")
{
    this() {
        super(true, FontStyle.normal);
    }

    override CSSValue parseValueImpl(Token[] tokens)
    {
        popSpaces(tokens);

        if (tokens.front.tok == Tok.ident) {
            switch (tokens.front.str) {
            case "normal": return new CSSValue(FontStyle.normal);
            case "italic": return new CSSValue(FontStyle.italic);
            case "oblique": return new CSSValue(FontStyle.oblique);
            default:
                break;
            }
        }
        return null;
    }
}

final class FontSizeProperty :
        TStyleMetaProperty!(int, "font-size", FontSize)
{
    this() {
        super(true, FontSize(AbsoluteKwd.medium));

        typeof(relativeMap) rm;
        rm[10] = [ 9, 12];      // xxSmall
        rm[11] = [10, 13];
        rm[12] = [10, 14];      // xSmall
        rm[13] = [11, 15];
        rm[14] = [12, 16];      // small
        rm[15] = [13, 18];
        rm[16] = [14, 19];      // medium
        rm[17] = [15, 20];
        rm[18] = [16, 22];
        rm[19] = [16, 24];      // large
        rm[20] = [17, 25];
        rm[21] = [17, 27];
        rm[22] = [18, 29];
        rm[23] = [18, 30];
        rm[24] = [19, 32];      // xLarge
        rm[25] = [20, 33];
        rm[26] = [20, 34];
        rm[27] = [21, 35];
        rm[28] = [21, 36];
        rm[29] = [22, 37];
        rm[30] = [23, 38];
        rm[31] = [23, 39];
        rm[32] = [24, 40];      // xxLarge

        relativeMap = rm.rehash;
    }

    /// yields size in px
    enum AbsoluteKwd {
        xxSmall     = 10,
        xSmall      = 12,
        small       = 14,
        medium      = 16,
        large       = 19,
        xLarge      = 24,
        xxLarge     = 32,
    }

    enum RelativeKwd {
        smaller, larger,
    }

    int[2][int] relativeMap;

    static struct FontSize {
        enum Type {
            absolute,
            relative,
            length,
            percent,
        }
        Type type;
        union {
            AbsoluteKwd abs;
            RelativeKwd rel;
            Length      len;
            float       per;
        }

        this(AbsoluteKwd kwd) {
            type = Type.absolute;
            abs = kwd;
        }
        this(RelativeKwd kwd) {
            type = Type.relative;
            rel = kwd;
        }
        this(Length l) {
            type = Type.length;
            len = l;
        }
        this(double p) {
            type = Type.percent;
            per = cast(float)p;
        }
    }

    override CSSValueBase parseValueImpl(Token[] tokens)
    {
        popSpaces(tokens);
        auto tok = tokens.front;
        if (tok.tok == Tok.ident) {
            switch(tok.str) {
            case "xx-small":
                return new TCSSValue!FontSize(AbsoluteKwd.xxSmall);
            case "x-small":
                return new TCSSValue!FontSize(AbsoluteKwd.xSmall);
            case "small":
                return new TCSSValue!FontSize(AbsoluteKwd.small);
            case "medium":
                return new TCSSValue!FontSize(AbsoluteKwd.medium);
            case "large":
                return new TCSSValue!FontSize(AbsoluteKwd.large);
            case "x-large":
                return new TCSSValue!FontSize(AbsoluteKwd.xLarge);
            case "xx-large":
                return new TCSSValue!FontSize(AbsoluteKwd.xxLarge);

            case "smaller":
                return new TCSSValue!FontSize(RelativeKwd.smaller);
            case "larger":
                return new TCSSValue!FontSize(RelativeKwd.larger);
            default:
                return null;
            }
        }
        else if (tok.tok == Tok.dimension) {
            Length l = void;
            return parseLength(tok, l) ? new TCSSValue!FontSize(l) : null;
        }
        else if (tok.tok == Tok.percentage) {
            return new TCSSValue!FontSize(tok.num);
        }
        else {
            return null;
        }
    }

    int parentOrInitial(Style target)
    {
        auto p = getProperty(target.parent);
        return p ? p.value : cast(int)AbsoluteKwd.medium;
    }

    override int convert(FontSize fs, Style target)
    {
        import std.math : round;

        final switch (fs.type) {
        case FontSize.Type.absolute:
            return cast(int)fs.abs;
        case FontSize.Type.relative:
            immutable pfs = parentOrInitial(target);
            const pfsRelative = pfs in relativeMap;
            if (pfsRelative) {
                return fs.rel == RelativeKwd.smaller ?
                                    (*pfsRelative)[0] : (*pfsRelative)[1];
            }
            else {
                import std.algorithm : max;
                return cast(int)round(max(9,
                        fs.rel == RelativeKwd.smaller ?
                        pfs/1.2f : pfs*1.2f
                ));
            }
        case FontSize.Type.percent:
            immutable pfs = parentOrInitial(target);
            return cast(int)round(0.01f * pfs * fs.per);
        case FontSize.Type.length:
            immutable lenVal = fs.len.val;
            final switch (fs.len.unit) {
            case Length.Unit.em:
                immutable pfs = parentOrInitial(target);
                return cast(int)round(lenVal * pfs);
            case Length.Unit.ex:
            case Length.Unit.ch:
                // assuming 0.5em
                immutable pfs = parentOrInitial(target);
                return cast(int)round(0.5 * lenVal * pfs);
            case Length.Unit.rem:
                immutable rfs = target.view.isRoot ?
                            cast(int)AbsoluteKwd.medium :
                            target.root.fontSize;
                return cast(int)round(lenVal * rfs);
            case Length.Unit.vw:
                const win = target.view.window;
                immutable width = win.geometry.width;
                return cast(int)round(lenVal * width * 0.01f);
            case Length.Unit.vh:
                const win = target.view.window;
                immutable height = win.geometry.height;
                return cast(int)round(lenVal * height * 0.01f);
            case Length.Unit.vmin:
                import std.algorithm : min;
                const win = target.view.window;
                immutable rect = win.geometry;
                return cast(int)round(lenVal * min(rect.width, rect.height) * 0.01f);
            case Length.Unit.vmax:
                import std.algorithm : max;
                const win = target.view.window;
                immutable rect = win.geometry;
                return cast(int)round(lenVal * max(rect.width, rect.height) * 0.01f);
            case Length.Unit.cm:
                const scr = target.view.window.screen;
                immutable dens = scr.dpi / 2.54f;
                return cast(int)round(dens * lenVal);
            case Length.Unit.mm:
                const scr = target.view.window.screen;
                immutable dens = scr.dpi / 25.4f;
                return cast(int)round(dens * lenVal);
            case Length.Unit.q:
                const scr = target.view.window.screen;
                immutable dens = scr.dpi / (4*25.4f);
                return cast(int)round(dens * lenVal);
            case Length.Unit.inch:
                const scr = target.view.window.screen;
                immutable dens = scr.dpi;
                return cast(int)round(dens * lenVal);
            case Length.Unit.pc:
                const scr = target.view.window.screen;
                immutable dens = scr.dpi / 6f;
                return cast(int)round(dens * lenVal);
            case Length.Unit.pt:
                const scr = target.view.window.screen;
                immutable dens = scr.dpi / 72f;
                return cast(int)round(dens * lenVal);
            case Length.Unit.px:
                return cast(int)round(lenVal);
            }
        }
        return cast(int)AbsoluteKwd.medium;
    }
}

alias HLayoutSizeProperty = LayoutSizeProperty!"layout-width";
alias VLayoutSizeProperty = LayoutSizeProperty!"layout-height";

/// layout-width / layout-height
/// Value:      number | match-parent | wrap-content
/// Inherited:  no
/// Initial:    wrap-content
class LayoutSizeProperty(string n) :
        TStyleMetaProperty!(float, n)
{
    this()
    {
        super(false, wrapContent);
    }

    override CSSValuet parseValueImpl(Token[] tokens)
    {
        popSpaces(tokens);
        if (tokens.front.tok == Tok.number) {
            return new CSSValue(tokens.front.num);
        }
        else if (tokens.front.tok == Tok.ident) {
            switch (tokens.front.str) {
            case "match-parent": return new CSSValue(matchParent);
            case "wrap-content": return new CSSValue(wrapContent);
            default:
                break;
            }
        }
        return null;
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
class LayoutGravityProperty :
            TStyleMetaProperty!(Gravity, "layout-gravity")
{
    this()
    {
        super(false, Gravity.none);
    }

    override CSSValue parseValueImpl(Token[] tokens)
    {
        popSpaces(tokens);
        immutable g1 = parseGravity(tokens);
        popSpaces(tokens);
        if (!tokens.empty &&
                tokens.front.tok == Tok.delim &&
                tokens.front.delimCP == '|') {
            tokens.popFront();
            popSpaces(tokens);
            immutable g2 = tokens.empty ? Gravity.none : parseGravity(tokens);
            return new CSSValue(g1 | g2);
        }
        else {
            return new CSSValue(g1);
        }
    }

    private Gravity parseGravity(ref Token[] tokens)
    {
        assert(!tokens.empty);
        auto tok = tokens.front;
        if (tok.tok == Tok.ident) {
            tokens.popFront();
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
