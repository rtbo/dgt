/// Module gathering CSS properties implemented by DGT for views
module dgt.style;

import dgt : dgtStyleLog;
import dgt.font.style;
import dgt.gfx.color;
import dgt.gfx.paint;
import dgt.css.style;
import dgt.css.token;
import dgt.css.value;
import dgt.ui.layout;
import dgt.ui.view;

import std.range;
import std.typecons : rebindable, Nullable;

final class BackgroundMetaProperty : StyleMetaProperty!(RPaint)
{
    mixin StyleSingleton!(typeof(this));

    this()
    {
        super("background", false, RPaint(new immutable ColorPaint(Color.transparent)), false);
    }

    override bool parseValueImpl(ref Token[] tokens, out RPaint paint)
    {
        import dgt.style.paint : parsePaint;

        immutable p = parsePaint(tokens);
        if (p is null) return false;
        paint = rebindable(p);
        return true;
    }
}

final class BackgroundColorMetaProperty : StyleMetaProperty!(Color)
{
    mixin StyleSingleton!(typeof(this));

    this()
    {
        super("background-color", false, Color(ColorName.transparent), false);
    }

    override bool parseValueImpl(ref Token[] tokens, out Color color)
    {
        import dgt.style.color : parseColor;

        return parseColor(tokens, color);
    }
}

final class BorderColorMetaProperty : StyleMetaProperty!(Color)
{
    mixin StyleSingleton!(typeof(this));

    this()
    {
        super("border-color", false, Color(ColorName.transparent), false);
    }

    override bool parseValueImpl(ref Token[] tokens, out Color color)
    {
        import dgt.style.color : parseColor;

        return parseColor(tokens, color);
    }
}

final class BorderWidthMetaProperty : StyleMetaProperty!int
{
    mixin StyleSingleton!(typeof(this));

    enum none = 0;
    enum thin = 1;
    enum medium = 3;
    enum thick = 5;

    this()
    {
        super("border-width", false, none, false);
    }

    override bool parseValueImpl(ref Token[] tokens, out int width)
    {
        tokens.popSpaces();
        if (tokens.empty) return false;
        switch (tokens.front.tok) {
        case Tok.number:
            width = cast(int)tokens.front.num;
            tokens.popFront();
            return true;
        case Tok.dimension:
            if (tokens.front.unit == "px") {
                width = cast(int)tokens.front.num;
                tokens.popFront();
                return true;
            }
            else {
                return false;
            }
        case Tok.ident:
            switch(tokens.front.str) {
            case "none":
                tokens.popFront();
                width = 0;
                return true;
            case "thin":
                tokens.popFront();
                width = thin;
                return true;
            case "medium":
                tokens.popFront();
                width = medium;
                return true;
            case "thick":
                tokens.popFront();
                width = thick;
                return true;
            default:
                return false;
            }
        default:
            return false;
        }
    }
}

final class BorderRadiusMetaProperty : StyleMetaProperty!float
{
    mixin StyleSingleton!(typeof(this));

    this()
    {
        super("border-radius", false, 0, false);
    }

    override bool parseValueImpl(ref Token[] tokens, out float radius)
    {
        tokens.popSpaces();
        if (tokens.empty) return false;
        switch (tokens.front.tok) {
        case Tok.number:
            radius = tokens.front.num;
            tokens.popFront();
            return true;
        case Tok.dimension:
            if (tokens.front.unit == "px") {
                radius = tokens.front.num;
                tokens.popFront();
                return true;
            }
            else {
                return false;
            }
        default:
            return false;
        }
    }
}

private struct ParsedFont
{
    Nullable!FontSlant slant;
    Nullable!ParsedFontWeight parsedWeight;
    ParsedFontSize parsedSize;
    string[] families;
}

/// Font shorthand meta property. Same as CSS3 font shorthand property.
/// Unlike the CSS standard, it is allowed here to not specify the family, in
/// such case it falls back to system-ui. (only the font size is mandatory)
final class FontMetaProperty : StyleShorthandProperty!ParsedFont
{
    mixin StyleSingleton!(typeof(this));

