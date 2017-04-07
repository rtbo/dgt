module dgt.text.font;

import dgt.text.fontcache;
import dgt.image;
import dgt.math.vec;
import dgt.core.resource;
import dgt.core.util;
import dgt.bindings.harfbuzz;
import dgt.vg;

import derelict.freetype.ft;

import std.string;
import std.exception;
import std.typecons : Flag, Yes, No;

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

/// General metrics of a scaled font.
struct FontMetrics
{
    /// Maximum advance between two consecutive glyphs.
    /// Always positive.
    float maxAdvance;
    /// Height between two consecutive baselines.
    /// Always positive.
    float height;
    /// Typographic ascender of the font.
    /// Always positive.
    float ascender;
    /// Typographic descender of the font.
    /// Usually negative.
    float descender;
    /// Position where underline should be placed.
    /// Usuallt negative.
    float underlinePos;
    /// Thickness that should apply for underline.
    float underlineThickness;
}

/// A scaled font object that hold font information and will lazily load and
/// cache glyphs into memory.
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
    }

    /// Retrieve the scaled font metrics, with or without hinting.
    FontMetrics metrics(in Flag!"hinted" hinted = Yes.hinted) const
    {
        // combined factor of 26.6 and 16.16 fixed point
        enum real scaleFactor = 1 << (6 + 16);
        immutable ftMetrics = _ftFace.size.metrics;

        float scale(FT_Short dimension, FT_Fixed scale)
        {
            import std.math : round;
            return cast(float)( hinted ?
                    round(dimension * scale / scaleFactor) :
                    dimension * scale / scaleFactor
            );
        }

        FontMetrics metrics;
        metrics.maxAdvance = scale(_ftFace.max_advance_width, ftMetrics.x_scale);
        metrics.height = scale(_ftFace.height, ftMetrics.y_scale);
        metrics.ascender = scale(_ftFace.ascender, ftMetrics.y_scale);
        metrics.descender = scale(_ftFace.descender, ftMetrics.y_scale);
        metrics.underlinePos = scale(_ftFace.underline_position, ftMetrics.y_scale);
        metrics.underlineThickness = scale(_ftFace.underline_thickness, ftMetrics.y_scale);
        return metrics;
    }

    /// Get the scaled metrics of one glyph.
    GlyphMetrics glyphMetrics(size_t glyphIndex)
    {
        GlyphCache* entry = glyphIndex in _glyphCache;
        GlyphCache cache = entry ? *entry : GlyphCache.init;
        if (cache.metricsSet) return cache.metrics;

        FT_Load_Glyph(_ftFace, cast(FT_UInt)glyphIndex, FT_LOAD_DEFAULT);

        auto ftm = _ftFace.glyph.metrics;
        cache.metrics = GlyphMetrics(
            fvec(ftm.width/64f, ftm.height/64f),

            fvec(ftm.horiBearingX/64f, ftm.horiBearingY/64f),
            ftm.horiAdvance/64f,

            fvec(ftm.vertBearingX/64f, ftm.vertBearingY/64f),
            ftm.vertAdvance/64f,
        );
        cache.metricsSet = true;

        if (entry) *entry = cache;
        else _glyphCache[glyphIndex] = cache;
        return cache.metrics;
    }

    /// Rasterize the glyph at the specified index.
    /// If the glyph is a whitespace, null is returned.
    RasterizedGlyph rasterizeGlyph(size_t glyphIndex, VgBackend backend)
    {
        GlyphCache* entry = glyphIndex in _glyphCache;
        GlyphCache cache = entry ? *entry : GlyphCache.init;
        if (cache.rasterized && cache.rasterized.backendUid == backend.uid)
        {
            return cache.rasterized;
        }

        if (cache.isWhitespace) return null;

        auto rasterized = rasterize(glyphIndex, backend);
        if (rasterized)
        {
            cache.rasterized = rasterized;
        }
        else
        {
            cache.isWhitespace = true;
        }

        if (entry) *entry = cache;
        else _glyphCache[glyphIndex] = cache;
        return rasterized;
    }

    mixin ReadOnlyValueProperty!(string, "filename");
    mixin ReadOnlyValueProperty!(int, "faceIndex");
    mixin ReadOnlyValueProperty!(string, "family");
    mixin ReadOnlyValueProperty!(FontSize, "size");
    mixin ReadOnlyValueProperty!(int, "weight");
    mixin ReadOnlyValueProperty!(FontStyle, "style");
    mixin ReadOnlyValueProperty!(string, "foundry");
    mixin ReadOnlyValueProperty!(FontFormat, "format");

    @property FT_Face ftFace()
    {
        return _ftFace;
    }
    @property hb_font_t* hbFont()
    {
        return _hbFont;
    }

    private RasterizedGlyph rasterize(size_t glyphIndex, VgBackend backend)
    {
        import std.math : abs;
        import std.algorithm : min;
        import std.array : uninitializedArray;

        FT_Load_Glyph(_ftFace, cast(FT_UInt)glyphIndex, FT_LOAD_DEFAULT);
        FT_Render_Glyph(_ftFace.glyph, FT_RENDER_MODE_NORMAL);
        auto slot = _ftFace.glyph;
        auto bitmap = slot.bitmap;

        immutable stride = abs(bitmap.pitch);

        if (stride == 0)
        {
            // no graphics (whitespace of some kind)
            return null;
        }

        immutable fmt = ImageFormat.a8;
        immutable width = bitmap.width;
        immutable height = bitmap.rows;
        immutable destStride = fmt.vgBytesForWidth(width);
        immutable srcStride = abs(bitmap.pitch);
        immutable copyStride = min(destStride, srcStride);
        const srcData = bitmap.buffer[0 .. height*srcStride];
        auto destData = uninitializedArray!(ubyte[])(destStride * height);
        foreach(r; 0 .. height)
        {
            immutable srcOffset = r * srcStride;
            immutable destLine = bitmap.pitch > 0 ? r : height-r-1;
            immutable destOffset = destLine * destStride;
            destData[destOffset .. destOffset+copyStride] =
                    srcData[srcOffset .. srcOffset+copyStride];
        }
        auto img = new Image(destData, fmt, width, destStride);
        return new RasterizedGlyph(
            img, vec(slot.bitmap_left, slot.bitmap_top), backend.uid
        );
    }


    private FT_Face _ftFace;
    private hb_font_t* _hbFont;
    private GlyphCache[size_t] _glyphCache;
}

