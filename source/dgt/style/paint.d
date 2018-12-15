module dgt.style.paint;

import dgt : dgtLog;
import dgt.gfx.paint;
import dgt.css.token;
import std.range;

/// parse CSS token into a paint.
immutable(Paint) parsePaint(Tokens)(ref Tokens tokens)
if (isInputRange!Tokens && is(ElementType!Tokens == Token))
{
    import dgt.gfx.color : Color;
    import dgt.style.color : parseColor;

    tokens.popSpaces();
    if (tokens.empty) return null;

    immutable tok = tokens.front;
    if (tok.tok == Tok.func && tok.str == "linear-gradient") {
        tokens.popFront();
        return parseLinearGradientPaint(tokens);
    }
    else if (tok.tok == Tok.url) {
        return parseImageFromUri(tok.str);
    }
    else {
        Color c;
        if (parseColor(tokens, c)) {
            return new immutable ColorPaint(c);
        }
    }
    return null;
}
/// ditto
immutable(Paint) parsePaint(string css)
{
    import std.utf : byDchar;
    auto tokens = makeTokenInput(byDchar(css), null);
    return parsePaint(tokens);
}

///
unittest
{
    import dgt.gfx.color : Color;
    import gfx.math.approx : approxUlp;

    alias Direction = LinearGradientPaint.Direction;

    auto p1 = parsePaint("linear-gradient(yellow, blue 20%, #0f0)");
    assert(p1.type == PaintType.linearGradient);
    immutable lg1 = cast(immutable(LinearGradientPaint))p1;
    assert(lg1.direction == Direction.S);
    immutable stops1 = lg1.stops;
    assert(stops1.length == 3);
    assert(stops1[0].color == Color.yellow);
    assert(stops1[1].color == Color.blue);
    assert(stops1[2].color == Color(0xff00ff00));
    assert(stops1[0].position.approxUlp(0f));
    assert(stops1[1].position.approxUlp(0.2f));
    assert(stops1[2].position.approxUlp(1f));

    auto p2 = parsePaint("linear-gradient(to top right, red, white, blue)");
    assert(p2.type == PaintType.linearGradient);
    immutable lg2 = cast(immutable(LinearGradientPaint))p2;
    assert(lg2.direction == Direction.NE);
    immutable stops2 = lg2.stops;
    assert(stops2.length == 3);
    assert(stops2[0].color == Color.red);
    assert(stops2[1].color == Color.white);
    assert(stops2[2].color == Color.blue);
    assert(stops2[0].position.approxUlp(0f));
    assert(stops2[1].position.approxUlp(0.5f));
    assert(stops2[2].position.approxUlp(1f));

    auto p3 = parsePaint("linear-gradient(45deg, red, white, rgb(0, 255, 0))");
    assert(p3.type == PaintType.linearGradient);
    immutable lg3 = cast(immutable(LinearGradientPaint))p3;
    assert(lg3.direction == Direction.angle);
    assert(lg3.angle.approxUlp(45));
    immutable stops3 = lg3.stops;
    assert(stops3.length == 3);
    assert(stops3[0].color == Color.red);
    assert(stops3[1].color == Color.white);
    assert(stops3[2].color == Color(0xff00ff00));
    assert(stops3[0].position.approxUlp(0f));
    assert(stops3[1].position.approxUlp(0.5f));
    assert(stops3[2].position.approxUlp(1f));
}

private:

