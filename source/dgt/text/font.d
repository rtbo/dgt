module dgt.text.font;

import dgt.text.fontcache;
import dgt.image;
import dgt.resource;
import dgt.util;

import derelict.freetype.ft;

import std.string;
import std.exception;

/// Font size (expressed in pts or px)
struct FontSize
{
    /// Unit of the size value
    enum Unit
    {
        pts,
        px
    }

    Unit unit;
    double value;

    /// Returns a FontSize with value expressed in pts
    static FontSize pts(double pts)
    {
        return FontSize(Unit.pts, pts);
    }
    /// Returns a FontSize with value expressed in px
    static FontSize px(double px)
    {
        return FontSize(Unit.px, px);
    }
}

/// Font style as defined by the CSS specification
enum FontStyle
{
    normal,
    italic,
    oblique,
}

/// Font weight as defined by the CSS specification.
/// An integer is typically expected for the weight. Either a value of this enum
/// or a number between 100 and 900 can be provided in place.
enum FontWeight : int
{
    normal = 400,
    bold = 700,
}

/// Font variant as defined by the CSS specification.
/// Unsupported at the moment.
enum FontVariant
{
    normal,
    smallCaps,
}

/// Format of the font
enum FontFormat
{
    /// The font embeds a scalable outline
    outline,
    /// The font embeds bitmaps for a set of sizes
    bitmap,
}

/// An actual font that hold font information and will lazily load glyph into memory
class Font : RefCounted
{
    mixin(rcCode);

    this(in FontResult res)
    {
        _filename = res.filename;
        _faceIndex = res.faceIndex;
        _family = res.family;
        _size = res.size;
        _weight = res.weight;
        _style = res.style;
        _foundry = res.foundry;

        ftEnforce(FT_New_Face(_ftLib, toStringz(_filename), _faceIndex, &_ftFace));
        enforce(_ftFace.face_flags & FT_FACE_FLAG_SCALABLE, "Only outline fonts are supported.");
        _format = FontFormat.outline;

        if (_size.unit == FontSize.Unit.pts)
        {
            FT_Set_Char_Size(_ftFace, 0, cast(long)_size.value*64, 96, 96);
        }
        else
        {
            FT_Set_Pixel_Sizes(_ftFace, 0, cast(int)_size.value);
        }
    }

    override void dispose()
    {
        FT_Done_Face(_ftFace);
    }

    Glyph renderGlyph(size_t glyphIndex)
    {
        import std.math : abs;
        import std.algorithm : min;

        FT_Load_Glyph(_ftFace, cast(FT_UInt)glyphIndex, FT_LOAD_DEFAULT);
        FT_Render_Glyph(_ftFace.glyph, FT_RENDER_MODE_NORMAL);
        auto bitmap = _ftFace.glyph.bitmap;

        ubyte *srcData = bitmap.buffer;
        immutable srcStride = abs(bitmap.pitch);

        immutable destStride = ImageFormat.a8.bytesForWidth(bitmap.width);
        ubyte[] destData = new ubyte[bitmap.rows * destStride];

        immutable copyStride = min(srcStride, destStride);

        foreach (r; 0 .. bitmap.rows)
        {
            immutable srcOffset = r * srcStride;
            immutable destLine = bitmap.pitch > 0 ? r : bitmap.rows-r-1;
            immutable destOffset = destLine * destStride;
            destData[destOffset .. destOffset+copyStride] =
                srcData[srcOffset .. srcOffset+copyStride ];
            if (copyStride < destStride)
            {
                // padding stride to zero, probably not necessary
                destData[destOffset+copyStride .. destOffset+destStride] = 0;
            }
        }
        auto img = new Image(destData, ImageFormat.a8, bitmap.width, destStride);
        assert(img.size.height == bitmap.rows);
        return new Glyph(img);
    }

    mixin ReadOnlyValueProperty!("filename", string);
    mixin ReadOnlyValueProperty!("faceIndex", int);
    mixin ReadOnlyValueProperty!("family", string);
    mixin ReadOnlyValueProperty!("size", FontSize);
    mixin ReadOnlyValueProperty!("weight", int);
    mixin ReadOnlyValueProperty!("style", FontStyle);
    mixin ReadOnlyValueProperty!("foundry", string);
    mixin ReadOnlyValueProperty!("format", FontFormat);

    @property FT_Face ftFace()
    {
        return _ftFace;
    }

    private FT_Face _ftFace;
}

struct GlyphMetrics
{
}

class Glyph
{
    private Image _bitmap;
    private GlyphMetrics _metrics;

    this (Image bitmap)
    {
        _bitmap = bitmap;
    }

    @property inout(Image) bitmap() inout
    {
        return _bitmap;
    }
}

private:

__gshared FT_Library _ftLib;

shared static this()
{
    DerelictFT.load();
    FT_Init_FreeType(&_ftLib);
}

shared static ~this()
{
    FT_Done_FreeType(_ftLib);
}

void ftEnforce(FT_Error err)
{
    enforce(err == 0);
}
