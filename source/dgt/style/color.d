module dgt.style.color;

import dgt.core.color;
import dgt.css.token : Token;
import std.range : ElementType, isInputRange;

/// Attempts to parse a color from the given tokens.
/// Returns: true if successful (out color is set), false otherwise.
bool parseColor(TokenRange)(ref TokenRange tokens, out Color color)
if (isInputRange!TokenRange && is(ElementType!TokenRange == Token))
{
    import dgt.css.token : popSpaces, Tok;
    import std.conv : to;
    import std.exception : enforce;
    import std.range : empty, front, popFront;
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
    import dgt.css.token : popSpaces, Tok;
    import std.algorithm : filter, until;
    import std.range : empty, front, popFront;

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
    import dgt.css.token : Tok;
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
    import dgt.css.token : Tok;
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
    import dgt.css.token : Tok;
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
    import dgt.css.token : Tok;
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
    import gfx.math.vec : fvec;

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
    import gfx.math.vec : fvec;

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