    this()
    {
        super("font", true, [
            cast(IStyleMetaProperty)FontSlantMetaProperty.instance,
            cast(IStyleMetaProperty)FontWeightMetaProperty.instance,
            cast(IStyleMetaProperty)FontSizeMetaProperty.instance,
            cast(IStyleMetaProperty)FontFamilyMetaProperty.instance,
        ]);
    }

    override bool parseValueImpl(ref Token[] tokens, out ParsedFont font)
    {
        FontSlant slant;
        ParsedFontWeight parsedWeight;
        string[] families;
        if (FontSlantMetaProperty.instance.parseValueImpl(tokens, slant)) {
            font.slant = slant;
        }
        if (FontWeightMetaProperty.instance.parseValueImpl(tokens, parsedWeight)) {
            font.parsedWeight = parsedWeight;
        }
        if (!FontSizeMetaProperty.instance.parseValueImpl(tokens, font.parsedSize)) {
            return false;
        }
        if (FontFamilyMetaProperty.instance.parseValueImpl(tokens, families)) {
            font.families = families;
        }
        return true;
    }

    final void applyFromValue(StyleElement target, CSSValueBase val, Origin origin) {
        auto pf = (cast(CSSValue)val).value;

        auto fsp = cast(StyleProperty!FontSlant)target.styleProperty("font-style");
        fsp.setValue(FontSlantMetaProperty.instance.convert(
            pf.slant.isNull ? FontSlantMetaProperty.instance.initialVal : pf.slant, target), origin);

        auto fwp = cast(StyleProperty!FontWeight)target.styleProperty("font-weight");
        fwp.setValue(FontWeightMetaProperty.instance.convert(
            pf.parsedWeight.isNull ? FontWeightMetaProperty.instance.initialVal : pf.parsedWeight, target), origin);

        auto fszp = cast(StyleProperty!int)target.styleProperty("font-size");
        fszp.setValue(FontSizeMetaProperty.instance.convert(pf.parsedSize, target), origin);

        auto ffp = cast(StyleProperty!(string[]))target.styleProperty("font-family");
        ffp.setValue(FontFamilyMetaProperty.instance.convert(
            pf.families.length ? pf.families : FontFamilyMetaProperty.instance.initialVal, target), origin);
    }
}

final class FontFamilyMetaProperty : StyleMetaProperty!(string[])
{
    mixin StyleSingleton!(typeof(this));

    this()
    {
        super("font-family", true, ["system-ui"], false);
    }

    override bool parseValueImpl(ref Token[] tokens, out string[] families)
    {
        while (!tokens.empty) {
            if(tokens.front.tok == Tok.whitespace) {
                tokens.popFront();
                continue;
            }
            if (tokens.front.tok == Tok.ident) {
                string fam = tokens.front.str;
                tokens.popFront();
                while (!tokens.empty && tokens.front.tok == Tok.ident) {
                    if (tokens.front.tok == Tok.whitespace) {
                        fam ~= " ";
                    }
                    else if (tokens.front.tok == Tok.ident) {
                        fam ~= tokens.front.str;
                    }
                    else {
                        break;
                    }
                    tokens.popFront();
                }
                families ~= fam;
            }
            else if (tokens.front.tok == Tok.str) {
                families ~= tokens.front.str;
                tokens.popFront();
            }
            else if (tokens.front.tok == Tok.comma) {
                tokens.popFront();
                tokens.popSpaces();
                if (tokens.empty) return false;
            }
            else {
                break;
            }
        }
        return families.length != 0;
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
        FontWeight abs;
        RelKwd rel;
    }
    this(int w) {
        type = Type.absolute;
        abs = cast(FontWeight)w;
    }
    this(FontWeight w) {
        type = Type.absolute;
        abs = w;
    }
    this(RelKwd rel) {
        type = Type.relative;
        this.rel = rel;
    }
}

final class FontWeightMetaProperty : StyleMetaProperty!(FontWeight, ParsedFontWeight)
{
    mixin StyleSingleton!(typeof(this));

    enum initialFW = FontWeight.normal;

    this() {
        super("font-weight", true, ParsedFontWeight(initialFW), false);
    }

