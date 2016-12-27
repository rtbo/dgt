module dgt.image;

import dgt.geometry;

import std.exception;

/// Internal representation of an image.
enum ImageFormat
{
    /// 1 bit per pixel alpha value. Used for masking.
    a1,
    /// 8 bits per pixel alpha value. Used for masking.
    a8,
    /// 32 bits per pixel RGB. Upper 8 bits are unused.
    /// Will save some computation time by skipping blending.
    rgb,
    /// 32 bits per pixel ARGB. Stored in machine native byte order.
    /// Less efficient than the premultiplied version for blending.
    /// Some backends only support the premultiplied format in such case
    /// the data will be copied into another premultiplied buffer
    argb,
    /// 32 bits per pixel ARGB. RGB channels are premultiplied by the alpha
    /// channel to boost the alpha blending computations. Stored in machine
    /// native byte order.
    argbPremult,
}

/// How many bits per pixel for a format?
@property size_t bpp(in ImageFormat format)
{
    final switch(format)
    {
    case ImageFormat.a1:
        return 1;
    case ImageFormat.a8:
        return 8;
    case ImageFormat.rgb:
    case ImageFormat.argb:
    case ImageFormat.argbPremult:
        return 32;
    }
}

/// Required bytes alignment for stride (one row of pixels)
enum strideAlignment = 4;

/// The minimum number of bytes an image must have for a row of pixels
size_t bytesForWidth(in ImageFormat format, in size_t width)
{
    immutable size_t bits = format.bpp * width;
    return (((bits + 7) / 8) + strideAlignment-1) & (-strideAlignment);
}

///
unittest
{
    assert(ImageFormat.a1.bytesForWidth(0) == 0);
    assert(ImageFormat.a1.bytesForWidth(1) == strideAlignment);
    assert(ImageFormat.a1.bytesForWidth(5) == strideAlignment);
    assert(ImageFormat.a1.bytesForWidth(48) == 2*strideAlignment);
    assert(ImageFormat.a1.bytesForWidth(64) == 2*strideAlignment);
    assert(ImageFormat.a1.bytesForWidth(65) == 3*strideAlignment);

    assert(ImageFormat.a8.bytesForWidth(1) == strideAlignment);
    assert(ImageFormat.a8.bytesForWidth(3) == strideAlignment);
    assert(ImageFormat.a8.bytesForWidth(4) == strideAlignment);
    assert(ImageFormat.a8.bytesForWidth(5) == 2*strideAlignment);
    assert(ImageFormat.a8.bytesForWidth(8) == 2*strideAlignment);
    assert(ImageFormat.a8.bytesForWidth(9) == 3*strideAlignment);

    assert(ImageFormat.argb.bytesForWidth(1) == strideAlignment);
    assert(ImageFormat.argb.bytesForWidth(2) == 2*strideAlignment);
    assert(ImageFormat.argb.bytesForWidth(3) == 3*strideAlignment);
    assert(ImageFormat.argb.bytesForWidth(4) == 4*strideAlignment);
    assert(ImageFormat.argb.bytesForWidth(5) == 5*strideAlignment);
}

/// Check if a size is usable for an image
@property bool isValidImageSize(in Size size)
{
    return size.width >= 0 && size.height >= 0 &&
        size.width < ushort.max && size.height < ushort.max;
}

/// In-memory representation of an image.
class Image
{
    private ubyte[] _data;
    private ImageFormat _format;
    private ushort _width; // in px
    private ushort _height; // in px
    private size_t _stride; // in bytes
    private size_t _minStride; // in bytes

    /// Allocates an image with format and size
    this(ImageFormat format, ISize size)
    {
        enforce(size.isValidImageSize);
        _width = cast(ushort)size.width;
        _height = cast(ushort)size.height;
        _stride = format.bytesForWidth(size.width);
        _minStride = _stride;
        _data = new ubyte[_stride * _height];
    }

    /// Initialize an $(D Image) with existing $(D data) and $(D format),
    /// $(D width) and $(D stride).
    /// Enforcements:
    ///   - $(D stride >= format.bytesForWidth(width))
    /// Notes:
    ///   - $(D data) is kept within the $(D Image) without any copy or relocation
    ///   - the $(D height) is computed as $(D data.length / stride)
    ///
    /// Stride can be used to pass in a slice of a bigger image.
    this(ubyte[] data, in ImageFormat fmt, in size_t width, in size_t stride)
    {
        import std.format : format;
        immutable minStride = fmt.bytesForWidth(width);
        immutable height = data.length / stride;
        enforce(
            stride >= minStride,
            format("provided stride is %s, minimum requested is %s",
                stride, minStride)
        );
        enforce(isValidImageSize(size(this)));

        _width = cast(ushort)width;
        _height = cast(ushort)height;
        _stride = stride;
        _minStride = minStride;
        _format = fmt;
        _data = data;
    }

    /// Direct access to pixel data.
    @property inout(ubyte)[] data() inout
    {
        return _data;
    }

    /// Direct access to the pixel data of one line
    inout(ubyte)[] line(in size_t l) inout
    in
    {
        assert(l < _height);
    }
    body
    {
        immutable start = l * _stride;
        immutable end = start + _minStride;
        return _data[start .. end];
    }

