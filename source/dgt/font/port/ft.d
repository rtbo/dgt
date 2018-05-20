/// Freetype typeface implementation module
module dgt.font.port.ft;

import derelict.freetype.ft;

import dgt : Subsystem;
import dgt.core.geometry;
import dgt.core.image;
import dgt.core.rc;
import dgt.font.style;
import dgt.font.typeface;
import gfx.math.vec : FVec2, IVec2;
import dgt.text.shaping;

import std.exception;
import std.experimental.logger;
import std.typecons : Nullable;
import std.uni : CodepointSet;

// for other modules to import without having to deal with derelict
alias FT_Face = derelict.freetype.ft.FT_Face;

class FtTypeface : Typeface
{
    this(FT_Face face) {
        _face = face;
        // todo handle MS symbols
    }

    // version that keeps the font file data in memory (needed for cloning)
    private this (FT_Face face, const(ubyte)[] blob)
    {
        this(face);
        _blob = blob;
    }

    static FtTypeface newFromMemory(const(ubyte)[] data, int faceIndex) {
        auto f = openFaceFromMemory(data, faceIndex);
        return new FtTypeface(f, data);
    }

    static FtTypeface newFromFile(in string filename, int faceIndex) {
        auto f = openFaceFromFile(filename, faceIndex);
        return new FtTypeface(f);
    }

    override void dispose() {
        foreach(sc; _scs) {
            sc.release();
        }
        _scs = null;
        FT_Done_Face(_face);
        _face = null;
    }

    override @property string family() {
        import std.string : fromStringz;
        return fromStringz(_face.family_name).idup;
    }

    override @property FontStyle style() {
        const flags = _face.style_flags;
        const slant = flags & FT_STYLE_FLAG_ITALIC ? FontSlant.italic : FontSlant.normal;
        const weight = flags & FT_STYLE_FLAG_BOLD ? FontWeight.bold : FontWeight.normal;
        // font width?
        return FontStyle(weight, slant, FontWidth.normal);
    }

    final override @property CodepointSet coverage() {
        if (_coverage.isNull) {
            _coverage = buildCoverage();
        }
        return _coverage;
    }

    override ScalingContext getScalingContext(in float pixelSize) {
        foreach (sc; _scs) {
            if (sc._pixelSize == pixelSize) {
                return sc;
            }
        }

        auto sc = new FtScalingContext(_face, pixelSize);
        sc.retain();
        _scs ~= sc;
        return sc;
    }

    /// Clone the typeface such as the size and glyph slot in the FT_Face
    /// can be manipulated independently by different scaling contexts
    // not actually used
    FtTypeface clone() {
        if (!_blob.length) {
            _blob = fetchBlob();
        }
        if (!_blob.length) {
            return null;
        }
        FT_Face faceClone;
        if (FT_New_Memory_Face(gFtLib, _blob.ptr, cast(FT_ULong)_blob.length,
                 _face.face_index, &faceClone)) {
            return null;
        }
        return new FtTypeface(faceClone, _blob);
    }

    protected CodepointSet buildCoverage() {
        return ftFaceToCoverage(_face);
    }

    private const(ubyte)[] fetchBlob() {
        FT_ULong length=0;
        if (FT_Load_Sfnt_Table(_face, 0, 0, null, &length)) {
            return null;
        }
        auto blob = new ubyte[length];
        if (FT_Load_Sfnt_Table(_face, 0, 0, blob.ptr, &length)) {
            return null;
        }
        return blob;
    }

    private FT_Face _face;
    private const(ubyte)[] _blob;
    private Nullable!CodepointSet _coverage;
    private FtScalingContext[] _scs;
}

/// data must be alive until FT_Done_Face is called
FT_Face openFaceFromMemory(const(ubyte)[] data, int faceIndex) {
    FT_Open_Args args;
    args.flags = FT_OPEN_MEMORY;
    args.memory_base = data.ptr;
    args.memory_size = data.length;
    FT_Face face;
    enforce(FT_Open_Face(gFtLib, &args, faceIndex, &face) == 0,
            "Freetype cannot open font from memorty");
    return face;
}

FT_Face openFaceFromFile(in string filename, int faceIndex) {
    import std.string : toStringz;
    char[] fn = filename.dup ~ '\0';
    FT_Open_Args args;
    args.flags = 4; // see https://github.com/DerelictOrg/DerelictFT/issues/13
    args.pathname = fn.ptr;
    FT_Face face;
    enforce(FT_Open_Face(gFtLib, &args, faceIndex, &face) == 0,
            "Freetype cannot open font from file: "~filename
    );
    return face;
}

