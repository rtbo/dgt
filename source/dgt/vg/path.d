module dgt.vg.path;

interface Path
{
    void moveTo(float[2] pos);
    void lineTo(float[2] pos);
    void hLineTo(float xPos);
    void vLineTo(float yPos);
    void quadTo(float[2] control, float[2] pos);
    void cubicTo(float[2] control1, float[2] control2, float[2] pos);
    void smoothQuadTo(float[2] pos);
    void smoothCubicTo(float[2] control2, float[2] pos);
    void shortCcwArcTo(float rh, float rv, float rot, float[2] pos);
    void shortCwArcTo(float rh, float rv, float rot, float[2] pos);
    void largeCcwArcTo(float rh, float rv, float rot, float[2] pos);
    void largeCwArcTo(float rh, float rv, float rot, float[2] pos);
    void close();
}
