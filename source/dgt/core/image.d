/// In-memory pixel images.
module dgt.core.image;

import dgt.core.geometry;
import dgt.core.rc;

import std.exception;
import std.typecons : Nullable, Flag, Yes, No;

/// Internal representation of an image.
enum ImageFormat
{
    /// 1 bit per pixel alpha value. Used for masking.
    a1,
    /// 8 bits per pixel alpha value. Used for masking.
    a8,
    /// 32 bits per pixel RGB. Upper 8 bits are unused.
    /// Will save some computation time by skipping blending.
    xrgb,
    /// 32 bits per pixel ARGB. Stored in machine native byte order.
    /// Do not support vector graphics rendering.
    argb,
    /// 32 bits per pixel ARGB. RGB channels are premultiplied by the alpha
    /// channel to boost the alpha blending computations. Stored in machine
    /// native byte order.
    argbPremult,
}

/// Whether the format only has alpha component.
@property bool isPureAlpha(in ImageFormat format)
{
    return format == ImageFormat.a1 || format == ImageFormat.a8;
}

/// Whether the format has alpha component.
@property bool hasAlpha(in ImageFormat format)
{
    return format != ImageFormat.xrgb;
}

/// Whether the format has color components.
@property bool hasRgb(in ImageFormat format)
{
    return !format.isPureAlpha;
}

/// How many bits per pixel for a format?
@property size_t bpp(in ImageFormat format) pure
{
    final switch(format)
    {
    case ImageFormat.a1:
        return 1;
    case ImageFormat.a8:
        return 8;
    case ImageFormat.xrgb:
    case ImageFormat.argb:
    case ImageFormat.argbPremult:
        return 32;
    }
}

/// Required bytes alignment for stride (one row of pixels) of an Image
/// that can be used as texture graphics surface.
enum strideAlignment = 4;

/// The minimum number of bytes an image must have for a row of pixels to be
/// usable as a texture graphics surface.
/// This gives number of bytes for a row of image including a 4 bytes alignment.
size_t alignedStrideForWidth(in ImageFormat format, in size_t width) pure
{
    immutable size_t bits = format.bpp * width;
    return (((bits + 7) / 8) + strideAlignment-1) & (-strideAlignment);
}

unittest
{
    assert(ImageFormat.a1.alignedStrideForWidth(0) == 0);
    assert(ImageFormat.a1.alignedStrideForWidth(1) == strideAlignment);
    assert(ImageFormat.a1.alignedStrideForWidth(5) == strideAlignment);
    assert(ImageFormat.a1.alignedStrideForWidth(48) == 2*strideAlignment);
    assert(ImageFormat.a1.alignedStrideForWidth(64) == 2*strideAlignment);
    assert(ImageFormat.a1.alignedStrideForWidth(65) == 3*strideAlignment);

    assert(ImageFormat.a8.alignedStrideForWidth(1) == strideAlignment);
    assert(ImageFormat.a8.alignedStrideForWidth(3) == strideAlignment);
    assert(ImageFormat.a8.alignedStrideForWidth(4) == strideAlignment);
    assert(ImageFormat.a8.alignedStrideForWidth(5) == 2*strideAlignment);
    assert(ImageFormat.a8.alignedStrideForWidth(8) == 2*strideAlignment);
    assert(ImageFormat.a8.alignedStrideForWidth(9) == 3*strideAlignment);

    assert(ImageFormat.argb.alignedStrideForWidth(1) == strideAlignment);
    assert(ImageFormat.argb.alignedStrideForWidth(2) == 2*strideAlignment);
    assert(ImageFormat.argb.alignedStrideForWidth(3) == 3*strideAlignment);
    assert(ImageFormat.argb.alignedStrideForWidth(4) == 4*strideAlignment);
    assert(ImageFormat.argb.alignedStrideForWidth(5) == 5*strideAlignment);
}

/// Check if a size is usable for an image
@property bool isValidImageSize(in ISize size) pure
{
    return size.width >= 0 && size.height >= 0 &&
        size.width < ushort.max && size.height < ushort.max;
}

/// Format of an image serialized into a file
enum ImageFileFormat
{
    png,
    jpeg,
}