CodepointSet ftFaceToCoverage(FT_Face face) {
    import std.uni : isControl;
    CodepointSet coverage;
    FT_UInt glyph;
    dchar c = cast(dchar)FT_Get_First_Char(face, &glyph);
    while (glyph != 0) {
        bool skip = false;
        if (isControl(c)) {
            const FT_Int loadFlags =   FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH |
                                        FT_LOAD_NO_SCALE |
                                        FT_LOAD_NO_HINTING;
            if (FT_Load_Glyph(face, glyph, loadFlags) ||
                (face.glyph.format == FT_GLYPH_FORMAT_OUTLINE &&
                face.glyph.outline.n_contours == 0)) {
                skip = true;
            }
        }

        if (!skip) {
            coverage.add(c, c+1);
        }

        c = cast(dchar)FT_Get_Next_Char(face, c, &glyph);
    }
    return coverage;
}

private:

__gshared FT_Library gFtLib = null;

shared static this() {
    import dgt : registerSubsystem;
    registerSubsystem(new FtSubsystem);
}

class FtSubsystem : Subsystem {
    override @property bool running() const {
        return gFtLib !is null;
    }
    override void initialize() {
        enforce(FT_Init_FreeType(&gFtLib) == 0, "Could not initialize freetype");
    }
    override void finalize() {
        FT_Done_FreeType(gFtLib);
        gFtLib = null;
    }
}

final class FtScalingContext : ScalingContext
{
    mixin(atomicRcCode);

    FT_Face _face;
    float _pixelSize;
    TextShapingContext _textShaper;
    Glyph[GlyphId] _glyphs;

    this (FT_Face face, float pixelSize) {
        _face = face;
        FT_Reference_Face(face);
        _pixelSize = pixelSize;
    }

    override void dispose() {
        if (_textShaper) {
            _textShaper.release();
            _textShaper = null;
        }
        FT_Done_Face(_face);
        _face = null;
    }

    override @property float pixelSize() {
        return _pixelSize;
    }

    override GlyphMetrics glyphMetrics(in GlyphId glyphId) {
        Glyph* glp = glyphId in _glyphs;
        if (glp && !glp._metrics.isNull) {
            return glp._metrics;
        }

        ensureSize();
        FT_Load_Glyph(_face, glyphId, loadFlags);

        const metrics = metricsFromFace();

        if (glp) {
            glp._metrics = metrics;
        }
        else {
            auto gl = new Glyph(glyphId);
            gl._metrics = metrics;
            _glyphs[glyphId] = gl;
        }

        return metrics;
    }

    override void getOutline(in GlyphId glyphId, OutlineAccumulator oa) {
        ensureSize();
        enforce(0 == FT_Load_Glyph(_face, glyphId, FT_LOAD_NO_BITMAP), "Could not load glyph for outline");
        FT_Outline_Funcs funcs;
        funcs.move_to = &dgt_ftOutlineMoveTo;
        funcs.line_to = &dgt_ftOutlineLineTo;
        funcs.conic_to = &dgt_ftOutlineConicTo;
        funcs.cubic_to = &dgt_ftOutlineCubicTo;
        enforce(0 == FT_Outline_Decompose(&_face.glyph.outline, &funcs, cast(void*)oa), "Could not decompose outline");
    }

    override Glyph renderGlyph(in GlyphId glyphId) {

        Glyph* glp = glyphId in _glyphs;
        if (glp && (glp.img || glp._isWhitespace)) {
            return *glp;
        }

        ensureSize();
        IVec2 bearing = IVec2(0, 0);
        bool yReversed;
        bool ownedByFT;
        auto img = renderGlyphPriv(glyphId, bearing, yReversed, ownedByFT);

        Image glImg;
        if (img && yReversed) {
            glImg = new Image(img.format, img.size, img.stride);
            glImg.blitFrom(img, IPoint(0, 0), IPoint(0, 0), img.size, yReversed);
        }
        else if (img && ownedByFT) {
            glImg = img.dup;
        }
        else if (img) {
            glImg = img;
        }

        // if (glImg) {
        //     import std.format;
        //     static int num;
        //     glImg.saveToFile(format("glyph%s.png", num++));
        // }

        Glyph gl = glp ? *glp : new Glyph(glyphId);
        gl._img = glImg;
        gl._bearing = cast(FVec2)bearing;
        gl._isWhitespace = glImg is null;
        if (gl._metrics.isNull) {
            gl._metrics = metricsFromFace();
        }

        if (!glp) {
            _glyphs[glyphId] = gl;
        }
        return gl;
    }

