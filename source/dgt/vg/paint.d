module dgt.vg.paint;

import dgt.core.resource;
import gfx.math.vec;
import dgt.image;

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
    /// linear distance between two points of this stop.
    float offset;
    /// color of this stop.
    FVec4 color;
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
    private PaintType _type;

    private this (PaintType type)
    {
        _type = type;
    }

    final @property PaintType type() const
    {
        return _type;
    }
}

/// A solid paint color.
/// The color is represented with sRGBA float channels.
class ColorPaint : Paint
{
    private FVec4 _color;

    /// Initialize with opaque black.
    this ()
    {
        super(PaintType.color);
        _color = [ 0, 0, 0, 1 ];
    }
    /// Initialize with RGBA color
    this (in float[4] color)
    {
        super(PaintType.color);
        _color = vec(color);
    }
    /// ditto
    this (in FVec4 color)
    {
        super(PaintType.color);
        _color = color;
    }

    /// Get the color.
    @property FVec4 color() const
    {
        return _color;
    }
    /// Set the color.
    @property void color(in float[4] color)
    {
        _color = vec(color);
    }
    /// Set the color.
    @property void color(in FVec4 color)
    {
        _color = color;
    }
}

/// Abstract base for gradient paints.
abstract class GradientPaint : Paint
{
    private GradientStop[] _stops;
    private SpreadMode _spreadMode;

    private this(PaintType type)
    {
        super(type);
    }

    /// Get the color stops.
    @property const(GradientStop)[] stops() const
    {
        return _stops;
    }
    /// Set the color stops.
    @property void stops (GradientStop[] stops)
    {
        _stops = stops;
    }

    /// Get the spread mode.
    @property SpreadMode spreadMode() const
    {
        return _spreadMode;
    }
    /// Set the spread mode.
    @property void spreadMode(in SpreadMode spreadMode)
    {
        _spreadMode = spreadMode;
    }
}

/// Gradient that interpolate colors in a linear way between two points.
/// The color on each point on the line from start to end is projected
/// orthogonally on both sides of the line.
class LinearGradientPaint : GradientPaint
{
    private FVec2 _start;
    private FVec2 _end;

    this()
    {
        super(PaintType.linearGradient);
    }
    this (in FVec2 start, in FVec2 end, GradientStop[] stops)
    {
        super(PaintType.linearGradient);
        _start = start;
        _end = end;
        _stops = stops;
    }

    /// Get the start point (offset 0).
    @property FVec2 start() const
    {
        return _start;
    }
    /// Set the start point (offset 0).
    @property void start(in FVec2 start)
    {
        _start = start;
    }

    /// Get the end point (offset 1).
    @property FVec2 end() const
    {
        return _end;
    }
    /// Set the end point (offset 1).
    @property void end(in FVec2 end)
    {
        _end = end;
    }
}

/// Gradient paint that interpolates the color defined in stops between a focal
/// point and a circle.
class RadialGradientPaint : GradientPaint
{
    private FVec2 _focal;
    private FVec2 _center;
    private float _radius;

    this()
    {
        super(PaintType.radialGradient);
    }

    this (in FVec2 focal, in FVec2 center, in float radius, GradientStop[] stops)
    {
        super(PaintType.radialGradient);
        _focal = focal;
        _center = center;
        _radius = radius;
        _stops = stops;
    }

    @property FVec2 focal() const
    {
        return _focal;
    }
    @property void focal(in FVec2 focal)
    {
        _focal = focal;
    }

    @property FVec2 center() const
    {
        return _center;
    }
    @property void center(in FVec2 center)
    {
        _center = center;
    }

    @property float radius() const
    {
        return _radius;
    }
    @property void radius(in float radius)
    {
        _radius = radius;
    }
}

/// A Paint that will paint image data (a.k.a. texture).
class ImagePaint : Paint
{
    private Image _image;

    this()
    {
        super(PaintType.image);
    }
    this(Image image)
    {
        super(PaintType.image);
        _image = image;
    }

    @property inout(Image) image() inout
    {
        return _image;
    }
}
