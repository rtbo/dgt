/// Color module.
/// Provide a common construct to describe colors, and utility to
/// build from/convert to various forms (including CSS).
module dgt.color;

import dgt.css.token;
import dgt.math.vec;

import std.exception;
import std.range;

/// A Color construct that has a uint representation with ARGB components of
/// one byte each in this order.
struct Color
{
    this(uint argb)
    {
        _argb = argb;
    }
    this(in ubyte r, in ubyte g, in ubyte b)
    {
        _argb = 0xff000000  |
                r << 16     |
                g << 8      |
                b;
    }
    this(in ubyte r, in ubyte g, in ubyte b, in ubyte a)
    {
        _argb = a << 24 |
                r << 16 |
                g << 8  |
                b;
    }
    this(in float r, in float g, in float b)
    {
        _argb = 0xff000000 |
                (cast(int)(r*255) & 0xff) << 16 |
                (cast(int)(g*255) & 0xff) << 8  |
                (cast(int)(b*255) & 0xff);
    }
    this(in float r, in float g, in float b, in float a)
    {
        _argb = (cast(int)(a*255) & 0xff) << 24 |
                (cast(int)(r*255) & 0xff) << 16 |
                (cast(int)(g*255) & 0xff) << 8  |
                (cast(int)(b*255) & 0xff);
    }
    this(in ubyte[3] rgb)
    {
        this(rgb[0], rgb[1], rgb[2]);
    }
    this(in ubyte[4] rgba)
    {
        this(rgba[0], rgba[1], rgba[2], rgba[3]);
    }
    this(in float[3] rgb)
    {
        this(rgb[0], rgb[1], rgb[2]);
    }
    this(in float[4] rgba)
    {
        this(rgba[0], rgba[1], rgba[2], rgba[3]);
    }
    this(in FVec3 rgb)
    {
        this(rgb[0], rgb[1], rgb[2]);
    }
    this(in FVec4 rgba)
    {
        this(rgba[0], rgba[1], rgba[2], rgba[3]);
    }
    this(in ColorName name)
    {
        _argb = cast(uint)name;
    }
    this(in string css)
    {
        import std.utf : byDchar;
        auto tokens = makeTokenInput(byDchar(css));
        Color c = void;
        if (parseColor(tokens, c)) {
            _argb = c._argb;
        }
        else {
            import std.experimental.logger : errorf;
            errorf("could not parse %s as a color", css);
        }
    }

    /// Build a Color from its css name.
    static Color opDispatch(string name)()
    if (isColorName!name)
    {
        return Color(mixin("ColorName."~name));
    }

    @property uint argb() const { return _argb; }

    @property ubyte[4] asBytes() const
    {
        return [
            red, green, blue, alpha
        ];
    }
    @property float[4] asFloats() const
    {
        immutable argb = _argb;
        return [
            ((argb >> 16) & 0xff) / 255f,
            ((argb >> 8) & 0xff) / 255f,
            (argb & 0xff) / 255f,
            ((argb >> 24) & 0xff) / 255f,
        ];
    }
    @property FVec4 asVec() const
    {
        immutable argb = _argb;
        return fvec(
            ((argb >> 16) & 0xff) / 255f,
            ((argb >> 8) & 0xff) / 255f,
            (argb & 0xff) / 255f,
            ((argb >> 24) & 0xff) / 255f,
        );
    }

    /// The red component
    @property ubyte red() const
    {
        return (_argb >> 16) & 0xff;
    }
    /// ditto
    @property void red(in ubyte val)
    {
        immutable argb =
            ((alpha << 24) & 0xff000000) |
            ((val << 16) & 0x00ff0000) |
            ((green << 8) & 0x0000ff00) |
            (blue & 0x000000ff);
        _argb = argb;
    }

    /// The green component
    @property ubyte green() const
    {
        return (_argb >> 8) & 0xff;
    }
    /// ditto
    @property void green(in ubyte val)
    {
        immutable argb =
            ((alpha << 24) & 0xff000000) |
            ((red << 16) & 0x00ff0000) |
            ((val << 8) & 0x0000ff00) |
            (blue & 0x000000ff);
        _argb = argb;
    }