    /// Get the internal format
    @property ImageFormat format() const
    {
        return _format;
    }

    /// The width of the image
    @property ushort width() const
    {
        return _width;
    }

    /// The height of the image
    @property ushort height() const
    {
        return _height;
    }

    /// Get the number of bytes between two rows
    @property size_t stride() const
    {
        return _stride;
    }
}


/// The size of the image
@property ISize size(const(Image) img)
{
    return ISize(img.width, img.height);
}

// pixel access helpers

/// Get the alpha component of a argb pixel value.
@property ubyte alpha(in uint value)
{
    return (value >> 24) & 0xff;
}
/// Get the red component of a argb or rgb pixel value.
@property ubyte red(in uint value)
{
    return (value >> 16) & 0xff;
}
/// Get the green component of a argb or rgb pixel value.
@property ubyte green(in uint value)
{
    return (value >> 8) & 0xff;
}
/// Get the blue component of a argb or rgb pixel value.
@property ubyte blue(in uint value)
{
    return value & 0xff;
}

/// Builds a rgb pixel value from its components.
uint rgb (in ubyte red, in ubyte green, in ubyte blue)
{
    return (red << 16) | (green << 8) | blue;
}

/// Builds a argb pixel value from its components.
uint argb (in ubyte alpha, in ubyte red, in ubyte green, in ubyte blue)
{
    return (alpha << 24) | (red << 16) | (green << 8) | blue;
}

/// Premultiplies a argb value. Due to integer rounding, the assertion
/// $(D premultiply(unpremultiply(value)) == value) is not guaranteed.
uint premultiply(in uint value)
{
    immutable alpha = value.alpha;
    return argb( alpha,
        cast(ubyte)(value.red * alpha / 255),
        cast(ubyte)(value.green * alpha / 255),
        cast(ubyte)(value.blue * alpha / 255),
    );
}

/// Unpremultiplies a argb value. Due to integer rounding, the assertion
/// $(D unpremultiply(premultiply(value)) == value) is not guaranteed.
uint unpremultiply(in uint value)
{
    immutable alpha = value.alpha;
    return argb( alpha,
        cast(ubyte)(value.red * 255 / alpha),
        cast(ubyte)(value.green * 255 / alpha),
        cast(ubyte)(value.blue * 255 / alpha),
    );
}

/// Get a pixel value from a $(D ImageFormat.a1) scanline.
/// Setter is not given because would be too inefficient. Typically one would
/// instead accumulate at least 8 values to push one byte or more at a time.
bool getA1(in ubyte[] data, in size_t offset)
in
{
    assert(data.length > offset/8);
}
body
{
    return (data[offset / 8] & (0x80 >> (offset & 7))) != 0;
}

/// Get a pixel value from a rgb or argb scanline with an offset in pixel.
uint getArgb(in ubyte[] data, in size_t offset)
in
{
    assert(data.length >= offset*4+4);
}
body
{
    immutable index = offset*4;
    union bi {
        ubyte[4] b;
        uint i;
    }
    bi px = void;
    px.b = data[index .. index+4];
    return px.i;
}

unittest
{
    ubyte[] data = [
        0x01, 0x10, 0x23, 0xf4,
        0x45, 0x23, 0x18, 0x60,
        0xa5, 0x65, 0x53, 0x34,
        0xdb, 0x04, 0xe8, 0x11,
    ];
    version(BigEndian)
    {
        assert(getArgb(data, 0) == 0x011023f4);
        assert(getArgb(data, 1) == 0x45231860);
        assert(getArgb(data, 2) == 0xa5655334);
        assert(getArgb(data, 3) == 0xdb04e811);
    }
    version(LittleEndian)
    {
        assert(getArgb(data, 0) == 0xf4231001);
        assert(getArgb(data, 1) == 0x60182345);
        assert(getArgb(data, 2) == 0x345365a5);
        assert(getArgb(data, 3) == 0x11e804db);
    }
}

/// Set a pixel value within a rgb or argb scanline with an offset in pixel.
void setArgb(ubyte[] data, in size_t offset, in uint argb)
in
{
    assert(data.length >= offset*4+4);
}
body
{
    immutable index = offset*4;
    union bi {
        ubyte[4] b;
        uint i;
    }
    bi px = void;
    px.i = argb;
    data[index .. index+4] = px.b;
}

unittest
{
    ubyte[16] data;
    version(BigEndian)
    {
        data.setArgb(0, 0x011023f4);
        data.setArgb(1, 0x45231860);
        data.setArgb(2, 0xa5655334);
        data.setArgb(3, 0xdb04e811);
    }
    version(LittleEndian)
    {
        data.setArgb(0, 0xf4231001);
        data.setArgb(1, 0x60182345);
        data.setArgb(2, 0x345365a5);
        data.setArgb(3, 0x11e804db);
    }
    assert(data == [
        0x01, 0x10, 0x23, 0xf4,
        0x45, 0x23, 0x18, 0x60,
        0xa5, 0x65, 0x53, 0x34,
        0xdb, 0x04, 0xe8, 0x11,
    ]);
}
