module dgt.vg;

public import dgt.vg.context;
public import dgt.vg.paint;
public import dgt.vg.path;
import dgt.core.resource;
import dgt.image;


/// A vector graphics backend.
/// VG rendering is handled by CPU into in memory images.
interface VgBackend : Disposable
{
    /// Unique identifier of this backend.
    size_t uid() const;

    /// Human readable name of this backend. Mainly for debugging purpose.
    string name() const;

    /// Create a context to draw on the associated with the provided image.
    /// Some restrictions apply for img:
    ///   - rows must be 4 bytes aligned (img.stride % 4 == 0)
    ///   - format cannot be ImageFormat.argb. Use ImageFormat.argbPremult instead.
    VgContext createContext(Image img)
    in {
        assert(img);
        assert(img.stride % 4 == 0);
        assert(img.format != ImageFormat.argb);
    }
}


/// The default VG backend.
@property VgBackend vgDefaultBackend()
{
    import dgt.vg.backend.cairo : cairoBackend;
    return cairoBackend;
}

/// Create a context for the given image with the default VG backend.
@property VgContext createContext(Image img)
{
    return vgDefaultBackend.createContext(img);
}

/// Required bytes alignment for stride (one row of pixels) of an Image
/// that can be used as vector graphics surface.
enum vgStrideAlignment = 4;

/// The minimum number of bytes an image must have for a row of pixels to be
/// usable as a vector graphics surface.
/// This gives number of bytes for a row of image including a 4 bytes alignement.
size_t vgBytesForWidth(in ImageFormat format, in size_t width) pure
{
    immutable size_t bits = format.bpp * width;
    return (((bits + 7) / 8) + vgStrideAlignment-1) & (-vgStrideAlignment);
}

unittest
{
    assert(ImageFormat.a1.vgBytesForWidth(0) == 0);
    assert(ImageFormat.a1.vgBytesForWidth(1) == vgStrideAlignment);
    assert(ImageFormat.a1.vgBytesForWidth(5) == vgStrideAlignment);
    assert(ImageFormat.a1.vgBytesForWidth(48) == 2*vgStrideAlignment);
    assert(ImageFormat.a1.vgBytesForWidth(64) == 2*vgStrideAlignment);
    assert(ImageFormat.a1.vgBytesForWidth(65) == 3*vgStrideAlignment);

    assert(ImageFormat.a8.vgBytesForWidth(1) == vgStrideAlignment);
    assert(ImageFormat.a8.vgBytesForWidth(3) == vgStrideAlignment);
    assert(ImageFormat.a8.vgBytesForWidth(4) == vgStrideAlignment);
    assert(ImageFormat.a8.vgBytesForWidth(5) == 2*vgStrideAlignment);
    assert(ImageFormat.a8.vgBytesForWidth(8) == 2*vgStrideAlignment);
    assert(ImageFormat.a8.vgBytesForWidth(9) == 3*vgStrideAlignment);

    assert(ImageFormat.argb.vgBytesForWidth(1) == vgStrideAlignment);
    assert(ImageFormat.argb.vgBytesForWidth(2) == 2*vgStrideAlignment);
    assert(ImageFormat.argb.vgBytesForWidth(3) == 3*vgStrideAlignment);
    assert(ImageFormat.argb.vgBytesForWidth(4) == 4*vgStrideAlignment);
    assert(ImageFormat.argb.vgBytesForWidth(5) == 5*vgStrideAlignment);
}


/// Check wether img is compatible for vg
@property bool vgCompatible(const(Image) img)
{
    return img.format != ImageFormat.argb && img.stride % 4 == 0;
}

/// Returns img if compatible, otherwise a compatible image built from img.
Image makeVgCompatible(Image img)
out(res)
{
    assert(res.vgCompatible);
}
body
{
    if (img.vgCompatible) return img;

    auto ifmt = img.format;
    bool premult = false;
    if (ifmt == ImageFormat.argb)
    {
        ifmt = ImageFormat.argbPremult;
        premult = true;
    }

    immutable stride = ifmt.vgBytesForWidth(img.width);
    ubyte[] data;
    if (stride == img.stride)
    {
        data = img.data.dup;
    }
    else
    {
        import std.algorithm : min;
        data = new ubyte[stride * img.height];
        const srcData = img.data;
        immutable srcStride = img.stride;
        immutable copyStride = min(stride, srcStride);
        foreach (l; 0 .. img.height)
        {
            data[l*stride .. l*stride+copyStride] =
                srcData[l*srcStride .. l*srcStride+copyStride];
        }
    }
    auto newImg = new Image(data, ifmt, img.width, stride);
    if (premult)
    {
        newImg.apply!premultiply();
    }
    return newImg;
}

