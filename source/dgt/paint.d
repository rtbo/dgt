/// Paint module describes the stroke and fill paint used during rendering.
module dgt.paint;

import dgt.color;
import dgt.geometry;
import dgt.image;
import dgt.math.vec;

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
    float offset;
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

/// Paint defines the material that fills and strokes paths.
/// It can hold one of the different paint types.
abstract class Paint
{
    private this (PaintType type)
    {
        _type = type;
    }

    /// get the type of this paint
    final @property PaintType type()
    {
        return _type;
    }

    private immutable PaintType _type;
}

/// A solid paint color.
/// The color is represented with sRGBA float channels.
class ColorPaint : Paint
{
    /// Initialize with color
    this (in Color color)
    {
        super(PaintType.color);
        _color = color;
    }

    /// Get the color.
    @property Color color()
    {
        return _color;
    }

    private immutable Color _color;
}

/// Abstract base for gradient paints.
abstract class GradientPaint : Paint
{
    private this(PaintType type, immutable GradientStop[] stops) {
        super(type);
        _stops = stops;
    }

    /// Get the color stops.
    @property immutable(GradientStop)[] stops()
    {
        return _stops;
    }

    private immutable GradientStop[] _stops;
}

/// Gradient that interpolate colors in a linear way between two points.
/// The color on each point on the line from start to end is projected
/// orthogonally on both sides of the line.
class LinearGradientPaint : GradientPaint
{
    /// gradient line direction
    enum Direction
    {
        N, NE, E, SE, S, SW, W, NW,
        angle
    }

    /// Build a linear gradiant paint with an angle in degrees and gradient stops.
    this (in float angle, immutable GradientStop[] stops)
    {
        super(PaintType.linearGradient, stops);
        _direction = Direction.angle;
        _angle = angle;
    }



    /// The angle of the gradient line in degrees. Per CSS specification, 0deg means upwards,
    /// and 90deg means rightwards
    /// This property is only relevant for Direction.angle, use computeAngle for
    /// other cases.
    ///
    /// Returns:
    ///     NaN if direction is not Direction.angle, the angle of the gradient
    ///     line in degrees otherwise.
    @property float angle()
    {
        return _angle;
    }

    /// Returns: The angle of the gradient line in radians.
    float computeAngle(in FSize size) {
        import std.math : atan, PI;
        final switch (_direction) {
            case Direction.N:   return 0f;
            case Direction.E:   return PI / 2;
            case Direction.S:   return PI;
            case Direction.W:   return 3 * PI / 2;
            case Direction.NE:  return atan(size.width / size.height);
            case Direction.SE:  return PI - atan(size.width / size.height);
            case Direction.SW:  return PI + atan(size.width / size.height);
            case Direction.NW:  return 2*PI - atan(size.width / size.height);
            case Direction.angle: return _angle * PI / 180;
        }
    }

    private immutable Direction _direction = Direction.S;
    private immutable float _angle;
}

/// Gradient paint that interpolates the color defined in stops between a focal
/// point and a circle.
class RadialGradientPaint : GradientPaint
{
    this (in FVec2 focal, in FVec2 center, in float radius, immutable GradientStop[] stops)
    {
        super(PaintType.radialGradient, stops);
        _focal = focal;
        _center = center;
        _radius = radius;
    }

    @property FVec2 focal()
    {
        return _focal;
    }
    @property FVec2 center()
    {
        return _center;
    }
    @property float radius()
    {
        return _radius;
    }

    private immutable FVec2 _focal;
    private immutable FVec2 _center;
    private immutable float _radius;
}

/// A Paint that will paint image data
class ImagePaint : Paint
{
    this(immutable(Image) image)
    {
        super(PaintType.image);
        _image = image;
    }

    @property immutable(Image) image()
    {
        return _image;
    }

    private immutable Image _image;
}