    override TextShapingContext getTextShapingContext() {
        if (!_textShaper) {
            import dgt.text.port.hb : HbTextShapingContext;
            ensureSize();
            _textShaper = new HbTextShapingContext(_face, loadFlags);
            _textShaper.retain();
        }
        return _textShaper;
    }

    private void ensureSize() {
        import std.math : round;
        FT_Set_Pixel_Sizes(_face, 0, cast(FT_UInt)(round(_pixelSize)));
    }

    /// Render and return an image referencing internal FT buffer.
    /// Will be invalidated at next call of renderGlyph or rasterize
    private Image renderGlyphPriv(in GlyphId glyphId, ref IVec2 bearing, out bool yReversed, out bool ownedByFT)
    {
        // FT_Load_Char(_face, 0x82b1, loadFlags);
        FT_Load_Glyph(_face, cast(FT_UInt)glyphId, loadFlags);
        FT_Render_Glyph(_face.glyph, renderMode);
        auto slot = _face.glyph;

        immutable width = slot.bitmap.width;
        immutable height = slot.bitmap.rows;
        yReversed = slot.bitmap.pitch < 0;

        import std.math : abs;
        auto stride = abs(slot.bitmap.pitch);
        if (stride == 0) return null; // whitespace

        auto data = slot.bitmap.buffer[0 .. height*stride];
        ownedByFT = true;

        if (slot.bitmap.pixel_mode != FT_PIXEL_MODE_GRAY) {
            // convert to gray scale into a temp bitmap and copy in GC memory
            const expandOnes = slot.bitmap.pixel_mode == FT_PIXEL_MODE_MONO;
            ownedByFT = false;
            FT_Bitmap bitmap;
            FT_Bitmap_Init(&bitmap);
            FT_Bitmap_Convert(gFtLib, &slot.bitmap, &bitmap, 1);
            stride = abs(bitmap.pitch);
            yReversed = bitmap.pitch < 0;
            data = bitmap.buffer[0 .. height*stride].dup;
            if (expandOnes) {
                // It happens with small size font with many details
                // (typically asian) that freetype renders in mono.
                // FT_Bitmap_Convert expands to 8bpp depth, but keeps ones and zeros
                // (which would result invisible on a scale from 0 to 255).
                // We expand the ones to an alpha value that look similar to other shaded fonts.
                enum expandedValue = 212;
                foreach (ref b; data) {
                    if (b != 0) b = expandedValue;
                }
            }
            FT_Bitmap_Done(gFtLib, &bitmap);
        }

        bearing = vec(slot.bitmap_left, slot.bitmap_top);
        return new Image(data, ImageFormat.a8, width, stride);
    }

    private GlyphMetrics metricsFromFace()
    {
        const gm = _face.glyph.metrics;
        return GlyphMetrics(
            fvec(gm.width/64f, gm.height/64f),

            fvec(gm.horiBearingX/64f, gm.horiBearingY/64f),
            gm.horiAdvance/64f,

            fvec(gm.vertBearingX/64f, gm.vertBearingY/64f),
            gm.vertAdvance/64f,
        );
    }

    private enum loadFlags = FT_LOAD_TARGET_LIGHT;
    private enum renderMode = FT_RENDER_MODE_LIGHT;
}


FVec2 fromFtVec(const(FT_Vector)* vec) {
    return FVec2(vec.x/64f, vec.y/64f);
}

extern(C) nothrow
{
    int dgt_ftOutlineMoveTo(const(FT_Vector)* to, void* user)
    {
        auto oa = cast(OutlineAccumulator) user;
        try {
            oa.moveTo(fromFtVec(to));
        }
        catch(Exception ex) {
            return 1;
        }
        return 0;
    }

    int dgt_ftOutlineLineTo(const(FT_Vector)* to, void* user)
    {
        auto oa = cast(OutlineAccumulator) user;
        try {
            oa.lineTo(fromFtVec(to));
        }
        catch(Exception ex) {
            return 1;
        }
        return 0;
    }

    int dgt_ftOutlineConicTo(const(FT_Vector)* control, const(FT_Vector)* to, void* user)
    {
        auto oa = cast(OutlineAccumulator) user;
        try {
            oa.conicTo(fromFtVec(control), fromFtVec(to));
        }
        catch(Exception ex) {
            return 1;
        }
        return 0;
    }

    int dgt_ftOutlineCubicTo(const(FT_Vector)* control1, const(FT_Vector)* control2, const(FT_Vector)* to, void* user)
    {
        auto oa = cast(OutlineAccumulator) user;
        try {
            oa.cubicTo(fromFtVec(control1), fromFtVec(control2), fromFtVec(to));
        }
        catch(Exception ex) {
            return 1;
        }
        return 0;
    }
}