    /// The blue component
    @property ubyte blue() const
    {
        return _argb & 0xff;
    }
    /// ditto
    @property void blue(in ubyte val)
    {
        immutable argb =
            ((alpha << 24) & 0xff000000) |
            ((red << 16) & 0x00ff0000) |
            ((green << 8) & 0x0000ff00) |
            (val & 0x000000ff);
        _argb = argb;
    }

    /// The opacity
    @property ubyte alpha() const
    {
        return (_argb >> 24) & 0xff;
    }
    /// ditto
    @property void alpha(in ubyte val)
    {
        immutable argb =
            ((val << 24) & 0xff000000) |
            ((red << 16) & 0x00ff0000) |
            ((green << 8) & 0x0000ff00) |
            (blue & 0x000000ff);
        _argb = argb;
    }

    private uint _argb;
}


/// Standards: https://www.w3.org/TR/css3-color/#svg-color
enum ColorName
{
    transparent             = 0x00000000,

    aliceblue               = 0xfff0f8ff,
    antiquewhite            = 0xfffaebd7,
    aqua                    = 0xff00ffff,
    aquamarine              = 0xff7fffd4,
    azure                   = 0xfff0ffff,
    beige                   = 0xfff5f5dc,
    bisque                  = 0xffffe4c4,
    black                   = 0xff000000,
    blanchedalmond          = 0xffffebcd,
    blue                    = 0xff0000ff,
    blueviolet              = 0xff8a2be2,
    brown                   = 0xffa52a2a,
    burlywood               = 0xffdeb887,
    cadetblue               = 0xff5f9ea0,
    chartreuse              = 0xff7fff00,
    chocolate               = 0xffd2691e,
    coral                   = 0xffff7f50,
    cornflowerblue          = 0xff6495ed,
    cornsilk                = 0xfffff8dc,
    crimson                 = 0xffdc143c,
    cyan                    = 0xff00ffff,
    darkblue                = 0xff00008b,
    darkcyan                = 0xff008b8b,
    darkgoldenrod           = 0xffb8860b,
    darkgray                = 0xffa9a9a9,
    darkgreen               = 0xff006400,
    darkgrey                = 0xffa9a9a9,
    darkkhaki               = 0xffbdb76b,
    darkmagenta             = 0xff8b008b,
    darkolivegreen          = 0xff556b2f,
    darkorange              = 0xffff8c00,
    darkorchid              = 0xff9932cc,
    darkred                 = 0xff8b0000,
    darksalmon              = 0xffe9967a,
    darkseagreen            = 0xff8fbc8f,
    darkslateblue           = 0xff483d8b,
    darkslategray           = 0xff2f4f4f,
    darkslategrey           = 0xff2f4f4f,
    darkturquoise           = 0xff00ced1,
    darkviolet              = 0xff9400d3,
    deeppink                = 0xffff1493,
    deepskyblue             = 0xff00bfff,
    dimgray                 = 0xff696969,
    dimgrey                 = 0xff696969,
    dodgerblue              = 0xff1e90ff,
    firebrick               = 0xffb22222,
    floralwhite             = 0xfffffaf0,
    forestgreen             = 0xff228b22,
    fuchsia                 = 0xffff00ff,
    gainsboro               = 0xffdcdcdc,
    ghostwhite              = 0xfff8f8ff,
    gold                    = 0xffffd700,
    goldenrod               = 0xffdaa520,
    gray                    = 0xff808080,
    green                   = 0xff008000,
    greenyellow             = 0xffadff2f,
    grey                    = 0xff808080,
    honeydew                = 0xfff0fff0,
    hotpink                 = 0xffff69b4,
    indianred               = 0xffcd5c5c,
    indigo                  = 0xff4b0082,
    ivory                   = 0xfffffff0,
    khaki                   = 0xfff0e68c,
    lavender                = 0xffe6e6fa,
    lavenderblush           = 0xfffff0f5,
    lawngreen               = 0xff7cfc00,
    lemonchiffon            = 0xfffffacd,
    lightblue               = 0xffadd8e6,
    lightcoral              = 0xfff08080,
    lightcyan               = 0xffe0ffff,
    lightgoldenrodyellow    = 0xfffafad2,
    lightgray               = 0xffd3d3d3,
    lightgreen              = 0xff90ee90,
    lightgrey               = 0xffd3d3d3,
    lightpink               = 0xffffb6c1,
    lightsalmon             = 0xffffa07a,
    lightseagreen           = 0xff20b2aa,
    lightskyblue            = 0xff87cefa,
    lightslategray          = 0xff778899,
    lightslategrey          = 0xff778899,
    lightsteelblue          = 0xffb0c4de,
    lightyellow             = 0xffffffe0,
    lime                    = 0xff00ff00,
    limegreen               = 0xff32cd32,
    linen                   = 0xfffaf0e6,
    magenta                 = 0xffff00ff,
    maroon                  = 0xff800000,
    mediumaquamarine        = 0xff66cdaa,
    mediumblue              = 0xff0000cd,
    mediumorchid            = 0xffba55d3,
    mediumpurple            = 0xff9370db,
    mediumseagreen          = 0xff3cb371,
    mediumslateblue         = 0xff7b68ee,
    mediumspringgreen       = 0xff00fa9a,
    mediumturquoise         = 0xff48d1cc,
    mediumvioletred         = 0xffc71585,
    midnightblue            = 0xff191970,
    mintcream               = 0xfff5fffa,
    mistyrose               = 0xffffe4e1,
    moccasin                = 0xffffe4b5,
    navajowhite             = 0xffffdead,
    navy                    = 0xff000080,
    oldlace                 = 0xfffdf5e6,
    olive                   = 0xff808000,
    olivedrab               = 0xff6b8e23,
    orange                  = 0xffffa500,
    orangered               = 0xffff4500,
    orchid                  = 0xffda70d6,
    palegoldenrod           = 0xffeee8aa,
    palegreen               = 0xff98fb98,
    paleturquoise           = 0xffafeeee,
    palevioletred           = 0xffdb7093,
    papayawhip              = 0xffffefd5,
    peachpuff               = 0xffffdab9,
    peru                    = 0xffcd853f,
    pink                    = 0xffffc0cb,
    plum                    = 0xffdda0dd,
    powderblue              = 0xffb0e0e6,
    purple                  = 0xff800080,
    red                     = 0xffff0000,
    rosybrown               = 0xffbc8f8f,
    royalblue               = 0xff4169e1,
    saddlebrown             = 0xff8b4513,
    salmon                  = 0xfffa8072,
    sandybrown              = 0xfff4a460,
    seagreen                = 0xff2e8b57,
    seashell                = 0xfffff5ee,
    sienna                  = 0xffa0522d,
    silver                  = 0xffc0c0c0,
    skyblue                 = 0xff87ceeb,
    slateblue               = 0xff6a5acd,
    slategray               = 0xff708090,
    slategrey               = 0xff708090,
    snow                    = 0xfffffafa,
    springgreen             = 0xff00ff7f,
    steelblue               = 0xff4682b4,
    tan                     = 0xffd2b48c,
    teal                    = 0xff008080,
    thistle                 = 0xffd8bfd8,
    tomato                  = 0xffff6347,
    turquoise               = 0xff40e0d0,
    violet                  = 0xffee82ee,
    wheat                   = 0xfff5deb3,
    white                   = 0xffffffff,
    whitesmoke              = 0xfff5f5f5,
    yellow                  = 0xffffff00,
    yellowgreen             = 0xff9acd32,
}

