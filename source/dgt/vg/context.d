module dgt.vg.context;

import dgt.core.color : Color;
import dgt.core.image : Image;
import dgt.core.paint : Paint;
import dgt.vg.path : Path;
import dgt.vg.penbrush : Brush, Pen;

import gfx.core.rc : Disposable;
import gfx.math : FMat2x3;

interface VgContext : Disposable
{
    /// Get the image this context is drawing on
    Image image();

    /// Save and restore the context state.
    /// The state include the following properties:
    ///   - brush
    ///   - pen
    ///   - transform
    ///   - clip
    void save();
    /// ditto
    void restore();

    /// Get/Set the transform of the context.
    @property FMat2x3 transform() const;
    /// ditto
    @property void transform(const ref FMat2x3 transform);

    /// Multiply current transform by the given one
    void mulTransform(const ref FMat2x3 transform);

    /// Intersects the current clip path with path
    void clip(immutable(Path) path);

    /// Mask the surface with the alpha plane of the image and paint it
    /// with the current brush paint. img.format must be either ImageFormat.a1 or
    /// ImageFormat.a8.
    void mask(immutable(Image) img, immutable(Paint) paint);

    /// Draw the image to the underlying image.
    void drawImage(immutable(Image) img);

    /// Clear the whole clipping area with the provided color.
    /// This is equivalent has filling the clip path with a color Paint,
    /// but can possibly be faster.
    void clear(in Color color);

    /// Stroke the given path using the given pen
    void stroke(immutable(Path) path, immutable(Pen) pen=null);

    /// Fill the given path using the given brush
    void fill(immutable(Path) path, immutable(Brush) brush=null);
}
