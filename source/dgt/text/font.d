/// Font file manipulation
module dgt.text.font;

import dgt.bindings.harfbuzz;
import dgt.geometry;
import dgt.image;
import dgt.math.vec;
import dgt.sg.style;
import dgt.text.fontcache;
import dgt.util;
import dgt.vg;

import gfx.foundation.rc;

import derelict.freetype.ft;

import std.algorithm;
import std.array;
import std.exception;
import std.experimental.logger;
import std.range;
import std.string;
import std.typecons : Flag, Yes, No, Rebindable;

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
    /// Usually negative.
    float underlinePos;
    /// Thickness that should apply for underline.
    float underlineThickness;
}

/// Glyph metrics (all in px).
struct GlyphMetrics
{
    private this (in FSize size, in FVec2 horBearing, in float horAdvance,
            in FVec2 verBearing, in float verAdvance)
    {
        _size = size;
        _horBearing = horBearing;
        _horAdvance = horAdvance;
        _verBearing = verBearing;
        _verAdvance = verAdvance;
    }

    /// The size of the glyph
    mixin ReadOnlyValueProperty!(FSize, "size");
    /// Bearing for horizontal layout
    mixin ReadOnlyValueProperty!(FVec2, "horBearing");
    /// Advance for horizontal layout
    mixin ReadOnlyValueProperty!(float, "horAdvance");
    /// Bearing for vertical layout
    mixin ReadOnlyValueProperty!(FVec2, "verBearing");
    /// Advance for vertical layout
    mixin ReadOnlyValueProperty!(float, "verAdvance");
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
        _cacheHash = res.hash;