private enum CacheFlags
{
    none = 0,
    metricsSet  = 1,
    isWhitespace = 2,
}

private struct GlyphCache
{
    CacheFlags flags;
    GlyphMetrics metrics;
    RasterizedGlyph rasterized;

    @property bool metricsSet() const
    {
        return (flags & CacheFlags.metricsSet) != 0;
    }
    @property void metricsSet(bool val)
    {
        flags = val ?
            flags | CacheFlags.metricsSet :
            flags & ~CacheFlags.metricsSet;
    }

    @property bool isWhitespace() const
    {
        return (flags & CacheFlags.isWhitespace) != 0;
    }
    @property void isWhitespace(bool val)
    {
        flags = val ?
            flags | CacheFlags.isWhitespace :
            flags & ~CacheFlags.isWhitespace;
    }
}

/// Glyph metrics.
struct GlyphMetrics
{
    private this (in FVec2 size, in FVec2 horBearing, in float horAdvance,
            in FVec2 verBearing, in float verAdvance)
    {
        _size = size;
        _horBearing = horBearing;
        _horAdvance = horAdvance;
        _verBearing = verBearing;
        _verAdvance = verAdvance;
    }

    mixin ReadOnlyValueProperty!(FVec2, "size");
    mixin ReadOnlyValueProperty!(FVec2, "horBearing");
    mixin ReadOnlyValueProperty!(float, "horAdvance");
    mixin ReadOnlyValueProperty!(FVec2, "verBearing");
    mixin ReadOnlyValueProperty!(float, "verAdvance");
}

/// A glyph rasterized in a bitmap
class RasterizedGlyph
{
    private Image _img;
    private @property IVec2 _bearing;
    private size_t backendUid;

    this (Image img, in IVec2 bearing, in size_t backendUid)
    {
        _img = img;
        _bearing = bearing;
        this.backendUid = backendUid;
    }

    @property inout(Image) image() inout
    {
        return _img;
    }

    @property IVec2 bearing() const
    {
        return _bearing;
    }
}

/// FontEngine is a singleton that hold some resources to be used by Fonts
class FontEngine : Disposable
{
    /// Instance access
    static @property FontEngine instance()
    in
    {
        assert(_feInst !is null);
    }
    body
    {
        return _feInst;
    }


    /// Initialize FontEngine
    package(dgt) static void initialize()
    in
    {
        assert(_feInst is null);
    }
    body
    {
        _feInst = new FontEngine();
    }


    private this()
    {
        FT_Init_FreeType(&_ftLib);
    }

    override void dispose()
    {
        FT_Done_FreeType(_ftLib);
        _ftLib = null;
        _feInst = null;
    }
}

private:

__gshared FontEngine _feInst;
__gshared FT_Library _ftLib;

void ftEnforce(FT_Error err)
{
    enforce(err == 0);
}