/// Whether the string `n` refers to a CSS color
template isColorName(string n)
{
    enum isColorName = is(typeof({
        auto c = mixin("ColorName."~n);
    }));
}

static assert(isColorName!"violet");
static assert(isColorName!"transparent");
static assert(!isColorName!"blablaba");

/// An AA that allow to look-up colors by the extended CSS color name.
/// To do such look-up at compile time, use `Color.<css name>` dispatch.
/// Standards: https://www.w3.org/TR/css3-color/#svg-color
@property immutable(Color[string]) cssColors()
{
    import std.conv : to;
    import std.exception : assumeUnique;
    import std.meta : NoDuplicates;
    import std.traits : EnumMembers;

    static Color[string] colors;
    if (colors.length == 0) {
        foreach(em; NoDuplicates!(EnumMembers!ColorName)) {
            colors[em.to!string] = Color(cast(uint)em);
        }
        // adding duplicates that do not yield a string by EnumMembers
        colors["cyan"]              = Color(ColorName.cyan);
        colors["darkgrey"]          = Color(ColorName.darkgrey);
        colors["darkslategrey"]     = Color(ColorName.darkslategrey);
        colors["grey"]              = Color(ColorName.grey);
        colors["lightgrey"]         = Color(ColorName.lightgrey);
        colors["lightslategrey"]    = Color(ColorName.lightslategrey);
        colors["magenta"]           = Color(ColorName.magenta);
        colors["slategrey"]         = Color(ColorName.slategrey);
        colors = colors.rehash;
    }
    return assumeUnique(colors);
}
/// use of opDispatch ctor
unittest
{
    auto c = Color.cyan;
    assert(c.argb == cast(int)ColorName.cyan);
}