immutable(LinearGradientPaint) parseLinearGradientPaint(Tokens)(ref Tokens tokens)
{
    tokens.popSpaces();
    if (tokens.empty) return null;
    alias Direction = LinearGradientPaint.Direction;

    auto dir = Direction.S;
    float angle;

    immutable tok = tokens.front;
    if (tok.tok == Tok.dimension && tok.unit == "deg") {
        angle = tok.num;
        dir = Direction.angle;
        tokens.popFront();
        tokens.popSpaces();
        if (tokens.empty || tokens.front.tok != Tok.comma) return null;
        tokens.popFront(); // eat ','
    }
    else if (tok.tok == Tok.ident && tok.str == "to") {
        dir = cast(Direction)0;
        while (true) {
            tokens.popFront();
            tokens.popSpaces();
            if (tokens.empty) return null;
            if (tokens.front.tok == Tok.comma) break;
            else if (tokens.front.tok == Tok.ident) {
                switch (tokens.front.str) {
                case "top":
                    dir |= Direction.N;
                    break;
                case "bottom":
                    dir |= Direction.S;
                    break;
                case "right":
                    dir |= Direction.E;
                    break;
                case "left":
                    dir |= Direction.W;
                    break;
                default:
                    return null;
                }
            }
            else {
                return null;
            }
        }
        if (dir == cast(Direction)0                         ||
            ((dir & Direction.N) && (dir & Direction.S))    ||
            ((dir & Direction.E) && (dir & Direction.W)))
        {
            // forbiding non sense such as "to top bottom"
            // things like "to top top top top right" will be accepted however
            return null;
        }
        assert(!tokens.empty && tokens.front.tok == Tok.comma);
        tokens.popFront(); // eat ','
    }

    immutable stops = parseColorStops(tokens);
    if (stops.empty) return null;

    return new immutable LinearGradientPaint(dir, angle, stops);
}

immutable(GradientStop)[] parseColorStops(Tokens)(ref Tokens tokens)
{
    import dgt.style.color : parseColor;
    import dgt.css.token : Tok;

    GradientStop[] stops;
    tokens.popSpaces();

    while (!tokens.empty && tokens.front.tok != Tok.parenCl) {
        GradientStop s;
        if (!parseColor(tokens, s.color)) {
            return null;
        }
        tokens.popSpaces();
        if (!tokens.empty && tokens.front.tok == Tok.percentage) {
            s.position = tokens.front.num / 100f;
            tokens.popFront();
            tokens.popSpaces();
        }
        if (!tokens.empty && tokens.front.tok == Tok.comma) {
            tokens.popFront();
            tokens.popSpaces();
        }
        stops ~= s;
    }

    if (stops.length < 2) return null;

    import std.math : isNaN;

    if (stops[0].position.isNaN) stops[0].position = 0f;
    if (stops[$-1].position.isNaN) stops[$-1].position = 1f;

    float curPos = stops[0].position;
    foreach (ref s; stops[1 .. $]) {
        if (s.position.isNaN) continue;
        if (s.position < curPos) s.position = curPos;
        curPos = s.position;
    }

    foreach (j, ref stop; stops[1 .. $-1]) {
        immutable i = j+1;  // started index 1
        if (stop.position.isNaN) {
            immutable before = stops[i-1].position;
            float after;
            float num = 2f;
            foreach (s; stops[i+1 .. $]) {
                if (s.position.isNaN) {
                    num += 1f;
                }
                else {
                    after = s.position;
                    break;
                }
            }
            assert(!after.isNaN);
            stop.position = before + (after-before) / num;
        }
    }

    debug {
        import std.algorithm : all;
        assert(stops.all!(s => !s.position.isNaN));
    }

    import std.exception : assumeUnique;
    return assumeUnique(stops);
}

RPaint[string] imageCache;

immutable(Paint) parseImageFromUri(in string uri)
{
    import dgt.gfx.image : assumeUnique, Image, ImageFormat;
    import dgt.core.resource : Registry, Resource, retrieveResource;
    import std.algorithm : startsWith;
    import std.typecons : Rebindable;

    auto cached = uri in imageCache;
    if (cached) return *cached;

    try {

        const network = (uri.startsWith("http") || uri.startsWith("ftp"));

        Rebindable!Resource data;
        if (network) {
            data = Registry.tryGet(uri);
        }
        if (!data) {
            data = retrieveResource(uri);
            if (network) {
                Registry.register(uri, data);
            }
        }

        dgtLog.tracef(`decoding image from "%s"`, uri);
        immutable img = assumeUnique(
            Image.loadFromMemory(data, ImageFormat.argbPremult)
        );
        auto pnt = new immutable ImagePaint(img);
        imageCache[uri] = pnt;
        return pnt;
    }
    catch(Exception ex) {
        dgtLog.errorf("could not get paint image from url %s", uri);
        dgtLog.errorf("Error msg:%s", ex.msg);
        return null;
    }
}