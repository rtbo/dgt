/// Freetype typeface implementation module
module dgt.font.port.ft;

import derelict.freetype.ft;

import dgt : Subsystem;
import dgt.core.geometry;
import dgt.core.image;
import dgt.core.rc;
import dgt.font.style;
import dgt.font.typeface;
import dgt.math.vec : FVec2, IVec2;
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
        FT_Done_Face(_face);
    }

    override @property string family() {
        import std.string : fromStringz;
        return fromStringz(_face.family_name).idup;
    }

    override @property FontStyle style() {
        const flags = _face.style_flags;
        const slant = flags & FT_STYLE_FLAG_ITALIC ? FontSlant.italic : FontSlant.normal;
        const weight = flags & FT_STYLE_FLAG_BOLD ? FontWeight.bold : FontWeight.normal;
        return FontStyle(weight, slant, FontWidth.normal);
    }

    final override @property CodepointSet coverage() {
        if (_coverage.isNull) {
            _coverage = ftFaceToCoverage(_face);
        }
        return _coverage;
    }

    override GlyphId[] glyphsForString(in string text) {
        return [];
    }

    override ScalingContext makeScalingContext(in int pixelSize) {
        return new FtScalingContext(this, pixelSize);
    }

    /// Clone the typeface such as the size and glyph slot in the FT_Face
    /// can be manipulated independently by different scaling contexts
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
    protected Nullable!CodepointSet _coverage;
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
        enforce(FT_Init_FreeType(&gFtLib) == 0);
    }
    override void finalize() {
        FT_Done_FreeType(gFtLib);
        gFtLib = null;
    }
}

final class FtScalingContext : ScalingContext
{
    mixin(rcCode);

    FtTypeface _tf;
    int _pixelSize;

    this (FtTypeface tf, int pixelSize) {
        _tf = tf;
        _tf.retain();
        _pixelSize = pixelSize;
    }

    override void dispose() {
        _tf.release();
        _tf = null;
    }

    override @property Typeface typeface() {
        return _tf;
    }

    override @property int pixelSize() {
        return _pixelSize;
    }

    override GlyphMetrics glyphMetrics(in GlyphId glyph) {
        ensureSize();
        FT_Load_Glyph(ftFace, glyph, FT_LOAD_DEFAULT);

        const gm = ftFace.glyph.metrics;
        return GlyphMetrics(
            fvec(gm.width/64f, gm.height/64f),

            fvec(gm.horiBearingX/64f, gm.horiBearingY/64f),
            gm.horiAdvance/64f,

            fvec(gm.vertBearingX/64f, gm.vertBearingY/64f),
            gm.vertAdvance/64f,
        );
    }

    override void getOutline(in GlyphId glyphId, OutlineAccumulator oa) {
        ensureSize();
        enforce(0 == FT_Load_Glyph(ftFace, glyphId, FT_LOAD_NO_BITMAP));
        FT_Outline_Funcs funcs;
        funcs.move_to = &dgt_ftOutlineMoveTo;
        funcs.line_to = &dgt_ftOutlineLineTo;
        funcs.conic_to = &dgt_ftOutlineConicTo;
        funcs.cubic_to = &dgt_ftOutlineCubicTo;
        enforce(0 == FT_Outline_Decompose(&ftFace.glyph.outline, &funcs, cast(void*)oa));
    }

    override void renderGlyph(in GlyphId glyphId, Image output, in IVec2 offset, out IVec2 bearing) {
        ensureSize();
        bool yReversed = void;
        const img = renderGlyphPriv(glyphId, bearing, yReversed);

        output.blitFrom(img, IPoint(0, 0), offset, img.size, yReversed);
    }

    override Image renderGlyph(in GlyphId glyphId, out IVec2 bearing) {
        ensureSize();
        bool yReversed = void;
        const img = renderGlyphPriv(glyphId, bearing, yReversed);

        if (yReversed) {
            auto res = new Image(img.format, img.size, img.stride);
            res.blitFrom(img, IPoint(0, 0), IPoint(0, 0), img.size, yReversed);
            return res;
        }
        else {
            return img.dup;
        }
    }

    TextShapingContext makeTextShapingContext() {
        import dgt.text.port.hb : HbTextShapingContext;
        ensureSize();
        return new HbTextShapingContext(this, _tf._face);
    }

    private FT_Face ftFace() {
        return _tf._face;
    }

    private void ensureSize() {
        FT_Set_Pixel_Sizes(_tf._face, _pixelSize, _pixelSize);
    }

    /// Render and return an image referencing internal FT buffer.
    /// Will be invalidated at next call of renderGlyph or rasterize
    private const(Image) renderGlyphPriv(in GlyphId glyphId, out IVec2 bearing, out bool yReversed)
    {
        import std.math : abs;

        FT_Load_Glyph(_tf._face, cast(FT_UInt)glyphId, FT_LOAD_DEFAULT);
        FT_Render_Glyph(_tf._face.glyph, FT_RENDER_MODE_NORMAL);
        auto slot = _tf._face.glyph;
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