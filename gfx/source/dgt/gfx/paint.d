/// Paint module describes the stroke and fill paint used during rendering.
module dgt.gfx.paint;

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
    import dgt.gfx.color : Color;

    /// linear position of the stop in the range [0-1].
    float position;
    /// color of this stop.
    Color color;
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

    string toString() const
    {
        import std.format : format;
        return format("Paint [ type = %s ]", _type);
    }

    private immutable PaintType _type;
}

/// A solid paint color.
/// The color is represented with sRGBA float channels.
alias RColorPaint = Rebindable!(immutable(ColorPaint));
/// ditto
immutable class ColorPaint : Paint
{
    import dgt.gfx.color : Color;

    /// Prebuilt common colors
    static immutable ColorPaint black;
    /// ditto
    static immutable ColorPaint white;
    /// ditto
    static immutable ColorPaint red;
    /// ditto
    static immutable ColorPaint green;
    /// ditto
    static immutable ColorPaint blue;

    /// Build a new ColorPaint from a css color name
    static immutable(ColorPaint) opDispatch(string name)()
    {
        return new immutable ColorPaint(mixin("Color."~name));
    }

    private shared static this()
    {
        ColorPaint.black = new immutable ColorPaint(Color.black);
        ColorPaint.white = new immutable ColorPaint(Color.white);
        ColorPaint.red = new immutable ColorPaint(Color.red);
        ColorPaint.green = new immutable ColorPaint(Color.green);
        ColorPaint.blue = new immutable ColorPaint(Color.blue);
    }

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

    override string toString() const
    {
        import std.format : format;
        return format("ColorPaint [ color = %s ]", _color);
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
    import dgt.gfx.geometry : FSize, FVec2;

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

    package(dgt) this (in Direction direction, in float angle, immutable GradientStop[] stops)
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
    final float computeAngle(in FSize size) const
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

    override string toString() const
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
    import dgt.gfx.geometry : FVec2;

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
alias RImagePaint = Rebindable!(immutable(ImagePaint));
/// ditto
immutable class ImagePaint : Paint
{
    import dgt.gfx.image : Image;

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
