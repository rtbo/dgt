module dgt.vg.paint;

enum PaintType
{
    color,
    linearGradient,
    radialGradient,
    //image,
}

struct GradientStop
{
    float offset;
    float[4] color;
}

struct LinearGradient
{
    float[2] p0;
    float[2] p1;
    GradientStop[] stops;
}

struct RadialGradient
{
    float[2] c;
    float[2] f;
    float r;
    GradientStop[] stops;
}

enum SpreadMode
{
    none,
    pad,
    repeat,
    reflect,
}

/// Paint defines the material that fills and strokes pathes.
/// It can hold one of the different paint types.
interface Paint
{
    void dispose();

    @property PaintType type() const;

    @property float[4] color() const;
    @property void color(in float[4] color);

    @property LinearGradient linearGradient() const;
    @property void linearGradient(in LinearGradient gradient);

    @property RadialGradient radialGradient() const;
    @property void radialGradient(in RadialGradient gradient);

    @property SpreadMode speadMode() const;
    @property void spreadMode(in SpreadMode spreadMode);
}
