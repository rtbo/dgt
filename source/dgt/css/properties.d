/// Module gathering all CSS properties implemented by DGT
module dgt.css.properties;

package:

import dgt.css.cascade;
import dgt.css.color;
import dgt.css.token;
import dgt.css.value;
import dgt.geometry;
import dgt.view.style;

import std.experimental.logger;
import std.range;

final class BackgroundColorProperty : CSSProperty
{
    this()
    {
        super(
            "background-color", false,
            new CSSValue!Color(Color(ColorName.transparent))
        );
    }

    override CSSValue!Color parseValueImpl(Token[] tokens)
    {
        return new CSSValue!Color(parseColor(tokens));
    }

    override void applyFromParent(Style target)
    {
        target.backgroundColor = target.parent.backgroundColor;
    }

    override void applyFromValue(Style target, CSSValueBase value)
    {
        auto cv = cast(CSSValue!Color) value;
        assert(cv);
        target.backgroundColor = cv.value;
    }
}

final class FontFamilyProperty : CSSProperty
{
    this()
    {
        super(
            "font-family", true,
            new CSSValue!(string[])(["sans-serif"])
        );
    }

    override CSSValue!(string[]) parseValueImpl(Token[] tokens)
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
        return new CSSValue!(string[])(families);
    }

    override void applyFromParent(Style target)
    {
        target.fontFamily = target.parent.fontFamily;
    }

    override void applyFromValue(Style target, CSSValueBase value)
    {
        auto cv = cast(CSSValue!(string[])) value;
        assert(cv);
        target.fontFamily = cv.value;
    }
}

final class FontWeightProperty : CSSProperty
{
    enum initialFW = 400;
    this() {
        super(
            "font-weight", true,
            new CSSValue!FontWeight(initialFW)
        );
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

    override CSSValue!FontWeight parseValueImpl(Token[] tokens)
    {
        popSpaces(tokens);
        if (tokens.empty) return null;
        auto tok = tokens.front;
        if (tok.tok == Tok.ident) {
            switch (tok.str) {
            case "normal":
                return new CSSValue!FontWeight(400);
            case "bold":
                return new CSSValue!FontWeight(700);
            case "lighter":
                return new CSSValue!FontWeight(RelativeKwd.lighter);
            case "bolder":
                return new CSSValue!FontWeight(RelativeKwd.bolder);
            default:
                return null;
            }
        }
        else if (tok.tok == Tok.number && tok.integer) {
            return new CSSValue!FontWeight(cast(int)tok.num);
        }
        else {
            return null;
        }
    }

    override void applyFromParent(Style target)
    {
        target.fontWeight = target.parent.fontWeight;
    }

    override void applyFromValue(Style target, CSSValueBase value)
    {
        auto val = cast(CSSValue!FontWeight)value;
        assert(val);
        immutable fw = val.value;
        if (fw.type == FontWeight.Type.absolute) {
            target.fontWeight = fw.abs;
        }
        else {
            immutable int pfw = target.parent ? target.parent.fontWeight : initialFW;
            if (pfw >= 100 && pfw <= 300) {
                target.fontWeight = fw.rel == RelativeKwd.lighter ? 100 : 400;
            }
            else if (pfw >= 301 && pfw <= 599) {
                target.fontWeight = fw.rel == RelativeKwd.lighter ? 100 : 700;
            }
            else if (pfw >= 600 && pfw <= 799) {
                target.fontWeight = fw.rel == RelativeKwd.lighter ? 400 : 900;
            }
            else if (pfw >= 800 && pfw <= 900) {
                target.fontWeight = fw.rel == RelativeKwd.lighter ? 700 : 900;
            }
            else {
                warningf("out of range font-weight: %s", pfw);
            }
        }
    }
}

final class FontStyleProperty : CSSProperty
{
    this() {
        super("font-style", true, new CSSValue!FontStyle(FontStyle.normal));
    }

    override CSSValue!FontStyle parseValueImpl(Token[] tokens)
    {
        popSpaces(tokens);
        if (tokens.front.tok == Tok.ident) {
            switch (tokens.front.str) {
            case "normal": return new CSSValue!FontStyle(FontStyle.normal);
            case "italic": return new CSSValue!FontStyle(FontStyle.italic);
            case "oblique": return new CSSValue!FontStyle(FontStyle.oblique);
            default:
                break;
            }
        }
        return null;
    }

    override void applyFromParent(Style target)
    {
        target.fontStyle = target.parent.fontStyle;
    }