        logf("loading font file %s with size %s%s", _filename, _size.value, _size.unit);

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
        logf("unloading font file %s with size %s%s", _filename, _size.value, _size.unit);
        FontCache.instance.onFontDispose(_cacheHash);
        hb_font_destroy(_hbFont);
        FT_Done_Face(_ftFace);
        _renderedGlyphs.clear();
        _runs = [];
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
    GlyphMetrics glyphMetrics(uint glyphIndex)
    {
        GlyphCache* entry = glyphIndex in _glyphCache;
        GlyphCache cache = entry ? *entry : GlyphCache.init;
        if (cache.metricsSet) return cache.metrics;

        FT_Load_Glyph(_ftFace, cast(FT_UInt)glyphIndex, FT_LOAD_DEFAULT);

        auto ftm = _ftFace.glyph.metrics;
        cache.metrics = GlyphMetrics(
            FSize(ftm.width/64f, ftm.height/64f),

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

    /// Accumulate glyph indices to be part of the next glyph run
    void prepareGlyphRun(IR)(IR indexRange)
    if (isInputRange!IR && is(ElementType!IR == uint))
    {
        static if (hasLength!IR) {
            reserve(_runPreparation, indexRange.length);
        }
        foreach (i; indexRange) {
            _runPreparation ~= i;
        }
    }

    /// Realizes the glyph run with previously accumulated glyph indices
    void realizeGlyphRun()
    {
        scope(exit) _runPreparation = [];

        // temporary struct
        static struct G {
            uint glyph;
            GlyphMetrics gm;
            IRect rect;
        }

        // getting glyph metrics of each glyph and discarding whitespace
        G[] gs;
        foreach(glyph; sort(_runPreparation)
                        .uniq()
                        .filter!(gl => !hasGlyphRendered(gl))) {
            immutable gm = glyphMetrics(glyph);
            immutable size = cast(ISize)gm.size;
            if (size.area == 0) continue;
            G g;
            g.gm = gm;
            g.glyph = glyph;
            gs ~= g;
        }

        // shaping the run into a more or less square of glyphs.
        // Will place the same number of glyphs per line, which is not optimal
        // when glyphs have different sizes.
        // we also let 2px space min between glyphs to avoid filtering issues
        immutable numPerLine = glyphRunNumPerLine(gs.length);
        int lineLoad;
        int lineWidth;
        int lineHeight;
        int totalWidth;
        int totalHeight;
        IVec2 advance = ivec(1, 1);
        foreach(ref g; gs) {
            immutable size = cast(ISize)g.gm.size;
            g.rect = IRect(advance, size);

            lineHeight = max(lineHeight, size.height+2);
            lineWidth += size.width+2;
            totalWidth = max(totalWidth, lineWidth);
            totalHeight = max(totalHeight, lineHeight+advance.y-1);
            if (++lineLoad == numPerLine) {
                advance = ivec(0, advance.y+lineHeight);
                lineLoad = 0;
                lineWidth = 0;
                lineHeight = 0;
            }
            else {
                advance += ivec(size.width+2, 0);
            }
        }

        // make width multiple of 4, height even, allocate run bitmap, and render
        Image img = new Image(ImageFormat.a8, ISize(roundUp(totalWidth, 4), roundUp(totalHeight, 2)));
        foreach(g; gs) {
            immutable rect = g.rect;

            IVec2 bearing =void;
            bool yReversed =void;
            const rg = renderGlyph(g.glyph, bearing, yReversed);
            assert(rg);
            assert(rg.size == rect.size);
            img.blitFrom(rg, IPoint(0, 0), rect.topLeft, rect.size, yReversed);
        }

        // import std.format : format;
        // static int num;
        // img.saveToFile(format("run%s.png", num++));

        // storing results
        import dgt.render : RenderThread;
        immutable cookie = RenderThread.instance.nextCacheCookie();
        immutable iimg = assumeUnique(img);
        immutable(RenderedGlyph)[] glyphs;
        foreach(g; gs) {
            immutable rg = new immutable RenderedGlyph(g.glyph, g.rect, g.gm, iimg, cookie);
            glyphs ~= rg;
            _renderedGlyphs[g.glyph] = rg;
        }
        _runs ~= new immutable GlyphRun(iimg, glyphs, cookie);
    }

    immutable(RenderedGlyph) renderedGlyph(uint index)
    {
        auto rg = (index in _renderedGlyphs);
        return rg ? *rg : null;
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

    /// Render and return an image referencing internal FT buffer.
    /// Will be invalidated at next call of renderGlyph or rasterize
    private const(Image) renderGlyph(uint glyphIndex, out IVec2 bearing, out bool yReversed)
    {
        import std.math : abs;

        FT_Load_Glyph(_ftFace, cast(FT_UInt)glyphIndex, FT_LOAD_DEFAULT);
        FT_Render_Glyph(_ftFace.glyph, FT_RENDER_MODE_NORMAL);
        auto slot = _ftFace.glyph;
        auto bitmap = slot.bitmap;

        immutable stride = abs(bitmap.pitch);
        if (stride == 0) return null; // whitespace

        immutable width = bitmap.width;
        immutable height = bitmap.rows;
        auto data = bitmap.buffer[0 .. height*stride];

        bearing = vec(slot.bitmap_left, slot.bitmap_top);
        yReversed = bitmap.pitch < 0;
        return new Image(data, ImageFormat.a8, width, stride);
    }

    private bool hasGlyphRendered(in uint glyph) const
    {
        return (glyph in _renderedGlyphs) !is null;
    }

    private FT_Face _ftFace;
    private hb_font_t* _hbFont;
    private uint[] _runPreparation;
    private immutable(GlyphRun)[] _runs;
    private Rebindable!(immutable(RenderedGlyph))[uint] _renderedGlyphs;
    private size_t _cacheHash;

    // API that follows is to be revised or pruned.
    // used by software rendering, which could probably use the new API

    /// Rasterize the glyph at the specified index.
    /// If the glyph is a whitespace, null is returned.
    RasterizedGlyph rasterizeGlyph(uint glyphIndex)
    {
        GlyphCache* entry = glyphIndex in _glyphCache;
        GlyphCache cache = entry ? *entry : GlyphCache.init;
        if (cache.rasterized)
        {
            return cache.rasterized;
        }

        if (cache.isWhitespace) return null;

        auto rasterized = rasterize(glyphIndex);
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


    private RasterizedGlyph rasterize(uint glyphIndex)
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
            img, vec(slot.bitmap_left, slot.bitmap_top)
        );
    }

    private GlyphCache[uint] _glyphCache;
}


immutable class GlyphRun
{
    immutable this(immutable(Image) img,
                    immutable(RenderedGlyph)[] glyphs,
                    ulong cacheCookie)
    {
        _img = img;
        _glyphs = glyphs;
        _cacheCookie = cacheCookie;
    }

    @property immutable(Image) image() const { return _img; }
    @property immutable(RenderedGlyph)[] glyphs() const { return _glyphs; }
    @property ulong cacheCookie() const { return _cacheCookie; }

    private Image _img;
    private RenderedGlyph[] _glyphs;
    private ulong _cacheCookie;
}


immutable class RenderedGlyph
{
    immutable this(in uint glyph, in IRect rect, in GlyphMetrics metrics,
                    immutable(Image) runImg,
                    in ulong cacheCookie)
    {
        _glyph = glyph;
        _rect = rect;
        _metrics = metrics;
        _runImg = runImg;
        _cacheCookie = cacheCookie;
    }

    @property uint glyph() const { return _glyph; }
    @property IRect rect() const { return _rect; }
    @property GlyphMetrics metrics() const { return _metrics; }
    @property immutable(Image) runImg() const { return _runImg; }
    @property ulong cacheCookie() const { return _cacheCookie; }

    // 60 bytes of metadata per glyph.
    // Have to be reduced as soon as usage gets clearer
    private uint _glyph;
    private IRect _rect;
    private GlyphMetrics _metrics;
    private Image _runImg;
    private ulong _cacheCookie;
}

private int roundUp(in int number, in int multiple) pure
{
    if (multiple == 0) return number;
    immutable rem = number % multiple;
    if (rem == 0) return number;
    return number + multiple - rem;
}

private size_t glyphRunNumPerLine(size_t numGlyphs)
{
    if (numGlyphs <= 25) return 5;
    if (numGlyphs <= 100) return 10;
    if (numGlyphs <= 400) return 20;

    import std.math : sqrt;
    // multiple of 10 close to sqrt
    return 10 * ((5+cast(int)sqrt(cast(float)numGlyphs))/10);
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


/// A glyph rasterized in a bitmap
class RasterizedGlyph
{
    private Image _img;
    private @property IVec2 _bearing;

    this (Image img, in IVec2 bearing)
    {
        _img = img;
        _bearing = bearing;
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
