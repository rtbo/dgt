module dgt.text.font;

import dgt.text.fontcache;
import dgt.image;
import dgt.math.vec;
import dgt.core.resource;
import dgt.core.util;
import dgt.bindings.harfbuzz;

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
            FT_Set_Char_Size(_ftFace, 0, cast(FT_F26Dot6)(_size.value*64), 96, 96);
        }
        else
        {
            FT_Set_Pixel_Sizes(_ftFace, 0, cast(int)_size.value);
        }

        _hbFont = hb_ft_font_create(_ftFace, null);
    }

    override void dispose()
    {
        hb_font_destroy(_hbFont);
        FT_Done_Face(_ftFace);
        // GC help in case this font is retained somewhere after disposal
        // (which should not be the case)
        _rasterizedCache = null;
    }

    /// Rasterize the glyph at the specified index.
    /// If the glyph is a whitespace, null is returned.
    RasterizedGlyph rasterizeGlyph(size_t glyphIndex)
    {
        RasterizedGlyph* pg = glyphIndex in _rasterizedCache;
        if (pg) return *pg;

        auto g = rasterize(glyphIndex);
        _rasterizedCache[glyphIndex] = g;
        return g;
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
    @property hb_font_t* hbFont()
    {
        return _hbFont;
    }

    private RasterizedGlyph rasterize(size_t glyphIndex)
    {
        import std.math : abs;
        import std.algorithm : min;

        FT_Load_Glyph(_ftFace, cast(FT_UInt)glyphIndex, FT_LOAD_DEFAULT);
        FT_Render_Glyph(_ftFace.glyph, FT_RENDER_MODE_NORMAL);
        auto slot = _ftFace.glyph;
        auto bitmap = slot.bitmap;

        ubyte *srcData = bitmap.buffer;
        immutable srcStride = abs(bitmap.pitch);
        if (srcStride == 0)
        {
            // likely a space
            return null;
        }

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
        return new RasterizedGlyph(img, vec(slot.bitmap_left, slot.bitmap_top));
    }

    private FT_Face _ftFace;
    private hb_font_t* _hbFont;
    private RasterizedGlyph[size_t] _rasterizedCache;
}

/// A glyph rasterized in a bitmap
class RasterizedGlyph
{
    private Image _bitmap;
    private @property IVec2 _bearing;

    this (Image bitmap, in IVec2 bearing)
    {
        _bitmap = bitmap;
        _bearing = bearing;
    }

    @property inout(Image) bitmap() inout
    {
        return _bitmap;
    }

    @property IVec2 bearing() const
    {
        return _bearing;
    }
}

private:

__gshared FT_Library _ftLib;

shared static this()
{
    DerelictFT.load();
    loadHarfbuzzSymbols();
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
