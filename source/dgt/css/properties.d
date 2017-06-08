/// Module gathering all CSS properties implemented by DGT
module dgt.css.properties;

import dgt.css.color;
import dgt.css.style;
import dgt.css.token;
import dgt.css.value;
import dgt.enums;
import dgt.geometry;
import dgt.view.layout;
import dgt.view.view;

import std.experimental.logger;
import std.range;


final class BackgroundColorMetaProperty :
        TStyleMetaProperty!(Color, "background-color")
{
    mixin StyleSingleton!(typeof(this));

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
    mixin StyleSingleton!(typeof(this));

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

private struct ParsedFontWeight {
    enum Type {
        absolute, relative,
    }
    enum RelKwd
    {
        lighter, bolder,
    }
    Type type;
    union {
        int abs;
        RelKwd rel;
    }
    this(int w) {
        type = Type.absolute;
        abs = w;
    }
    this(RelKwd rel) {
        type = Type.relative;
        this.rel = rel;
    }
}

final class FontWeightMetaProperty :
        TStyleMetaProperty!(int, "font-weight", ParsedFontWeight)
{
    mixin StyleSingleton!(typeof(this));

    enum initialFW = 400;

    this() {
        super(true, ParsedFontWeight(initialFW));
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
                return new CSSValue(ParsedFontWeight.RelKwd.lighter);
            case "bolder":
                return new CSSValue(ParsedFontWeight.RelKwd.bolder);
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

    override int convert(ParsedFontWeight fw, Style target)
    {
        if (fw.type == ParsedFontWeight.Type.absolute) {
            return fw.abs;
        }
        else {
            auto p = getProperty(target.parent);
            immutable pfw = p ? p.value : initialFW;

            if (pfw >= 100 && pfw <= 300) {
                return fw.rel == ParsedFontWeight.RelKwd.lighter ? 100 : 400;
            }
            else if (pfw >= 301 && pfw <= 599) {
                return fw.rel == ParsedFontWeight.RelKwd.lighter ? 100 : 700;
            }
            else if (pfw >= 600 && pfw <= 799) {
                return fw.rel == ParsedFontWeight.RelKwd.lighter ? 400 : 900;
            }
            else if (pfw >= 800 && pfw <= 900) {
                return fw.rel == ParsedFontWeight.RelKwd.lighter ? 700 : 900;
            }
            else {
                warningf("out of range font-weight: %s", pfw);
                return getProperty(target).value;
            }
        }
    }
}

final class FontStyleMetaProperty :
        TStyleMetaProperty!(FontSlant, "font-style")
{
    mixin StyleSingleton!(typeof(this));

    this() {
        super(true, FontSlant.normal);
    }

    override CSSValue parseValueImpl(Token[] tokens)
    {
        popSpaces(tokens);

        if (tokens.front.tok == Tok.ident) {
            switch (tokens.front.str) {
            case "normal": return new CSSValue(FontSlant.normal);
            case "italic": return new CSSValue(FontSlant.italic);
            case "oblique": return new CSSValue(FontSlant.oblique);
            default:
                break;
            }
        }
        return null;
    }
}

private struct ParsedFontSize {
    enum Type {
        absolute,
        relative,
        length,
        percent,
    }
    /// yields size in px
    enum AbsKwd {
        xxSmall     = 10,
        xSmall      = 12,
        small       = 14,
        medium      = 16,
        large       = 19,
        xLarge      = 24,
        xxLarge     = 32,
    }

    enum RelKwd {
        smaller, larger,
    }
    Type type;
    union {
        AbsKwd abs;
        RelKwd rel;
        Length      len;
        float       per;
    }

    this(AbsKwd kwd) {
        type = Type.absolute;
        abs = kwd;
    }
    this(RelKwd kwd) {
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

final class FontSizeMetaProperty :
        TStyleMetaProperty!(int, "font-size", ParsedFontSize)
{
    mixin StyleSingleton!(typeof(this));

    this() {
        super(true, ParsedFontSize(ParsedFontSize.AbsKwd.medium));

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


    int[2][int] relativeMap;


    override CSSValueBase parseValueImpl(Token[] tokens)
    {
        popSpaces(tokens);
        auto tok = tokens.front;
        if (tok.tok == Tok.ident) {
            switch(tok.str) {
            case "xx-small":
                return new CSSValue(ParsedFontSize.AbsKwd.xxSmall);
            case "x-small":
                return new CSSValue(ParsedFontSize.AbsKwd.xSmall);
            case "small":
                return new CSSValue(ParsedFontSize.AbsKwd.small);
            case "medium":
                return new CSSValue(ParsedFontSize.AbsKwd.medium);
            case "large":
                return new CSSValue(ParsedFontSize.AbsKwd.large);
            case "x-large":
                return new CSSValue(ParsedFontSize.AbsKwd.xLarge);
            case "xx-large":
                return new CSSValue(ParsedFontSize.AbsKwd.xxLarge);

            case "smaller":
                return new CSSValue(ParsedFontSize.RelKwd.smaller);
            case "larger":
                return new CSSValue(ParsedFontSize.RelKwd.larger);
            default:
                return null;
            }
        }
        else if (tok.tok == Tok.dimension) {
            Length l = void;
            return parseLength(tok, l) ? new CSSValue(l) : null;
        }
        else if (tok.tok == Tok.percentage) {
            return new CSSValue(tok.num);
        }
        else {
            return null;
        }
    }

    int fontSizeOrInitial(Style style)
    {
        auto p = getProperty(style);
        return p ? p.value : cast(int)ParsedFontSize.AbsKwd.medium;
    }

    override int convert(ParsedFontSize fs, Style target)
    {
        import std.math : round;

        final switch (fs.type) {
        case ParsedFontSize.Type.absolute:
            return cast(int)fs.abs;
        case ParsedFontSize.Type.relative:
            immutable pfs = fontSizeOrInitial(target.parent);
            const pfsRel = pfs in relativeMap;
            if (pfsRel) {
                return fs.rel == ParsedFontSize.RelKwd.smaller ?
                                    (*pfsRel)[0] : (*pfsRel)[1];
            }
            else {
                import std.algorithm : max;
                return cast(int)round(max(9,
                        fs.rel == ParsedFontSize.RelKwd.smaller ?
                        pfs/1.2f : pfs*1.2f
                ));
            }
        case ParsedFontSize.Type.percent:
            immutable pfs = fontSizeOrInitial(target.parent);
            return cast(int)round(0.01f * pfs * fs.per);
        case ParsedFontSize.Type.length:
            immutable lenVal = fs.len.val;
            final switch (fs.len.unit) {
            case Length.Unit.em:
                immutable pfs = fontSizeOrInitial(target.parent);
                return cast(int)round(lenVal * pfs);
            case Length.Unit.ex:
            case Length.Unit.ch:
                // assuming 0.5em
                immutable pfs = fontSizeOrInitial(target.parent);
                return cast(int)round(0.5 * lenVal * pfs);
            case Length.Unit.rem:
                immutable rfs = fontSizeOrInitial(target.root);
                return cast(int)round(lenVal * rfs);
            case Length.Unit.vw:
                immutable width = target.viewportSize.width;
                return cast(int)round(lenVal * width * 0.01f);
            case Length.Unit.vh:
                immutable height = target.viewportSize.height;
                return cast(int)round(lenVal * height * 0.01f);
            case Length.Unit.vmin:
                import std.algorithm : min;
                immutable size = target.viewportSize;
                return cast(int)round(lenVal * min(size.width, size.height) * 0.01f);
            case Length.Unit.vmax:
                import std.algorithm : max;
                immutable size = target.viewportSize;
                return cast(int)round(lenVal * max(size.width, size.height) * 0.01f);
            case Length.Unit.cm:
                immutable dens = target.dpi / 2.54f;
                return cast(int)round(dens * lenVal);
            case Length.Unit.mm:
                immutable dens = target.dpi / 25.4f;
                return cast(int)round(dens * lenVal);
            case Length.Unit.q:
                immutable dens = target.dpi / (4*25.4f);
                return cast(int)round(dens * lenVal);
            case Length.Unit.inch:
                immutable dens = target.dpi;
                return cast(int)round(dens * lenVal);
            case Length.Unit.pc:
                immutable dens = target.dpi / 6f;
                return cast(int)round(dens * lenVal);
            case Length.Unit.pt:
                immutable dens = target.dpi / 72f;
                return cast(int)round(dens * lenVal);
            case Length.Unit.px:
                return cast(int)round(lenVal);
            }
        }
    }
}

alias LayoutWidthMetaProperty = LayoutSizeMetaProperty!"layout-width";
alias LayoutHeightMetaProperty = LayoutSizeMetaProperty!"layout-height";

/// layout-width / layout-height
/// Value:      number | match-parent | wrap-content
/// Inherited:  no
/// Initial:    wrap-content
class LayoutSizeMetaProperty(string n) :
        TStyleMetaProperty!(float, n)
{
    mixin StyleSingleton!(typeof(this));

    this()
    {
        super(false, wrapContent);
    }

    override CSSValue parseValueImpl(Token[] tokens)
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
class LayoutGravityMetaProperty :
            TStyleMetaProperty!(Gravity, "layout-gravity")
{
    mixin StyleSingleton!(typeof(this));

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