/// Convert a color from HSV representation into RGB
/// Params:
///     h:      Hue, in range [0-1[
///     s:      Saturation, in range [0-1]
///     v:      Value, in range [0-1]
FVec3 hsvToRGB(in float h, in float s, in float v) pure
in {
    assert(h >= 0 && h < 1);
    assert(s >= 0 && s <= 1);
    assert(v >= 0 && v <= 1);
}
body {
    import std.math : abs;
    immutable c = s * v;
    immutable x = c * (1 - abs( ((h*6) % 2) - 1 ));
    immutable m = v - c;

    enum float yellow   = 1.0/60.0;
    enum float green    = 2.0/60.0;
    enum float cyan     = 3.0/60.0;
    enum float blue     = 4.0/60.0;
    enum float magenta  = 5.0/60.0;

    if (h < yellow)
        return fvec(c+m, x+m, m);
    else if (h < green)
        return fvec(x+m, c+m, m);
    else if (h < cyan)
        return fvec(m, c+m, x+m);
    else if (h < blue)
        return fvec(m, x+m, c+m);
    else if (h < magenta)
        return fvec(x+m, m, c+m);
    else
        return fvec(c+m, m, x+m);
}

/// Convert a color from HSL representation into RGB
/// Params:
///     h:      Hue, in range [0-1[
///     s:      Saturation, in range [0-1]
///     l:      Lightness, in range [0-1]
FVec3 hslToRGB(in float h, in float s, in float l) pure
in {
    assert(h >= 0 && h < 1);
    assert(s >= 0 && s <= 1);
    assert(l >= 0 && l <= 1);
}
body {
    import std.math : abs;
    immutable c = (1 - abs(2*l - 1)) * s;
    immutable x = c * (1 - abs( ((h*6) % 2) - 1 ));
    immutable m = l - c/2;

    enum float yellow   = 1.0/60.0;
    enum float green    = 2.0/60.0;
    enum float cyan     = 3.0/60.0;
    enum float blue     = 4.0/60.0;
    enum float magenta  = 5.0/60.0;

    if (h < yellow)
        return fvec(c+m, x+m, m);
    else if (h < green)
        return fvec(x+m, c+m, m);
    else if (h < cyan)
        return fvec(m, c+m, x+m);
    else if (h < blue)
        return fvec(m, x+m, c+m);
    else if (h < magenta)
        return fvec(x+m, m, c+m);
    else
        return fvec(c+m, m, x+m);
}

