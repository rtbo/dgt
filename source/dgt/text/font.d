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
        foreach(ref cache; _glyphCache)
        {
            if (cache.rasterized) cache.rasterized.release();
        }
    }

    /// Get the metrics of one glyph
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
            rasterized.retain();
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

        FT_Load_Glyph(_ftFace, cast(FT_UInt)glyphIndex, FT_LOAD_DEFAULT);
        FT_Render_Glyph(_ftFace.glyph, FT_RENDER_MODE_NORMAL);
        auto slot = _ftFace.glyph;
        auto bitmap = slot.bitmap;

        immutable stride = abs(bitmap.pitch);

        if (stride == 0)
        {
            // likely a space
            return null;
        }
        // Pixels is (purposely) compatible with FreeType bitmap
        auto pixels = Pixels(ImageFormat.a8, bitmap.buffer[0 .. bitmap.rows*stride],
                            bitmap.pitch, bitmap.width, bitmap.rows);
        auto tex = backend.createTexture(pixels);
        return new RasterizedGlyph(
            tex, vec(slot.bitmap_left, slot.bitmap_top), backend.uid
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
class RasterizedGlyph : RefCounted
{
    mixin(rcCode);

    private Rc!VgTexture _bitmapTex;
    private @property IVec2 _bearing;
    private size_t backendUid;

    this (VgTexture bitmapTex, in IVec2 bearing, in size_t backendUid)
    {
        _bitmapTex = bitmapTex;
        _bearing = bearing;
        this.backendUid = backendUid;
    }

    override void dispose()
    {
        _bitmapTex.unload();
    }

    @property inout(VgTexture) bitmapTex() inout
    {
        return _bitmapTex;
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
    import dgt.bindings.harfbuzz.load;
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