/// In-memory representation of an image.
class Image
{
    private ubyte[] _data;
    private ImageFormat _format;
    private ushort _width; // in px
    private ushort _height; // in px
    private size_t _stride; // in bytes

    /// Allocates an image with format and size.
    /// Image stride is given by max(minStride, format.minStrideForWidth(size.width))
    /// The pixel content is not initialized.
    this(ImageFormat format, ISize size, size_t minStride=0)
    {
        import std.array : uninitializedArray;
        import std.algorithm : max;
        enforce(size.isValidImageSize);
        _format = format;
        _width = cast(ushort)size.width;
        _height = cast(ushort)size.height;
        _stride = max(minStride, format.alignedStrideForWidth(size.width));
        _data = uninitializedArray!(ubyte[])(_stride * _height);
    }

    /// Initialize an $(D Image) with existing $(D data) and $(D format),
    /// $(D width) and $(D stride).
    /// Notes:
    ///   - $(D data) is kept within the $(D Image) without any copy or relocation
    ///   - the $(D height) is computed as $(D data.length / stride). The data slice
    ///     must be therefore adjusted to reflect the correct height;
    ///
    /// Stride can be used to pass in a slice of a bigger image.
    this(ubyte[] data, in ImageFormat fmt, in size_t width, in size_t stride)
    {
        immutable height = data.length / stride;
        immutable bytesPerPx = fmt.bpp / 8;

        enforce(data.length >= stride && data.length % stride == 0);
        enforce(width <= stride/bytesPerPx, "image from data: invalid width (bigger than stride)");
        enforce(isValidImageSize(ISize(cast(int)width, cast(int)height)));

        this(data, fmt, cast(ushort)width, cast(ushort)height, stride);
    }

    /// ditto
    immutable this(immutable(ubyte)[] data, in ImageFormat fmt, in size_t width, in size_t stride)
    {
        immutable height = data.length / stride;
        enforce(data.length > stride && data.length % stride == 0);
        enforce(isValidImageSize(ISize(cast(int)width, cast(int)height)));

        this(data, fmt, cast(ushort)width, cast(ushort)height, stride);
    }

    private this(ubyte[] data, ImageFormat format, ushort width, ushort height,
                    size_t stride)
    {
        _data = data;
        _format = format;
        _width = width;
        _height = height;
        _stride = stride;
    }