/// convert a RGB color into a HSV representation
FVec3 rgbToHSV(in float r, in float g, in float b)
{
    import std.algorithm : max, min;
    immutable cmin = min(r, g, b);
    immutable cmax = max(r, g, b);
    immutable delta = cmax - cmin;

    FVec3 hsv = void;

    if (delta == 0) {
        hsv[0] = 0;
    }
    else if (cmax == r) {
        hsv[0] = (((g - b)/delta) % 6) / 6f;
    }
    else if (cmax == g) {
        hsv[0] = (((b - r)/delta) + 2) / 6f;
    }
    else {
        hsv[0] = (((r - g)/delta) + 4) / 6f;
    }

    hsv[1] = cmax == 0 ? 0 : delta/cmax;
    hsv[2] = cmax;

    return hsv;
}

/// convert a RGB color into a HSL representation
FVec3 rgbToHSL(in float r, in float g, in float b)
{
    import std.algorithm : max, min;
    import std.math : abs;

    immutable cmin = min(r, g, b);
    immutable cmax = max(r, g, b);
    immutable delta = cmax - cmin;

    FVec3 hsl = void;

    if (delta == 0) {
        hsl[0] = 0;
    }
    else if (cmax == r) {
        hsl[0] = (((g - b)/delta) % 6) / 6f;
    }
    else if (cmax == g) {
        hsl[0] = (((b - r)/delta) + 2) / 6f;
    }
    else {
        hsl[0] = (((r - g)/delta) + 4) / 6f;
    }

    immutable l = (cmax + cmin) / 2;
    immutable div = (1 - abs(2*l - 1));
    hsl[1] = div == 0 ? 0 : delta/div;
    hsl[2] = l;

    return hsl;
}

/// Attempts to parse a color from the given tokens.
/// Returns: true if successful (out color is set), false otherwise.
bool parseColor(TokenRange)(ref TokenRange tokens, out Color color)
if (isInputRange!TokenRange && is(ElementType!TokenRange == Token))
{
    import std.conv : to;
    import std.uni : toLower;

    tokens.popSpaces();

    if (tokens.empty) return false;

    switch(tokens.front.tok) {
    case Tok.hash:
        auto hexStr = tokens.front.str;
        switch(hexStr.length) {
        case 3:
            hexStr = [
                hexStr[0], hexStr[0],
                hexStr[1], hexStr[1],
                hexStr[2], hexStr[2],
            ];
            break;
        case 6:
            break;
        default:
            throw new Exception("unsupported color hash string: "~hexStr);
        }
        hexStr = "ff" ~ hexStr.toLower;
        assert(hexStr.length == 8);
        color = Color(hexStr.to!uint(16));
        tokens.popFront();
        return true;
    case Tok.ident:
        auto ident = tokens.front.str;
        auto cp = ident in cssColors;
        enforce(cp !is null, ident ~ " is not a valid CSS color");
        color = *cp;
        tokens.popFront();
        return true;
    case Tok.func:
        if (tokens.front.str == "rgb") {
            tokens.popFront();
            return parseRGB(tokens, color);
        }
        else if (tokens.front.str == "rgba") {
            tokens.popFront();
            return parseRGBA(tokens, color);
        }
        else if (tokens.front.str == "hsv") {
            tokens.popFront();
            return parseHSV(tokens, color);
        }
        else if (tokens.front.str == "hsva") {
            tokens.popFront();
            return parseHSVA(tokens, color);
        }
        else if (tokens.front.str == "hsl") {
            tokens.popFront();
            return parseHSL(tokens, color);
        }
        else if (tokens.front.str == "hsla") {
            tokens.popFront();
            return parseHSLA(tokens, color);
        }
        else {
            return false;
        }
    default:
        return false;
    }
}

private Token[] funcArgs(Tokens)(ref Tokens tokens)
{
    import std.algorithm : filter, until;
    Token[] args;
    while(!tokens.empty) {
        tokens.popSpaces();
        if (tokens.empty) break;
        if (tokens.front.tok == Tok.parenCl) {
            tokens.popFront();
            break;
        }
        if (tokens.front.tok == Tok.comma) {
            tokens.popFront();
            continue;  // possibly ignores empty arg
        }
        args ~= tokens.front;
        tokens.popFront();
    }
    return args;
}