    override void applyFromValue(Style target, CSSValueBase value)
    {
        auto val = cast(CSSValue!FontStyle)value;
        assert(val);
        target.fontStyle = val.value;
    }
}

final class FontSizeProperty : CSSProperty
{
    this() {
        super("font-size", true, new CSSValue!FontSize(AbsoluteKwd.medium));

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
                return new CSSValue!FontSize(AbsoluteKwd.xxSmall);
            case "x-small":
                return new CSSValue!FontSize(AbsoluteKwd.xSmall);
            case "small":
                return new CSSValue!FontSize(AbsoluteKwd.small);
            case "medium":
                return new CSSValue!FontSize(AbsoluteKwd.medium);
            case "large":
                return new CSSValue!FontSize(AbsoluteKwd.large);
            case "x-large":
                return new CSSValue!FontSize(AbsoluteKwd.xLarge);
            case "xx-large":
                return new CSSValue!FontSize(AbsoluteKwd.xxLarge);

            case "smaller":
                return new CSSValue!FontSize(RelativeKwd.smaller);
            case "larger":
                return new CSSValue!FontSize(RelativeKwd.larger);
            default:
                return null;
            }
        }
        else if (tok.tok == Tok.dimension) {
            Length l = void;
            return parseLength(tok, l) ? new CSSValue!FontSize(l) : null;
        }
        else if (tok.tok == Tok.percentage) {
            return new CSSValue!FontSize(tok.num);
        }
        else {
            return null;
        }
    }

    override void applyFromParent(Style target)
    {
        target.fontSize = target.parent.fontSize;
    }

    int parentOrInitial(Style target)
    {
        return target.parent ? target.parent.fontSize :
            cast(int)AbsoluteKwd.medium;
    }

    override void applyFromValue(Style target, CSSValueBase value)
    {
        import std.math : round;
        auto val = cast(CSSValue!FontSize)value;
        auto fs = val.value;
        assert(val);
        final switch (fs.type) {
        case FontSize.Type.absolute:
            target.fontSize = cast(int)fs.abs;
            break;
        case FontSize.Type.relative:
            immutable pfs = parentOrInitial(target);
            const pfsRelative = pfs in relativeMap;
            if (pfsRelative) {
                target.fontSize = fs.rel == RelativeKwd.smaller ?
                                    (*pfsRelative)[0] : (*pfsRelative)[1];
            }
            else {
                import std.algorithm : max;
                target.fontSize = cast(int)round(max(9,
                        fs.rel == RelativeKwd.smaller ?
                        pfs/1.2f : pfs*1.2f
                ));
            }
            break;
        case FontSize.Type.percent:
            immutable pfs = parentOrInitial(target);
            target.fontSize = cast(int)round(0.01f * pfs * fs.per);
            break;
        case FontSize.Type.length:
            immutable lenVal = fs.len.val;
            final switch (fs.len.unit) {
            case Length.Unit.em:
                immutable pfs = parentOrInitial(target);
                target.fontSize = cast(int)round(lenVal * pfs);
                break;
            case Length.Unit.ex:
            case Length.Unit.ch:
                // assuming 0.5em
                immutable pfs = parentOrInitial(target);
                target.fontSize = cast(int)round(0.5 * lenVal * pfs);
                break;
            case Length.Unit.rem:
                immutable rfs = target.node.isRoot ?
                            cast(int)AbsoluteKwd.medium :
                            target.root.fontSize;
                target.fontSize = cast(int)round(lenVal * rfs);
                break;
            case Length.Unit.vw:
                const win = target.node.window;
                immutable width = win.geometry.width;
                target.fontSize = cast(int)round(lenVal * width * 0.01f);
                break;
            case Length.Unit.vh:
                const win = target.node.window;
                immutable height = win.geometry.height;
                target.fontSize = cast(int)round(lenVal * height * 0.01f);
                break;
            case Length.Unit.vmin:
                import std.algorithm : min;
                const win = target.node.window;
                immutable rect = win.geometry;
                target.fontSize = cast(int)round(lenVal * min(rect.width, rect.height) * 0.01f);
                break;
            case Length.Unit.vmax:
                import std.algorithm : max;
                const win = target.node.window;
                immutable rect = win.geometry;
                target.fontSize = cast(int)round(lenVal * max(rect.width, rect.height) * 0.01f);
                break;
            case Length.Unit.cm:
                const scr = target.node.window.screen;
                immutable dens = scr.dpi / 2.54f;
                target.fontSize = cast(int)round(dens * lenVal);
                break;
            case Length.Unit.mm:
                const scr = target.node.window.screen;
                immutable dens = scr.dpi / 25.4f;
                target.fontSize = cast(int)round(dens * lenVal);
                break;
            case Length.Unit.q:
                const scr = target.node.window.screen;
                immutable dens = scr.dpi / (4*25.4f);
                target.fontSize = cast(int)round(dens * lenVal);
                break;
            case Length.Unit.inch:
                const scr = target.node.window.screen;
                immutable dens = scr.dpi;
                target.fontSize = cast(int)round(dens * lenVal);
                break;
            case Length.Unit.pc:
                const scr = target.node.window.screen;
                immutable dens = scr.dpi / 6f;
                target.fontSize = cast(int)round(dens * lenVal);
                break;
            case Length.Unit.pt:
                const scr = target.node.window.screen;
                immutable dens = scr.dpi / 72f;
                target.fontSize = cast(int)round(dens * lenVal);
                break;
            case Length.Unit.px:
                target.fontSize = cast(int)round(lenVal);
                break;
            }
            break;
        }
    }
}