    private immutable this (immutable(ubyte)[] data, ImageFormat format,
                            ushort width, ushort height, size_t stride)
    {
        _data = data;
        _format = format;
        _width = width;
        _height = height;
        _stride = stride;
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
    out(line) {
        assert(line.length == _width*_format.bpp/8);
    }
    body
    {
        immutable start = l * _stride;
        immutable end = start + _width*_format.bpp/8;
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

    /// The size of the image
    @property ISize size() const
    {
        return ISize(_width, _height);
    }

    /// Get the number of bytes between two rows
    @property size_t stride() const
    {
        return _stride;
    }

    /// clear the image content with zeros
    void clear(T=ubyte)(uint val)
    in {
        assert((_data.length % T.sizeof) == 0);
    }
    body {
        auto d = cast(T[])_data;
        d[] = cast(T)val;
    }

    /// blit pixels from src into this image.
    /// The two formats must be identical and this must be big enough in both directions
    /// Unimplemented for ImageFormat.a1.
    void blitFrom(const(Image) src, in IPoint srcOrig, in IPoint destOrig, in ISize size, in bool yReversed=false)
    {
        enforce(format == src.format, "image blit: format mismatch");
        enforce(src.width >= srcOrig.x+size.width, "image blit: src.width too small");
        enforce(src.height >= srcOrig.y+size.height);
        enforce(this.width >= destOrig.x+size.width);
        enforce(this.height >= destOrig.y+size.height);
        assert(format != ImageFormat.a1);

        immutable pixelStride = bpp(format)/8;
        immutable copyStride = pixelStride * size.width;

        foreach(l; 0 .. size.height) {
            immutable srcL = yReversed ? (size.height-(l+srcOrig.y)-1) : (l+srcOrig.y);
            immutable srcPos = srcL * src.stride + pixelStride * srcOrig.x;
            immutable destL = l+destOrig.y;
            immutable destPos = destL * this.stride + pixelStride * destOrig.x;
            _data[destPos .. destPos+copyStride] = src.data[srcPos .. srcPos+copyStride];
        }
    }

    /// Read the file specified by filename and load into an Image.
    static Image loadFromFile(in string filename, in ImageFormat format)
    {
        auto io = imgIOFromFile(filename);
        if (!io)
        {
            throw new Exception("Unrecognized image format");
        }
        return io.readFile(filename, format);
    }

    /// Read the file specified by buffer and load into an Image.
    /// Reads in ImageFormat.argb
    static Image loadFromMemory(in ubyte[] data, in ImageFormat format)
    {
        auto io = imgIOFromMem(data);
        if (!io)
        {
            throw new Exception("Unrecognized image format");
        }
        return io.readMem(data, format);
    }

    /// Read the file specified at compile time by using an import expression
    /// to read the bytes
    static Image loadFromView(string path)(in ImageFormat format)
    {
        immutable data = cast(immutable(ubyte)[])import(path);
        auto io = imgIOFromMem(data);
        if (!io)
        {
            throw new Exception("Unrecognized image format:" ~ path);
        }
        return io.readMem(data, format);
    }

    /// Save the image to the specified buffer.
    /// Only ImageFormat.argb is supported.
    void saveToFile(in string filename) const
    {
        auto io = imgIOFromFile(filename);
        io.writeFile(this, filename);
    }

    /// Duplicates the image into an image completely independant of this one.
    @property Image dup() const
    {
        return new Image(_data.dup, _format, _width, _height, _stride);
    }

    /// Duplicates the image into an immutable image
    @property immutable(Image) idup() const
    {
        return new immutable Image(_data.idup, _format, _width, _height, _stride);
    }

    /// Convert the image into another format. If format is the same, dup is returned.
    /// It is only possible to convert between a1 and a8 or between one of the
    /// rgb formats. An unsupported conversion tentative will throw.
    Image convert(in ImageFormat format) const
    {
        if (format == _format)
        {
            return dup;
        }

        if (format.isPureAlpha != _format.isPureAlpha &&
            format.hasRgb != _format.hasRgb)
        {
            import std.conv : to;
            throw new Exception(
                "Unsupported image conversion from "~_format.to!string~
                " to "~format.to!string
            );
        }

        immutable stride = format.alignedStrideForWidth(_width);
        auto res = new Image (
            new ubyte[stride * _height], format, _width, _height, stride
        );

        if (_format == ImageFormat.a8 && format == ImageFormat.a1)
        {
            /// TODO: accumulation of 4 bytes at a time
            foreach (l; 0 .. _height)
            {
                const from = line(l);
                auto to = res.line(l);
                int count=0;
                int ind =0;
                ubyte val=0;
                foreach (p; 0 .. _width)
                {
                    if (from[p] > 127) val &= (1 << count);
                    if (++count == 8)
                    {
                        to[ind++] = val;
                        val = 0;
                        count = 0;
                    }
                }
                // if we are not multiple of 8, the last byte is not written
                assert(count == 0 || _width % 8);
                if (count) to[ind] = val;
            }
        }
        else if (_format == ImageFormat.a1 && format == ImageFormat.a8)
        {
            /// TODO: accumulation of 4 bytes at a time
            foreach (l; 0 .. _height)
            {
                const from = line(l);
                auto to = res.line(l);
                foreach (p; 0 .. _width)
                {
                    to[p] = getA1(from, p) ? 0xff : 0x00;
                }
            }
        }
        else if ((_format == ImageFormat.xrgb && format == ImageFormat.argb) ||
                (_format == ImageFormat.argb && format == ImageFormat.xrgb))
        {
            fourBytesConv!eraseAlpha(this, res);
        }
        else if (_format == ImageFormat.argbPremult)
        {
            assert(format.hasRgb);
            fourBytesConv!unpremultiply(this, res);
        }
        else if (format == ImageFormat.argbPremult)
        {
            assert(_format.hasRgb);
            fourBytesConv!premultiply(this, res);
        }
        else
        {
            assert(false);
        }
        return res;
    }
}

/// Create a slice of the given image, referencing the same data.
/// ImageFormat.a1 is not supported.
Image slice(Image img, in IPoint offset, in ISize size)
{
    assert(img);
    assert(img.format != ImageFormat.a1);
    enforce(offset.x+size.width <= img.width);
    enforce(offset.y+size.height <= img.height);

    const bytesPerPix = img.format.bpp / 8;
    const dataOffset = (offset.y*img.stride + offset.x) * bytesPerPix;
    const dataLen = (size.height*img.stride + size.width) * bytesPerPix;

    auto dataSlice = img.data[dataOffset .. dataOffset + dataLen];
    return new Image (
        dataSlice, img.format, cast(ushort)size.width, cast(ushort)size.height, img.stride
    );
}

/// Create a slice of the given image, referencing the same data.
/// ImageFormat.a1 is not supported.
immutable(Image) slice(immutable(Image) img, in IPoint offset, in ISize size)
{
    assert(img);
    assert(img.format != ImageFormat.a1);
    enforce(offset.x+size.width <= img.width);
    enforce(offset.y+size.height <= img.height);

    const bytesPerPix = img.format.bpp / 8;
    const dataOffset = (offset.y*img.stride + offset.x) * bytesPerPix;
    const dataLen = (size.height*img.stride + size.width) * bytesPerPix;

    immutable dataSlice = img.data[dataOffset .. dataOffset + dataLen];
    return new immutable Image (
        dataSlice, img.format, cast(ushort)size.width, cast(ushort)size.height, img.stride
    );
}

unittest {
    import std.algorithm : equal;
    ubyte[] data = new ubyte[8*8];
    foreach(i; 0 .. 8*8) {
        data[i] = cast(ubyte)i;
    }
    //  0,  1,  2,  3,  4,  5 ...
    //  8,  9,  10, 11, ...
    //  16, 17, 23, ...
    //  ...
    auto big = new Image(data, ImageFormat.a8, 8, 8);
    auto small = big.slice(IPoint(5, 4), ISize(3, 2));

    assert(small.stride == big.stride);
    assert(small.size == ISize(3, 2));
    assert(small.line(0).equal([37, 38, 39]));
    assert(small.line(1).equal([45, 46, 47]));
}

/// Assumes the image is unique and converts it into an immutable image
immutable(Image) assumeUnique(ref Image img)
{
    import std.exception : assumeUnique;
    immutable res = new immutable(Image)(
        assumeUnique(img.data), img.format, img.width, img.height, img.stride
    );
    img = null;
    return res;
}

/// ditto
immutable(Image) assumeUnique(Image img)
{
    import std.exception : assumeUnique;
    return new immutable(Image)(
        assumeUnique(img.data), img.format, img.width, img.height, img.stride
    );
}


/// Replicate of Image that allocates with malloc and frees in dispose
class MallocImage : Disposable
{
    private Image _img;

    /// Allocates an image with format and size.
    /// Image stride is given by max(minStride, format.minStrideForWidth(size.width))
    /// The pixel content is not initialized.
    this(ImageFormat format, ISize size, size_t minStride=0)
    {
        import std.array : uninitializedArray;
        import std.algorithm : max;
        import core.stdc.stdlib : malloc;
        enforce(size.isValidImageSize);
        immutable width = cast(ushort)size.width;
        immutable height = cast(ushort)size.height;
        immutable stride = max(minStride, format.alignedStrideForWidth(width));

        immutable dataSize = height * stride;
        auto data = cast(ubyte[])(malloc(dataSize)[0 .. dataSize]);

        _img = new Image(data, format, width, height, stride);
    }

    @property inout(Image) img() inout { return _img; }

    alias img this;

    override void dispose()
    {
        import core.stdc.stdlib : free;
        free(cast(void*)_img._data.ptr);
        _img._data = [];
        _img = null;
    }
}

private void fourBytesConv(alias convFn)(const(Image) from, Image to)
if (is(typeof(convFn(uint.init)) == uint))
in
{
    assert(from.size == to.size);
    assert(from.format.bpp == 32 && to.format.bpp == 32);
}
body
{
    foreach (l; 0 .. from.height)
    {
        const lfrom = from.line(l);
        auto lto = to.line(l);
        foreach (offset; 0 .. from.width)
        {
            immutable px = getArgb(lfrom, offset);
            setArgb(lto, offset, convFn(px));
        }
    }
}

/// Apply in-place the conversion function to each 4 bytes group of data.
/// If the image has 4 bytes component, each pixel will be processed individually.
/// Image.stride is always 4 bytes aligned.
void apply(alias convFn)(Image img)
if (is(typeof(convFn(uint.init)) == uint))
{
    foreach (l; 0 .. img.height)
    {
        auto line = img.line(l);
        foreach (i; 0 .. img.width)
        {
            immutable px = getArgb(line, i);
            setArgb(line, i, convFn(px));
        }
    }
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
    if (!alpha) return value;
    else return argb( alpha,
        cast(ubyte)(value.red * 255 / alpha),
        cast(ubyte)(value.green * 255 / alpha),
        cast(ubyte)(value.blue * 255 / alpha),
    );
}

/// Erase the alpha channel of the given pixel.
uint eraseAlpha(in uint value)
{
    return 0xff000000 & value;
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


/// Checks the first few bytes of the given data to check for a valid serialized
/// image signature.
Nullable!ImageFileFormat checkImgSig(const(ubyte)[] data) pure
{
    import std.algorithm : equal;
    import std.range : only;

    Nullable!ImageFileFormat res;

    if (data.length >= 8 &&
        data[0 .. 8].equal(only(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)))
    {
        res = ImageFileFormat.png;
    }

    else if (data.length >= 11 &&
        data[0 .. 3].equal(only(0xff, 0xd8, 0xff)) &&
        (data[3] & 0xfe) == 0xe0 &&
        data[6 .. 11].equal(only(0x4a, 0x46, 0x49, 0x46, 0x00)))
    {
        res = ImageFileFormat.jpeg;
    }

    return res;
}


private
{
    import libpng.png;
    import dgt.bindings.turbojpeg;
    import std.path;
    import std.string;
    import std.uni : toLower;

    ImgIO imgIOFromFile (string filename)
    out (result) {
        assert(result !is null);
    }
    body {
        /// TODO: do not trust extension.
        immutable ext = filename.extension.toLower;
        switch (ext) {
        case ".png":
            return new PngIO;
        case ".jpg":
        case ".jpeg":
            return new JpegIO;
        default:
            return null;
        }
    }

    ImgIO imgIOFromMem(const(ubyte)[] data)
    {
        auto fmt = checkImgSig(data);
        if (fmt.isNull) return null;
        return imgIOFromFormat(fmt);
    }

    ImgIO imgIOFromFormat(in ImageFileFormat format)
    {
        final switch (format)
        {
        case ImageFileFormat.png: return new PngIO;
        case ImageFileFormat.jpeg: return new JpegIO;
        }
    }

    interface ImgIO
    {
        Image readFile(in string filename, in ImageFormat format);
        Image readMem(in ubyte[] data, in ImageFormat format);
        void writeFile(in Image img, in string filename);
    }


    class PngIO : ImgIO
    {

        static uint pngFormat(ImageFormat format)
        {
            final switch (format)
            {
            case ImageFormat.a1:
                assert(false);
            case ImageFormat.a8:
                return PNG_FORMAT_GRAY;
            case ImageFormat.xrgb:
            case ImageFormat.argb:
            case ImageFormat.argbPremult:
            version(LittleEndian) {
                return PNG_FORMAT_BGRA;
            }
            else {
                return PNG_FORMAT_ARGB;
            }
            }
        }


        override Image readFile(in string filename, in ImageFormat format)
        {
            png_image pimg;
            pimg.version_ = PNG_IMAGE_VERSION;
            if (!png_image_begin_read_from_file(&pimg, filename.toStringz))
            {
                throw new Exception("could not read image from "~filename);
            }
            scope(exit) png_image_free(&pimg);
            return readFinish(&pimg, format);
        }

        override Image readMem(in ubyte[] data, in ImageFormat format)
        {
            png_image pimg;
            pimg.version_ = PNG_IMAGE_VERSION;
            if (!png_image_begin_read_from_memory(&pimg, data.ptr, data.length))
            {
                throw new Exception("could not read image from memory");
            }
            scope(exit) png_image_free(&pimg);
            return readFinish(&pimg, format);
        }

        private Image readFinish(png_imagep pimg, in ImageFormat format)
        {
            ImageFormat readFmt = format;
            // 1 bpp is not supported by libpng
            if (format == ImageFormat.a1) readFmt = ImageFormat.a8;

            immutable rowStride = alignedStrideForWidth(readFmt, pimg.width);
            immutable numBytes = rowStride*pimg.height;
            pimg.format = pngFormat(readFmt);
            ubyte[] buf = new ubyte[numBytes];
            if (!png_image_finish_read(pimg, null, cast(void*)buf, cast(int)rowStride, null))
            {
                throw new Exception("could not finish read image");
            }

            auto img = new Image(buf, readFmt, pimg.width, rowStride);

            if (format == ImageFormat.a1)
            {
                return img.convert(ImageFormat.a1);
            }
            if (format == ImageFormat.argbPremult)
            {
                img.apply!premultiply();
            }
            return img;
        }


        override void writeFile(in Image img, in string filename)
        {
            png_image pimg;
            pimg.version_ = PNG_IMAGE_VERSION;
            pimg.format = pngFormat(img.format);
            pimg.width = img.width;
            pimg.height = img.height;

            png_image_write_to_file(&pimg, filename.toStringz, 0, img.data.ptr, 0, null);
        }
    }

    class JpegIO : ImgIO
    {
        static uint jpegFormat(ImageFormat format)
        {
            final switch (format)
            {
            case ImageFormat.a1:
                assert(false);
            case ImageFormat.a8:
                return TJPF.TJPF_GRAY;
            case ImageFormat.xrgb:
            case ImageFormat.argb:
            case ImageFormat.argbPremult:
            version(LittleEndian) {
                return TJPF.TJPF_BGRA;
            }
            else {
                return TJPF.TJPF_ARGB;
            }
            }
        }


        string errorMsg() {
            import core.stdc.string : strlen;
            char* msg = tjGetErrorStr();
            auto len = strlen(msg);
            return msg[0..len].idup;
        }


        override Image readFile(in string filename, in ImageFormat format)
        {
            import std.file : read;
            auto bytes = cast(ubyte[]) read(filename);
            return readMem(bytes, format);
        }

        override Image readMem(in ubyte[] bytes, in ImageFormat format)
        {
            import core.stdc.config : c_ulong;

            ImageFormat readFmt = format;
            // 1 bpp is not supported by libjpeg
            if (format == ImageFormat.a1) readFmt = ImageFormat.a8;

            tjhandle jpeg = tjInitDecompress();
            scope(exit) tjDestroy(jpeg);

            // const cast needed.  arrgh!
            int width, height, jpegsubsamp;
            if (tjDecompressHeader2(jpeg, cast(ubyte*)bytes.ptr, cast(c_ulong)bytes.length,
                                    &width, &height, &jpegsubsamp) != 0)
            {
                throw new Exception("could not read from memory: "~errorMsg());
            }

            immutable rowStride = alignedStrideForWidth(ImageFormat.argb, width);
            auto data = new ubyte[rowStride * height];
            if(tjDecompress2(jpeg, cast(ubyte*)bytes.ptr, cast(c_ulong)bytes.length, data.ptr,
                            width, cast(int)rowStride, height, jpegFormat(readFmt), 0) != 0)
            {
                throw new Exception("could not read from memory: "~errorMsg());
            }

            auto img = new Image(data, ImageFormat.argb, width, rowStride);

            if (format == ImageFormat.a1)
            {
                return img.convert(ImageFormat.a1);
            }
            if (format == ImageFormat.argbPremult)
            {
                img.apply!premultiply();
            }
            return img;
        }

        override void writeFile(in Image img, in string filename)
        {
            import std.file : write;
            import core.stdc.config : c_ulong;

            tjhandle jpeg = tjInitCompress();
            scope(exit) tjDestroy(jpeg);
            c_ulong len;
            ubyte *bytes;
            if (tjCompress2(jpeg, cast(ubyte*)img.data.ptr, img.width, 0, img.height,
                       jpegFormat(img.format), &bytes, &len, TJSAMP.TJSAMP_444, 100,
                       TJFLAG_FASTDCT) != 0) {
                throw new Exception("could not encode to jpeg "~filename.baseName~": "~errorMsg());
            }
            scope(exit) tjFree(bytes);
            write(filename, cast(void[])bytes[0..cast(uint)len]);
        }
    }

}