private bool getComp(Token tok, out ubyte res)
{
    import std.algorithm : clamp;
    switch(tok.tok) {
    case Tok.number:
        res = cast(ubyte)clamp(tok.num, 0, 255);
        return true;
    case Tok.percentage:
        res = cast(ubyte)clamp(tok.num*255/100f, 0, 255);
        return true;
    default:
        return false;
    }
}
private bool getNComp(Token tok, out float res)
{
    import std.algorithm : clamp;
    switch(tok.tok) {
    case Tok.number:
        res = clamp(tok.num, 0, 1);
        return true;
    case Tok.percentage:
        res = clamp(tok.num/100f, 0, 1);
        return true;
    default:
        return false;
    }
}
private bool getAlpha(Token tok, out float res)
{
    import std.algorithm : clamp;
    switch(tok.tok) {
    case Tok.number:
        res = clamp(tok.num, 0, 1);
        return true;
    default:
        return false;
    }
}
private bool getAngle(Token tok, out float res)
{
    import std.algorithm : clamp;
    switch(tok.tok) {
    case Tok.number:
        res = tok.num / 360f;
        while (res < 0) res += 1;
        while (res >= 1) res -= 1;
        return true;
    default:
        return false;
    }
}

private bool parseRGB(Tokens)(ref Tokens tokens, out Color col)
{
    auto args = funcArgs(tokens);
    if (args.length != 3) return false;
    ubyte r = void, g = void, b = void;
    if (!getComp(args[0], r)) return false;
    if (!getComp(args[1], g)) return false;
    if (!getComp(args[2], b)) return false;
    col = Color(r, g, b);
    return true;
}

private bool parseRGBA(Tokens)(ref Tokens tokens, out Color col)
{
    auto args = funcArgs(tokens);
    if (args.length != 4) return false;
    ubyte r = void, g = void, b = void;
    float a = void;
    if (!getComp(args[0], r)) return false;
    if (!getComp(args[1], g)) return false;
    if (!getComp(args[2], b)) return false;
    if (!getAlpha(args[3], a)) return false;
    col = Color(r, g, b, cast(ubyte)a*255);
    return true;
}

private bool parseHSV(Tokens)(ref Tokens tokens, out Color col)
{
    auto args = funcArgs(tokens);
    if (args.length != 3) return false;
    float h = void, s = void, v = void;
    if (!getAngle(args[0], h)) return false;
    if (!getNComp(args[1], s)) return false;
    if (!getNComp(args[2], v)) return false;
    col = Color(hsvToRGB(h, s, v));
    return true;
}

private bool parseHSVA(Tokens)(ref Tokens tokens, out Color col)
{
    auto args = funcArgs(tokens);
    if (args.length != 3) return false;
    float h = void, s = void, v = void, a = void;
    if (!getAngle(args[0], h)) return false;
    if (!getNComp(args[1], s)) return false;
    if (!getNComp(args[2], v)) return false;
    if (!getAlpha(args[3], a)) return false;
    col = Color(fvec(hsvToRGB(h, s, v), a));
    return true;
}

private bool parseHSL(Tokens)(ref Tokens tokens, out Color col)
{
    auto args = funcArgs(tokens);
    if (args.length != 3) return false;
    float h = void, s = void, l = void;
    if (!getAngle(args[0], h)) return false;
    if (!getNComp(args[1], s)) return false;
    if (!getNComp(args[2], l)) return false;
    col = Color(hslToRGB(h, s, l));
    return true;
}

private bool parseHSLA(Tokens)(ref Tokens tokens, out Color col)
{
    auto args = funcArgs(tokens);
    if (args.length != 3) return false;
    float h = void, s = void, l = void, a = void;
    if (!getAngle(args[0], h)) return false;
    if (!getNComp(args[1], s)) return false;
    if (!getNComp(args[2], l)) return false;
    if (!getAlpha(args[3], a)) return false;
    col = Color(fvec(hslToRGB(h, s, l), a));
    return true;
}
