/// Paint module describes the stroke and fill paint used during rendering.
module dgt.core.paint;

import dgt.core.color;
import dgt.core.geometry;
import dgt.core.image;
import dgt.math.vec;

import std.experimental.logger;
import std.typecons : Rebindable;

/// The type of a paint.
enum PaintType
{
    /// solid color
    color,
    /// gradient that interpolate a set of colors between two points.
    linearGradient,
    /// gradient that interpolate a set of colors from one point to a circle.
    radialGradient,
    /// paint from image data
    image,
}

/// A gradient stop.
struct GradientStop
{
    /// linear position of the stop in the range [0-1].
    float position;
    /// color of this stop.
    Color color;
}

/// Spread mode for gradient paints.
/// Defines how is specified gradient color outside of range [0, 1].
enum SpreadMode
{
    /// The color is fully transparent.
    none,
    /// The color is padded to the color at 0 or to the color at 1.
    pad,
    /// The pattern is repeated beyond 0 or beyond 1.
    repeat,
    /// The pattern is reflected beyond 0 or beyond 1.
    reflect,
}


/// Paint defines a coloring material.
/// It can hold one of the different paint types.
/// While Paint are mutable references, they only have immutable members.
/// They can therefore safely be sent as-is to the rendering thread.
alias RPaint = Rebindable!(immutable(Paint));
/// ditto
abstract immutable class Paint
{
    private immutable this (PaintType type)
    {
        _type = type;
    }

    /// get the type of this paint
    final @property PaintType type() immutable
    {
        return _type;
    }

    private immutable PaintType _type;
}

/// A solid paint color.
/// The color is represented with sRGBA float channels.
alias RColorPaint = Rebindable!(immutable(ColorPaint));
/// ditto
immutable class ColorPaint : Paint
{
    /// Initialize with color
    immutable this (in Color color)
    {
        super(PaintType.color);
        _color = color;
    }

    /// Get the color.
    final @property Color color()
    {
        return _color;
    }

    string toString()
    {
        import std.format : format;
        return format("ColorPaint [ color = %s ]");
    }

    private Color _color;
}

/// Abstract base for gradient paints.
alias RGradientPaint = Rebindable!(immutable(GradientPaint));
/// ditto
abstract immutable class GradientPaint : Paint
{
    private immutable this(PaintType type, immutable GradientStop[] stops) {
        super(type);
        _stops = stops;
    }

    /// Get the color stops.
    final @property immutable(GradientStop)[] stops()
    {
        return _stops;
    }

    private immutable GradientStop[] _stops;
}

/// Gradient that interpolate colors in a linear way between two points.
/// The color on each point on the line from start to end is projected
/// orthogonally on both sides of the line.
alias RLinearGradientPaint = Rebindable!(immutable(LinearGradientPaint));
/// ditto
immutable class LinearGradientPaint : GradientPaint
{
    /// gradient line direction
    enum Direction
    {
        angle   = 0,

        N       = 0x01,
        S       = 0x02,
        W       = 0x10,
        E       = 0x20,
        NW      = N | W,
        NE      = N | E,
        SW      = S | W,
        SE      = S | E,
    }

    /// Build a linear gradiant paint with an angle in degrees and gradient stops.
    this (in float angle, immutable GradientStop[] stops)
    {
        super(PaintType.linearGradient, stops);
        _direction = Direction.angle;
        _angle = angle;
    }
    /// Build a linear gradiant paint with a direction and gradient stops.
    /// Direction.angle cannot be given here.
    this (in Direction direction, immutable GradientStop[] stops)
    in {
        assert(direction != Direction.angle);
    }
    body {
        super(PaintType.linearGradient, stops);
        _direction = direction;
        _angle = float.nan;
    }

    private this (in Direction direction, in float angle, immutable GradientStop[] stops)
    {
        super(PaintType.linearGradient, stops);
        _direction = direction;
        _angle = angle;
    }

    /// The Direction of this gradient
    final @property Direction direction()
    {
        return _direction;
    }

    /// The angle of the gradient line in degrees. Per CSS specification, 0deg means upwards,
    /// and 90deg means rightwards
    /// This property is only relevant for Direction.angle, use computeAngle for
    /// other cases.
    ///
    /// Returns:
    ///     NaN if direction is not Direction.angle, the angle of the gradient
    ///     line in degrees otherwise.
    final @property float angle()
    {
        return _angle;
    }

    /// Returns: The angle of the gradient line in radians.
    final float computeAngle(in FSize size)
    {
        import std.math : atan, PI;
        final switch (_direction) {
            case Direction.N:       return 0f;
            case Direction.E:       return PI / 2;
            case Direction.S:       return PI;
            case Direction.W:       return 3 * PI / 2;
            case Direction.NE:      return atan(size.width / size.height);
            case Direction.SE:      return PI - atan(size.width / size.height);
            case Direction.SW:      return PI + atan(size.width / size.height);
            case Direction.NW:      return 2*PI - atan(size.width / size.height);
            case Direction.angle:   return _angle * PI / 180;
        }
    }

    string toString()
    {
        import std.format : format;
        string res = format("LinearGradientPaint ( dir=%s, angle=%s, stops=[", _direction, _angle);
        foreach (i, s; stops) {
            res ~= format("{ pos=%s, col=%s }", s.position, s.color);
            if (i != stops.length - 1) {
                res ~= ", ";
            }
        }
        return res ~ "] )";
    }

    private Direction _direction = Direction.S;
    private float _angle;
}

/// Gradient paint that interpolates the color defined in stops between a focal
/// point and a circle.
/// Not supported yet.
alias RRadialGradientPaint = Rebindable!(immutable(RadialGradientPaint));
/// ditto
immutable class RadialGradientPaint : GradientPaint
{
    this (in FVec2 focal, in FVec2 center, in float radius, immutable GradientStop[] stops)
    {
        super(PaintType.radialGradient, stops);
        _focal = focal;
        _center = center;
        _radius = radius;
    }

    final @property FVec2 focal()
    {
        return _focal;
    }
    final @property FVec2 center()
    {
        return _center;
    }
    final @property float radius()
    {
        return _radius;
    }

    private immutable FVec2 _focal;
    private immutable FVec2 _center;
    private immutable float _radius;
}

/// A Paint that will paint image data
/// Not supported yet.
alias RImagePaint = Rebindable!(immutable(ImagePaint));
/// ditto
immutable class ImagePaint : Paint
{
    this(immutable(Image) image)
    {
        super(PaintType.image);
        _image = image;
    }

    final @property immutable(Image) image()
    {
        return _image;
    }

    private Image _image;
}

import dgt.css.token;
import std.range;

/// parse CSS token into a paint.
immutable(Paint) parsePaint(Tokens)(ref Tokens tokens)
if (isInputRange!Tokens && is(ElementType!Tokens == Token))
{
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
    import dgt.math.approx : approxUlp;
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

immutable(Paint) parseImageFromUri(in string uri)
{
    try {
        import dgt.core.resource : Registry, Resource, retrieveResource;
        import std.algorithm : startsWith;

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

        tracef(`decoding image from "%s"`, uri);
        immutable img = assumeUnique(
            Image.loadFromMemory(data, ImageFormat.argbPremult)
        );
        return new immutable ImagePaint(img);
    }
    catch(Exception ex) {
        errorf("could not get paint image from url %s\nError msg:%s", uri, ex.msg);
        return null;
    }
}