    override bool parseValueImpl(ref Token[] tokens, out ParsedFontWeight pfw)
    {
        popSpaces(tokens);
        if (tokens.empty) return false;
        auto tok = tokens.front;
        if (tok.tok == Tok.ident) {
            switch (tok.str) {
            case "normal":
                pfw = ParsedFontWeight(400);
                tokens.popFront();
                return true;
            case "bold":
                pfw = ParsedFontWeight(700);
                tokens.popFront();
                return true;
            case "lighter":
                pfw.rel = ParsedFontWeight.RelKwd.lighter;
                pfw.type = ParsedFontWeight.Type.relative;
                tokens.popFront();
                return true;
            case "bolder":
                pfw.rel = ParsedFontWeight.RelKwd.bolder;
                pfw.type = ParsedFontWeight.Type.relative;
                tokens.popFront();
                return true;
            default:
                return false;
            }
        }
        else if (tok.tok == Tok.number && tok.integer) {
            pfw = ParsedFontWeight(cast(int)tok.num);
            tokens.popFront();
            return true;
        }
        else {
            return false;
        }
    }

    override FontWeight convert(ParsedFontWeight fw, StyleElement target)
    {
        if (fw.type == ParsedFontWeight.Type.absolute) {
            return fw.abs;
        }
        else {
            auto p = getProperty(target.styleParent);
            immutable pfw = cast(int)(p ? p.value : initialFW);

            if (pfw >= 100 && pfw <= 300) {
                return fw.rel == ParsedFontWeight.RelKwd.lighter ? FontWeight.thin : FontWeight.normal;
            }
            else if (pfw >= 301 && pfw <= 599) {
                return fw.rel == ParsedFontWeight.RelKwd.lighter ? FontWeight.thin : FontWeight.bold;
            }
            else if (pfw >= 600 && pfw <= 799) {
                return fw.rel == ParsedFontWeight.RelKwd.lighter ? FontWeight.normal : FontWeight.extraLarge;
            }
            else if (pfw >= 800 && pfw <= 900) {
                return fw.rel == ParsedFontWeight.RelKwd.lighter ? FontWeight.bold : FontWeight.extraLarge;
            }
            else {
                dgtStyleLog.warningf("out of range font-weight: %s", pfw);
                return getProperty(target).value;
            }
        }
    }
}

final class FontSlantMetaProperty : StyleMetaProperty!FontSlant
{
    mixin StyleSingleton!(typeof(this));

    this() {
        super("font-style", true, FontSlant.normal, false);
    }

