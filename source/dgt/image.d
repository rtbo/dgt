module dgt.image;

import dgt.geometry;
import dgt.vg;

import std.exception;
import std.typecons : Nullable;

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

@property bool isPureAlpha(in ImageFormat format)
{
    return format == ImageFormat.a1 || format == ImageFormat.a8;
}

@property bool hasAlpha(in ImageFormat format)
{
    return format != ImageFormat.rgb;
}

@property bool hasRgb(in ImageFormat format)
{
    return !format.isPureAlpha;
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

/// The minimum number of bytes an image must have for a row of pixels.
/// This gives number of bytes for a row of image including a 4 bytes alignement.
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

/// Format of an image serialized into a file
enum ImageFileFormat
{
    png,
    jpeg,
}

/// Basic aggregation of data to describe pixels.
/// It does not check for any validity of size, nor does it constrain
/// bytes alignement as Image does.
struct Pixels
{
    /// The format describing pixels.
    ImageFormat format;
    /// The actual pixel data.
    ubyte[] data;
    /// Amount of bytes between two rows.
    /// If negative, it means that first row is at the bottom.
    int stride;
    /// The meaningful width
    size_t width;
    /// The number of rows.
    size_t height;

    /// Build a Pixels struct.
    /// If passed height is zero, it is interpreted as data.length / abs(stride).
    this (in ImageFormat format, ubyte[] data, in int stride, in size_t width,
            in size_t height=0)
    {
        import std.math : abs;
        this.format = format;
        this.data = data;
        this.stride = stride;
        this.width = width;
        this.height = height ? height : data.length / abs(stride);
    }
}

/// In-memory representation of an image.
/// Store pixels in main memory and keep rows 4 bytes aligned to
/// allow drawing optimizations.
class Image
{
    private ubyte[] _data;
    private ImageFormat _format;
    private ushort _width; // in px
    private ushort _height; // in px
    private size_t _stride; // in bytes

    /// Allocates an image with format and size
    this(ImageFormat format, ISize size)
    {
        enforce(size.isValidImageSize);
        _width = cast(ushort)size.width;
        _height = cast(ushort)size.height;
        _stride = format.bytesForWidth(size.width);
        _data = new ubyte[_stride * _height];
    }

    /// Build an Image from a Pixels struct. $(D pixels.data) does not need to
    /// meet alignement requirements.
    /// A copy of pixels is made. At most pixels.height rows will be copied.
    /// An exception is thrown if pixels.height cannot be read.
    this(in Pixels pixels)
    {
        import std.array : uninitializedArray;
        import std.algorithm : min;
        import std.math : abs;
        enforce(
            pixels.height <= pixels.data.length / abs(pixels.stride)
        );
        enforce(
            pixels.width <= 8 * pixels.stride / pixels.format.bpp
        );

        immutable width = pixels.width;
        immutable height = pixels.height;
        immutable destStride = pixels.format.bytesForWidth(width);
        immutable srcStride = abs(pixels.stride);
        immutable copyStride = min(destStride, srcStride);
        auto srcData = pixels.data;
        auto destData = uninitializedArray!(ubyte[])(destStride * height);

        foreach(r; 0 .. pixels.height)
        {
            immutable srcOffset = r * srcStride;
            immutable destLine = pixels.stride > 0 ? r : height-r-1;
            immutable destOffset = destLine * destStride;
            destData[destOffset .. destOffset+copyStride] =
                    srcData[srcOffset .. srcOffset+copyStride];
        }

        _format = pixels.format;
        _data = destData;
        _width = cast(ushort)width;
        _height = cast(ushort)height;
        _stride = destStride;
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
        _format = fmt;
        _data = data;
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
        immutable end = start + _stride;
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

    /// Make a surface that can be used to draw directly into the image data.
    /// As image data resides in main memory, the surface will be associated
    /// with a software rasterizer.
    VgSurface makeSurface()
    {
        import dgt.vg.backend.cairo : CairoImgSurf;
        return new CairoImgSurf(this);
    }

    /// Read the file specified by filename and load into an Image.
    /// Reads in ImageFormat.argb.
    static Image loadFromFile(string filename)
    {
        auto io = imgIOFromFile(filename);
        if (!io)
        {
            throw new Exception("Unrecognized image format");
        }
        return io.readFile(filename);
    }

    /// Read the file specified by buffer and load into an Image.
    /// Reads in ImageFormat.argb
    static Image loadFromMemory(const(ubyte)[] data)
    {
        auto io = imgIOFromMem(data);
        if (!io)
        {
            throw new Exception("Unrecognized image format");
        }
        return io.readMem(data);
    }

    /// Save the image to the specified buffer.
    /// Only ImageFormat.argb is supported.
    void saveToFile(string filename) const
    {
        enforce(format == ImageFormat.argb);
        auto io = imgIOFromFile(filename);
        io.writeFile(this, filename);
    }

    /// Duplicates the image into an image completely independant of this one.
    @property Image dup() const
    {
        return new Image(_data.dup, _format, _width, _height, _stride);
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

        immutable stride = bytesForWidth(format, _width);
        auto res = new Image (
            new ubyte[stride * _height], format, _width, _height, stride
        );

        if (_format == ImageFormat.a8 && format == ImageFormat.a1)
        {
            /// TODO: check accumulation of 4 bytes at a time
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
            /// TODO: check accumulation of 4 bytes at a time
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
        else if ((_format == ImageFormat.rgb && format == ImageFormat.argb) ||
                (_format == ImageFormat.argb && format == ImageFormat.rgb))
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



private void fourBytesConv(alias convFn)(const(Image) from, Image to)
if (is(typeof(convFn(uint.init)) == uint))
{
    assert(from.size == to.size);
    assert(from.format.bpp == 32 && to.format.bpp == 32);

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
    import libjpeg.turbojpeg;
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
        Image readFile(string filename);
        Image readMem(const(ubyte)[] data);
        void writeFile(const(Image) img, string filename);
    }


    class PngIO : ImgIO
    {

        version(LittleEndian) {
            enum pngFormat = PNG_FORMAT_BGRA;
        }
        else {
            enum pngFormat = PNG_FORMAT_ARGB;
        }

        override Image readFile(string filename)
        {
            png_image pimg;
            pimg.version_ = PNG_IMAGE_VERSION;
            if (!png_image_begin_read_from_file(&pimg, filename.toStringz))
            {
                throw new Exception("could not read image from "~filename);
            }
            scope(failure) png_image_free(&pimg);

            immutable rowStride = bytesForWidth(ImageFormat.argb, pimg.width);
            immutable numBytes = rowStride*pimg.height;
            pimg.format = pngFormat;
            ubyte[] buf = new ubyte[numBytes];
            if (!png_image_finish_read(&pimg, null, cast(void*)buf, cast(int)rowStride, null)) {
                throw new Exception("could not finish read image from "~filename);
            }
            return new Image(buf, ImageFormat.argb, pimg.width, rowStride);
        }

        override Image readMem(const(ubyte)[] data)
        {
            png_image pimg;
            pimg.version_ = PNG_IMAGE_VERSION;
            if (!png_image_begin_read_from_memory(&pimg, data.ptr, data.length))
            {
                throw new Exception("could not read image from memory");
            }
            scope(failure) png_image_free(&pimg);

            immutable rowStride = bytesForWidth(ImageFormat.argb, pimg.width);
            immutable numBytes = rowStride*pimg.height;
            pimg.format = pngFormat;
            ubyte[] buf = new ubyte[numBytes];
            if (!png_image_finish_read(&pimg, null, cast(void*)buf, cast(int)rowStride, null)) {
                throw new Exception("could not finish read image from memory");
            }
            return new Image(buf, ImageFormat.argb, pimg.width, rowStride);
        }


        override void writeFile(const(Image) img, string filename)
        {
            png_image pimg;
            pimg.version_ = PNG_IMAGE_VERSION;
            pimg.format = pngFormat;
            pimg.width = img.width;
            pimg.height = img.height;

            png_image_write_to_file(&pimg, filename.toStringz, 0, img.data.ptr, 0, null);
        }
    }

    class JpegIO : ImgIO
    {
        version(LittleEndian) {
            enum jpegFormat = TJPF.TJPF_BGRA;
        }
        else {
            enum jpegFormat = TJPF.TJPF_ARGB;
        }


        string errorMsg() {
            import core.stdc.string : strlen;
            char* msg = tjGetErrorStr();
            auto len = strlen(msg);
            return msg[0..len].idup;
        }


        override Image readFile(string filename)
        {
            import std.file : read;
            auto bytes = cast(ubyte[]) read(filename);
            return readMem(bytes);
        }

        override Image readMem(const(ubyte)[] bytes)
        {
            tjhandle jpeg = tjInitDecompress();
            scope(exit) tjDestroy(jpeg);

            // const cast needed.  arrgh!
            int width, height, jpegsubsamp;
            if (tjDecompressHeader2(jpeg, cast(ubyte*)bytes.ptr, bytes.length,
                                    &width, &height, &jpegsubsamp) != 0) {
                throw new Exception("could not read from memory: "~errorMsg());
            }

            immutable rowStride = bytesForWidth(ImageFormat.argb, width);
            auto data = new ubyte[rowStride * height];
            if(tjDecompress2(jpeg, cast(ubyte*)bytes.ptr, bytes.length, data.ptr,
                            width, cast(int)rowStride, height, jpegFormat, 0) != 0) {
                throw new Exception("could not read from memory: "~errorMsg());
            }

            return new Image(data, ImageFormat.argb, width, rowStride);
        }

        override void writeFile(const(Image) img, string filename)
        {
            import std.file : write;
            tjhandle jpeg = tjInitCompress();
            scope(exit) tjDestroy(jpeg);
            c_ulong len;
            ubyte *bytes;
            if (tjCompress2(jpeg, cast(ubyte*)img.data.ptr, img.width, 0, img.height,
                       jpegFormat, &bytes, &len, TJSAMP.TJSAMP_444, 100,
                       TJFLAG_FASTDCT) != 0) {
                throw new Exception("could not encode to jpeg "~filename.baseName~": "~errorMsg());
            }
            scope(exit) tjFree(bytes);
            write(filename, cast(void[])bytes[0..cast(uint)len]);
        }
    }

}