    override bool parseValueImpl(ref Token[] tokens, out FontSlant slant)
    {
        popSpaces(tokens);

        if (tokens.front.tok == Tok.ident) {
            switch (tokens.front.str) {
            case "normal":
                slant = FontSlant.normal;
                tokens.popFront();
                return true;
            case "italic":
                slant = FontSlant.italic;
                tokens.popFront();
                return true;
            case "oblique":
                slant = FontSlant.oblique;
                tokens.popFront();
                return true;
            default:
                break;
            }
        }
        return false;
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

final class FontSizeMetaProperty : StyleMetaProperty!(int, ParsedFontSize)
{
    mixin StyleSingleton!(typeof(this));

    this() {
        super("font-size", true, ParsedFontSize(ParsedFontSize.AbsKwd.medium), false);

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


    override bool parseValueImpl(ref Token[] tokens, out ParsedFontSize pfs)
    {
        popSpaces(tokens);
        auto tok = tokens.front;
        if (tok.tok == Tok.ident) {
            switch(tok.str) {
            case "xx-small":
                pfs = ParsedFontSize(ParsedFontSize.AbsKwd.xxSmall);
                tokens.popFront();
                return true;
            case "x-small":
                pfs = ParsedFontSize(ParsedFontSize.AbsKwd.xSmall);
                tokens.popFront();
                return true;
            case "small":
                pfs = ParsedFontSize(ParsedFontSize.AbsKwd.small);
                tokens.popFront();
                return true;
            case "medium":
                pfs = ParsedFontSize(ParsedFontSize.AbsKwd.medium);
                tokens.popFront();
                return true;
            case "large":
                pfs = ParsedFontSize(ParsedFontSize.AbsKwd.large);
                tokens.popFront();
                return true;
            case "x-large":
                pfs = ParsedFontSize(ParsedFontSize.AbsKwd.xLarge);
                tokens.popFront();
                return true;
            case "xx-large":
                pfs = ParsedFontSize(ParsedFontSize.AbsKwd.xxLarge);
                tokens.popFront();
                return true;

            case "smaller":
                pfs = ParsedFontSize(ParsedFontSize.RelKwd.smaller);
                tokens.popFront();
                return true;
            case "larger":
                pfs = ParsedFontSize(ParsedFontSize.RelKwd.larger);
                tokens.popFront();
                return true;
            default:
                return false;
            }
        }
        else if (tok.tok == Tok.dimension) {
            Length l = void;
            if (parseLength(tok, l)) {
                tokens.popFront();
                pfs = ParsedFontSize(l);
                return true;
            }
            else {
                return false;
            }
        }
        else if (tok.tok == Tok.percentage) {
            pfs = ParsedFontSize(tok.num);
            tokens.popFront();
            return true;
        }
        else {
            return false;
        }
    }

    int fontSizeOrInitial(StyleElement style)
    {
        auto p = getProperty(style);
        return p ? p.value : cast(int)ParsedFontSize.AbsKwd.medium;
    }

    override int convert(ParsedFontSize fs, StyleElement target)
    {
        import std.math : round;

        final switch (fs.type) {
        case ParsedFontSize.Type.absolute:
            return cast(int)fs.abs;
        case ParsedFontSize.Type.relative:
            immutable pfs = fontSizeOrInitial(target.styleParent);
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
            immutable pfs = fontSizeOrInitial(target.styleParent);
            return cast(int)round(0.01f * pfs * fs.per);
        case ParsedFontSize.Type.length:
            immutable lenVal = fs.len.val;
            final switch (fs.len.unit) {
            case Length.Unit.em:
                immutable pfs = fontSizeOrInitial(target.styleParent);
                return cast(int)round(lenVal * pfs);
            case Length.Unit.ex:
            case Length.Unit.ch:
                // assuming 0.5em
                immutable pfs = fontSizeOrInitial(target.styleParent);
                return cast(int)round(0.5 * lenVal * pfs);
            case Length.Unit.rem:
                immutable rfs = fontSizeOrInitial(target.styleRoot);
                return cast(int)round(lenVal * rfs);
            case Length.Unit.vw:
                immutable width = target.viewportSize[0];
                return cast(int)round(lenVal * width * 0.01f);
            case Length.Unit.vh:
                immutable height = target.viewportSize[1];
                return cast(int)round(lenVal * height * 0.01f);
            case Length.Unit.vmin:
                import std.algorithm : min;
                immutable size = target.viewportSize;
                return cast(int)round(lenVal * min(size[0], size[1]) * 0.01f);
            case Length.Unit.vmax:
                import std.algorithm : max;
                immutable size = target.viewportSize;
                return cast(int)round(lenVal * max(size[0], size[1]) * 0.01f);
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

final class MarginTopMetaProperty : MarginBaseMetaProperty
{
    mixin StyleSingleton!(typeof(this));

    this() { super("margin-top"); }
}

final class MarginRightMetaProperty : MarginBaseMetaProperty
{
    mixin StyleSingleton!(typeof(this));

    this() { super("margin-right"); }
}

final class MarginBottomMetaProperty : MarginBaseMetaProperty
{
    mixin StyleSingleton!(typeof(this));

    this() { super("margin-bottom"); }
}

final class MarginLeftMetaProperty : MarginBaseMetaProperty
{
    mixin StyleSingleton!(typeof(this));

    this() { super("margin-left"); }
}

abstract class MarginBaseMetaProperty : StyleMetaProperty!(float, Length)
{
    this(string name)
    {
        super(name, false, Length(0f, Length.Unit.px), true);
    }

    override bool parseValueImpl(ref Token[] tokens, out Length len)
    {
        popSpaces(tokens);
        if (!tokens.empty && tokens.front.tok == Tok.dimension) {
            if (parseLength(tokens.front, len)) {
                tokens.popFront();
                return true;
            }
        }
        return false;
    }

    override float convert(Length len, StyleElement target)
    {
        const lenVal = len.val;
        final switch (len.unit) {
        case Length.Unit.em:
        case Length.Unit.ex:
        case Length.Unit.ch:
        case Length.Unit.rem:
        case Length.Unit.vw:
            const width = target.viewportSize[0];
            return lenVal * width * 0.01f;
        case Length.Unit.vh:
            const height = target.viewportSize[1];
            return lenVal * height * 0.01f;
        case Length.Unit.vmin:
            import std.algorithm : min;
            const size = target.viewportSize;
            return lenVal * min(size[0], size[1]) * 0.01f;
        case Length.Unit.vmax:
            import std.algorithm : max;
            const size = target.viewportSize;
            return lenVal * max(size[0], size[1]) * 0.01f;
        case Length.Unit.cm:
            const dens = target.dpi / 2.54f;
            return dens * lenVal;
        case Length.Unit.mm:
            const dens = target.dpi / 25.4f;
            return dens * lenVal;
        case Length.Unit.q:
            const dens = target.dpi / (4*25.4f);
            return dens * lenVal;
        case Length.Unit.inch:
            const dens = target.dpi;
            return dens * lenVal;
        case Length.Unit.pc:
            const dens = target.dpi / 6f;
            return dens * lenVal;
        case Length.Unit.pt:
            const dens = target.dpi / 72f;
            return dens * lenVal;
        case Length.Unit.px:
            return lenVal;
        }
    }
}

private struct ParsedMargin
{
    uint num;
    Length[4] margins;
}

final class MarginMetaProperty : StyleShorthandProperty!ParsedMargin
{
    mixin StyleSingleton!(typeof(this));

    this()
    {
        super("margin", false, [
            cast(IStyleMetaProperty)MarginTopMetaProperty.instance,
            cast(IStyleMetaProperty)MarginRightMetaProperty.instance,
            cast(IStyleMetaProperty)MarginBottomMetaProperty.instance,
            cast(IStyleMetaProperty)MarginRightMetaProperty.instance,
        ]);
    }

    override bool parseValueImpl(ref Token[] tokens, out ParsedMargin pm)
    {
        foreach (i; 0 .. 4) {
            popSpaces(tokens);
            if (!tokens.empty && tokens.front.tok == Tok.dimension) {
                if (parseLength(tokens.front, pm.margins[i])) {
                    tokens.popFront();
                    pm.num++;
                    continue;
                }
            }
            break;
        }
        return pm.num > 0;
    }

    final void applyFromValue(StyleElement target, CSSValueBase val, Origin origin)
    {
        auto tsp = cast(StyleProperty!float)target.styleProperty("margin-top");
        auto rsp = cast(StyleProperty!float)target.styleProperty("margin-right");
        auto bsp = cast(StyleProperty!float)target.styleProperty("margin-bottom");
        auto lsp = cast(StyleProperty!float)target.styleProperty("margin-left");

        void setTop(Length val) {
            tsp.setValue(MarginTopMetaProperty.instance.convert(val, target), origin);
        }
        void setRight(Length val) {
            rsp.setValue(MarginRightMetaProperty.instance.convert(val, target), origin);
        }
        void setBottom(Length val) {
            bsp.setValue(MarginBottomMetaProperty.instance.convert(val, target), origin);
        }
        void setLeft(Length val) {
            lsp.setValue(MarginLeftMetaProperty.instance.convert(val, target), origin);
        }

        const pm = (cast(CSSValue)val).value;

        switch (pm.num)
        {
        case 1:
            setTop(pm.margins[0]);
            setRight(pm.margins[0]);
            setBottom(pm.margins[0]);
            setLeft(pm.margins[0]);
            break;
        case 2:
            setTop(pm.margins[0]);
            setRight(pm.margins[1]);
            setBottom(pm.margins[0]);
            setLeft(pm.margins[1]);
            break;
        case 3:
            setTop(pm.margins[0]);
            setRight(pm.margins[1]);
            setBottom(pm.margins[2]);
            setLeft(pm.margins[1]);
            break;
        case 4:
            setTop(pm.margins[0]);
            setRight(pm.margins[1]);
            setBottom(pm.margins[2]);
            setLeft(pm.margins[3]);
            break;
        default:
            assert(false, "invalid number of margins parsed");
        }
    }
}

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

