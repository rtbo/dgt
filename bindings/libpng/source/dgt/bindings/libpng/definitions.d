module dgt.bindings.libpng.definitions;

import dgt.bindings.libpng.pnglibconf;
import dgt.bindings.libpng.pngconf;

enum PNG_LIBPNG_VER_STRING = "1.6.16";
enum PNG_HEADER_VERSION_STRING = " libpng version 1.6.16 - December 22, 2014\n";

enum PNG_LIBPNG_VER_SONUM = 16;
enum PNG_LIBPNG_VER_DLLNUM = 16;

enum PNG_LIBPNG_VER_MAJOR = 1;
enum PNG_LIBPNG_VER_MINOR = 6;
enum PNG_LIBPNG_VER_RELEASE = 16;

enum PNG_LIBPNG_VER_BUILD = 0;

enum PNG_LIBPNG_BUILD_ALPHA = 1;
enum PNG_LIBPNG_BUILD_BETA = 2;
enum PNG_LIBPNG_BUILD_RC = 3;
enum PNG_LIBPNG_BUILD_STABLE = 4;
enum PNG_LIBPNG_BUILD_RELEASE_STATUS_MASK = 7;

enum PNG_LIBPNG_BUILD_PATCH = 8;
enum PNG_LIBPNG_BUILD_PRIVATE = 16;
enum PNG_LIBPNG_BUILD_SPECIAL = 32;

alias PNG_LIBPNG_BUILD_BASE_TYPE = PNG_LIBPNG_BUILD_STABLE;

enum PNG_LIBPNG_VER = 10616;

version (PNG_USER_PRIVATEBUILD)
{
    enum PNG_LIBPNG_BUILD_TYPE = (PNG_LIBPNG_BUILD_BASE_TYPE | PNG_LIBPNG_BUILD_PRIVATE);
}
else
{
    version (PNG_LIBPNG_SPECIALBUILD)
    {
        enum PNG_LIBPNG_BUILD_TYPE = (PNG_LIBPNG_BUILD_BASE_TYPE | PNG_LIBPNG_BUILD_SPECIAL);
    }
    else
    {
        enum PNG_LIBPNG_BUILD_TYPE = (PNG_LIBPNG_BUILD_BASE_TYPE);
    }
}

// extern(C) for function pointers
extern (C) nothrow @nogc:

alias png_libpng_version_1_6_16 = char*;

struct png_struct;
alias png_const_structp = const(png_struct)*;
alias png_structp = png_struct*;
alias png_structpp = png_struct**;

struct png_info;
alias png_infop = png_info*;
alias png_const_infop = const(png_info)*;
alias png_infopp = png_info**;

alias png_structrp = png_struct*;
alias png_const_structrp = const(png_struct)*;
alias png_inforp = png_info*;
alias png_const_inforp = const(png_info)*;

struct png_color
{
    png_byte red;
    png_byte green;
    png_byte blue;
}

alias png_colorp = png_color*;
alias png_const_colorp = const(png_color)*;
alias png_colorpp = png_color**;

struct png_color_16
{
    png_byte index;
    png_uint_16 red;
    png_uint_16 green;
    png_uint_16 blue;
    png_uint_16 gray;
}

alias png_color_16p = png_color_16*;
alias png_const_color_16p = const(png_color_16)*;
alias png_color_16pp = png_color_16**;

struct png_color_8
{
    png_byte red;
    png_byte green;
    png_byte blue;
    png_byte gray;
    png_byte alpha;
}

alias png_color_8p = png_color_8*;
alias png_const_color_8p = const(png_color_8)*;
alias png_color_8pp = png_color_8**;

struct png_sPLT_entry
{
    png_uint_16 red;
    png_uint_16 green;
    png_uint_16 blue;
    png_uint_16 alpha;
    png_uint_16 frequency;
}

alias png_sPLT_entryp = png_sPLT_entry*;
alias png_const_sPLT_entryp = const(png_sPLT_entry)*;
alias png_sPLT_entrypp = png_sPLT_entry**;

struct png_sPLT_t
{
    png_charp name;
    png_byte depth;
    png_sPLT_entryp entries;
    png_int_32 nentries;
}

alias png_sPLT_tp = png_sPLT_t*;
alias png_const_sPLT_tp = const(png_sPLT_t)*;
alias png_sPLT_tpp = png_sPLT_t**;

static if (PNG_TEXT_SUPPORTED)
{
    struct png_text
    {
        int compression;
        png_charp key;
        png_charp text;
        size_t text_length;
        size_t itxt_length;
        png_charp lang;
        png_charp lang_key;
    }

    alias png_textp = png_text*;
    alias png_const_textp = const(png_text)*;
    alias png_textpp = png_text**;
}

enum PNG_TEXT_COMPRESSION_NONE_WR = -3;
enum PNG_TEXT_COMPRESSION_zTXt_WR = -2;
enum PNG_TEXT_COMPRESSION_NONE = -1;
enum PNG_TEXT_COMPRESSION_zTXt = 0;
enum PNG_ITXT_COMPRESSION_NONE = 1;
enum PNG_ITXT_COMPRESSION_zTXt = 2;
enum PNG_TEXT_COMPRESSION_LAST = 3;

struct png_time
{
    png_uint_16 year;
    png_byte month;
    png_byte day;
    png_byte hour;
    png_byte minute;
    png_byte second;
}

alias png_timep = png_time*;
alias png_const_timep = const(png_time)*;
alias png_timepp = png_time**;

static if (PNG_STORE_UNKNOWN_CHUNKS_SUPPORTED || PNG_USER_CHUNKS_SUPPORTED)
{
    struct png_unknown_chunk
    {
        png_byte[5] name;
        png_byte* data;
        png_size_t size;

        png_byte location;
    }

    alias png_unknown_chunkp = png_unknown_chunk*;
    alias png_const_unknown_chunkp = const(png_unknown_chunk)*;
    alias png_unknown_chunkpp = png_unknown_chunk**;
}

enum PNG_HAVE_IHDR = 0x01;
enum PNG_HAVE_PLTE = 0x02;
enum PNG_AFTER_IDAT = 0x08;

enum PNG_UINT_31_MAX = cast(uint) 0x7fffffffL;
enum PNG_UINT_32_MAX = cast(uint)(-1);
enum PNG_SIZE_MAX = cast(size_t)(-1);

enum PNG_FP_1 = 100000;
enum PNG_FP_HALF = 50000;
enum PNG_FP_MAX = (cast(png_fixed_point) 0x7fffffffL);
enum PNG_FP_MIN = (-PNG_FP_MAX);

enum PNG_COLOR_MASK_PALETTE = 1;
enum PNG_COLOR_MASK_COLOR = 2;
enum PNG_COLOR_MASK_ALPHA = 4;

enum PNG_COLOR_TYPE_GRAY = 0;
enum PNG_COLOR_TYPE_PALETTE = (PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_PALETTE);
enum PNG_COLOR_TYPE_RGB = (PNG_COLOR_MASK_COLOR);
enum PNG_COLOR_TYPE_RGB_ALPHA = (PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_ALPHA);
enum PNG_COLOR_TYPE_GRAY_ALPHA = (PNG_COLOR_MASK_ALPHA);

alias PNG_COLOR_TYPE_RGBA = PNG_COLOR_TYPE_RGB_ALPHA;
alias PNG_COLOR_TYPE_GA = PNG_COLOR_TYPE_GRAY_ALPHA;

enum PNG_COMPRESSION_TYPE_BASE = 0;
alias PNG_COMPRESSION_TYPE_DEFAULT = PNG_COMPRESSION_TYPE_BASE;

enum PNG_FILTER_TYPE_BASE = 0;
enum PNG_INTRAPIXEL_DIFFERENCING = 64;
alias PNG_FILTER_TYPE_DEFAULT = PNG_FILTER_TYPE_BASE;

enum PNG_INTERLACE_NONE = 0;
enum PNG_INTERLACE_ADAM7 = 1;
enum PNG_INTERLACE_LAST = 2;

enum PNG_OFFSET_PIXEL = 0;
enum PNG_OFFSET_MICROMETER = 1;
enum PNG_OFFSET_LAST = 2;

enum PNG_EQUATION_LINEAR = 0;
enum PNG_EQUATION_BASE_E = 1;
enum PNG_EQUATION_ARBITRARY = 2;
enum PNG_EQUATION_HYPERBOLIC = 3;
enum PNG_EQUATION_LAST = 4;

enum PNG_SCALE_UNKNOWN = 0;
enum PNG_SCALE_METER = 1;
enum PNG_SCALE_RADIAN = 2;
enum PNG_SCALE_LAST = 3;

enum PNG_RESOLUTION_UNKNOWN = 0;
enum PNG_RESOLUTION_METER = 1;
enum PNG_RESOLUTION_LAST = 2;

enum PNG_sRGB_INTENT_PERCEPTUAL = 0;
enum PNG_sRGB_INTENT_RELATIVE = 1;
enum PNG_sRGB_INTENT_SATURATION = 2;
enum PNG_sRGB_INTENT_ABSOLUTE = 3;
enum PNG_sRGB_INTENT_LAST = 4;

enum PNG_KEYWORD_MAX_LENGTH = 79;

enum PNG_MAX_PALETTE_LENGTH = 256;

enum PNG_INFO_gAMA = 0x0001;
enum PNG_INFO_sBIT = 0x0002;
enum PNG_INFO_cHRM = 0x0004;
enum PNG_INFO_PLTE = 0x0008;
enum PNG_INFO_tRNS = 0x0010;
enum PNG_INFO_bKGD = 0x0020;
enum PNG_INFO_hIST = 0x0040;
enum PNG_INFO_pHYs = 0x0080;
enum PNG_INFO_oFFs = 0x0100;
enum PNG_INFO_tIME = 0x0200;
enum PNG_INFO_pCAL = 0x0400;
enum PNG_INFO_sRGB = 0x0800;
enum PNG_INFO_iCCP = 0x1000;
enum PNG_INFO_sPLT = 0x2000;
enum PNG_INFO_sCAL = 0x4000;
enum PNG_INFO_IDAT = 0x8000;

struct png_row_info
{
    uint width;
    size_t rowbytes;
    png_byte color_type;
    png_byte bit_depth;
    png_byte channels;
    png_byte pixel_depth;
}

alias png_row_infop = png_row_info*;
alias png_row_infopp = png_row_info**;

alias png_error_ptr = void function(png_structp, png_const_charp);
alias png_rw_ptr = void function(png_structp, png_bytep, size_t);
alias png_flush_ptr = void function(png_structp);
alias png_read_status_ptr = void function(png_structp, uint, int);
alias png_write_status_ptr = void function(png_structp, uint, int);

static if (PNG_PROGRESSIVE_READ_SUPPORTED)
{
    alias png_progressive_info_ptr = void function(png_structp, png_infop);
    alias png_progressive_end_ptr = void function(png_structp, png_infop);

    alias png_progressive_row_ptr = void function(png_structp, png_bytep, uint, int);
}

static if (PNG_READ_USER_TRANSFORM_SUPPORTED || PNG_WRITE_USER_TRANSFORM_SUPPORTED)
{
    alias png_user_transform_ptr = void function(png_structp, png_row_infop, png_bytep);
}

static if (PNG_USER_CHUNKS_SUPPORTED)
{
    alias png_user_chunk_ptr = int function(png_structp, png_unknown_chunkp);
}

static if (PNG_SETJMP_SUPPORTED)
{
    //alias void function(PNGARG((jmp_buf, int)), alias) png_longjmp_ptr;
}

enum PNG_TRANSFORM_IDENTITY = 0x0000;
enum PNG_TRANSFORM_STRIP_16 = 0x0001;
enum PNG_TRANSFORM_STRIP_ALPHA = 0x0002;
enum PNG_TRANSFORM_PACKING = 0x0004;
enum PNG_TRANSFORM_PACKSWAP = 0x0008;
enum PNG_TRANSFORM_EXPAND = 0x0010;
enum PNG_TRANSFORM_INVERT_MONO = 0x0020;
enum PNG_TRANSFORM_SHIFT = 0x0040;
enum PNG_TRANSFORM_BGR = 0x0080;
enum PNG_TRANSFORM_SWAP_ALPHA = 0x0100;
enum PNG_TRANSFORM_SWAP_ENDIAN = 0x0200;
enum PNG_TRANSFORM_INVERT_ALPHA = 0x0400;
enum PNG_TRANSFORM_STRIP_FILLER = 0x0800;

alias PNG_TRANSFORM_STRIP_FILLER_BEFORE = PNG_TRANSFORM_STRIP_FILLER;
enum PNG_TRANSFORM_STRIP_FILLER_AFTER = 0x1000;

enum PNG_TRANSFORM_GRAY_TO_RGB = 0x2000;

enum PNG_TRANSFORM_EXPAND_16 = 0x4000;
enum PNG_TRANSFORM_SCALE_16 = 0x8000;

enum PNG_FLAG_MNG_EMPTY_PLTE = 0x01;
enum PNG_FLAG_MNG_FILTER_64 = 0x04;
enum PNG_ALL_MNG_FEATURES = 0x05;

alias png_malloc_ptr = png_voidp function(png_structp, png_alloc_size_t);
alias png_free_ptr = void function(png_structp, png_voidp);

static if (PNG_READ_RGB_TO_GRAY_SUPPORTED)
{
    enum PNG_ERROR_ACTION_NONE = 1;
    enum PNG_ERROR_ACTION_WARN = 2;
    enum PNG_ERROR_ACTION_ERROR = 3;
    enum PNG_RGB_TO_GRAY_DEFAULT = (-1);
}

static if (PNG_READ_ALPHA_MODE_SUPPORTED)
{
    enum PNG_ALPHA_PNG = 0;
    enum PNG_ALPHA_STANDARD = 1;
    enum PNG_ALPHA_ASSOCIATED = 1;
    enum PNG_ALPHA_PREMULTIPLIED = 1;
    enum PNG_ALPHA_OPTIMIZED = 2;
    enum PNG_ALPHA_BROKEN = 3;
}

static if (PNG_READ_GAMMA_SUPPORTED || PNG_READ_ALPHA_MODE_SUPPORTED)
{
    enum PNG_DEFAULT_sRGB = -1;
    enum PNG_GAMMA_MAC_18 = -2;
    enum PNG_GAMMA_sRGB = 220000;
    alias PNG_GAMMA_LINEAR = PNG_FP_1;
}

static if (PNG_READ_FILLER_SUPPORTED || PNG_WRITE_FILLER_SUPPORTED)
{
    enum PNG_FILLER_BEFORE = 0;
    enum PNG_FILLER_AFTER = 1;
}
static if (PNG_READ_BACKGROUND_SUPPORTED)
{
    enum PNG_BACKGROUND_GAMMA_UNKNOWN = 0;
    enum PNG_BACKGROUND_GAMMA_SCREEN = 1;
    enum PNG_BACKGROUND_GAMMA_FILE = 2;
    enum PNG_BACKGROUND_GAMMA_UNIQUE = 3;
}

enum PNG_CRC_DEFAULT = 0;
enum PNG_CRC_ERROR_QUIT = 1;
enum PNG_CRC_WARN_DISCARD = 2;
enum PNG_CRC_WARN_USE = 3;
enum PNG_CRC_QUIET_USE = 4;
enum PNG_CRC_NO_CHANGE = 5;

enum PNG_NO_FILTERS = 0x00;
enum PNG_FILTER_NONE = 0x08;
enum PNG_FILTER_SUB = 0x10;
enum PNG_FILTER_UP = 0x20;
enum PNG_FILTER_AVG = 0x40;
enum PNG_FILTER_PAETH = 0x80;
enum PNG_ALL_FILTERS = (
            PNG_FILTER_NONE | PNG_FILTER_SUB | PNG_FILTER_UP | PNG_FILTER_AVG | PNG_FILTER_PAETH);

enum PNG_FILTER_VALUE_NONE = 0;
enum PNG_FILTER_VALUE_SUB = 1;
enum PNG_FILTER_VALUE_UP = 2;
enum PNG_FILTER_VALUE_AVG = 3;
enum PNG_FILTER_VALUE_PAETH = 4;
enum PNG_FILTER_VALUE_LAST = 5;

enum PNG_FILTER_HEURISTIC_DEFAULT = 0;
enum PNG_FILTER_HEURISTIC_UNWEIGHTED = 1;
enum PNG_FILTER_HEURISTIC_WEIGHTED = 2;
enum PNG_FILTER_HEURISTIC_LAST = 3;

enum PNG_DESTROY_WILL_FREE_DATA = 1;
enum PNG_SET_WILL_FREE_DATA = 1;
enum PNG_USER_WILL_FREE_DATA = 2;

enum PNG_FREE_HIST = 0x0008;
enum PNG_FREE_ICCP = 0x0010;
enum PNG_FREE_SPLT = 0x0020;
enum PNG_FREE_ROWS = 0x0040;
enum PNG_FREE_PCAL = 0x0080;
enum PNG_FREE_SCAL = 0x0100;
static if (PNG_STORE_UNKNOWN_CHUNKS_SUPPORTED)
{
    enum PNG_FREE_UNKN = 0x0200;
}

enum PNG_FREE_PLTE = 0x1000;
enum PNG_FREE_TRNS = 0x2000;
enum PNG_FREE_TEXT = 0x4000;
enum PNG_FREE_ALL = 0x7fff;
enum PNG_FREE_MUL = 0x4220;

static if (!PNG_ERROR_TEXT_SUPPORTED)
{
    void png_error(S1, S2)(S1 s1, S2 s2)
    {
        png_err(s1);
    }

    void png_chunk_error(S1, S2)(S1 s1, S2 s2)
    {
        png_err(s1);
    }
}

static if (!PNG_WARNINGS_SUPPORTED)
{
    void png_warning(S1, S2)(S1 s1, S2 s2)
    {
    }

    void png_chunk_warning(S1, S2)(S1 s1, S2 s2)
    {
    }
}

static if (!PNG_BENIGN_ERRORS_SUPPORTED)
{
    version (PNG_ALLOW_BENIGN_ERRORS)
    {
        alias png_benign_error = png_warning;
        alias png_chunk_benign_error = png_chunk_warning;
    }
    else
    {
        alias png_benign_error = png_error;
        alias png_chunk_benign_error = png_chunk_error;
    }
}

enum PNG_HANDLE_CHUNK_AS_DEFAULT = 0;
enum PNG_HANDLE_CHUNK_NEVER = 1;
enum PNG_HANDLE_CHUNK_IF_SAFE = 2;
enum PNG_HANDLE_CHUNK_ALWAYS = 3;
enum PNG_HANDLE_CHUNK_LAST = 4;

static if (PNG_IO_STATE_SUPPORTED)
{
    enum PNG_IO_NONE = 0x0000;
    enum PNG_IO_READING = 0x0001;
    enum PNG_IO_WRITING = 0x0002;
    enum PNG_IO_SIGNATURE = 0x0010;
    enum PNG_IO_CHUNK_HDR = 0x0020;
    enum PNG_IO_CHUNK_DATA = 0x0040;
    enum PNG_IO_CHUNK_CRC = 0x0080;
    enum PNG_IO_MASK_OP = 0x000f;
    enum PNG_IO_MASK_LOC = 0x00f0;
}

enum PNG_INTERLACE_ADAM7_PASSES = 7;

auto PNG_PASS_START_ROW(T)(T pass)
{
    return (((1 & ~(pass)) << (3 - ((pass) >> 1))) & 7);
}

auto PNG_PASS_START_COL(T)(T pass)
{
    return (((1 & (pass)) << (3 - (((pass) + 1) >> 1))) & 7);
}

auto PNG_PASS_ROW_OFFSET(T)(T pass)
{
    return ((pass) > 2 ? (8 >> (((pass) - 1) >> 1)) : 8);
}

auto PNG_PASS_COL_OFFSET(T)(T pass)
{
    return (1 << ((7 - (pass)) >> 1));
}

auto PNG_PASS_ROW_SHIFT(T)(T pass)
{
    return ((pass) > 2 ? (8 - (pass)) >> 1 : 3);
}

auto PNG_PASS_COL_SHIFT(T)(T pass)
{
    return ((pass) > 1 ? (7 - (pass)) >> 1 : 3);
}

auto PNG_PASS_ROWS(S, T)(S height, T pass)
{
    return (((height) + (((1 << PNG_PASS_ROW_SHIFT(pass)) - 1) - PNG_PASS_START_ROW(
            pass))) >> PNG_PASS_ROW_SHIFT(pass));
}

auto PNG_PASS_COLS(S, T)(S width, T pass)
{
    return (((width) + (((1 << PNG_PASS_COL_SHIFT(pass)) - 1) - PNG_PASS_START_COL(
            pass))) >> PNG_PASS_COL_SHIFT(pass));
}

auto PNG_ROW_FROM_PASS_ROW(S, T)(S y_in, T pass)
{
    return (((y_in) << PNG_PASS_ROW_SHIFT(pass)) + PNG_PASS_START_ROW(pass));
}

auto PNG_COL_FROM_PASS_COL(S, T)(S x_in, T pass)
{
    return (((x_in) << PNG_PASS_COL_SHIFT(pass)) + PNG_PASS_START_COL(pass));
}

auto PNG_PASS_MASK(S, T)(S pass, T off)
{
    return (((0x110145AF >> (((7 - (off)) - (pass)) << 2)) & 0xF) | (
            (0x01145AF0 >> (((7 - (off)) - (pass)) << 2)) & 0xF0));
}

auto PNG_ROW_IN_INTERLACE_PASS(T)(y, pass)
{
    return ((PNG_PASS_MASK(pass, 0) >> ((y) & 7)) & 1);
}

auto PNG_COL_IN_INTERLACE_PASS(T)(x, pass)
{
    return ((PNG_PASS_MASK(pass, 1) >> ((x) & 7)) & 1);
}

auto png_composite(T)(out T composite, png_uint_16 fg, png_uint_16 alpha, png_uint_16 bg)
{
    return (composite) = cast(png_byte)(((fg) * (alpha) + (bg) * (255 - (alpha)) + 127) / 255);
}

auto png_composite_16(T)(out T composite, uint fg, uint alpha, uint bg)
{
    return (composite) = cast(png_uint_16)(((fg) * (alpha) + (bg) * (65535 - (alpha)) + 32767) / 65535);
}

version (PNG_USE_READ_MACROS)
{
    auto PNG_get_uint_32(png_const_bytep buf) pure
    {
        return ((cast(uint)(*(buf)) << 24) + (cast(uint)(*((buf) + 1)) << 16) + (
                cast(uint)(*((buf) + 2)) << 8) + (cast(uint)(*((buf) + 3))));
    }

    auto PNG_get_uint_16(png_const_bytep buf) pure
    {
        return (cast(png_uint_16)((cast(uint)(*(buf)) << 8) + (cast(uint)(*((buf) + 1)))));
    }

    auto PNG_get_int_32(T)(png_const_bytep buf) pure
    {
        return (cast(png_int_32)((*(buf) & 0x80)
                ? -(cast(png_int_32)((png_get_uint_32(buf) ^ 0xffffffffL) + 1))
                : cast(png_int_32) png_get_uint_32(buf)));
    }

    static if (!PNG_PREFIX)
    {
        auto png_get_uint_32(S)(S s) pure
        {
            return PNG_get_uint_32(s);
        }

        auto png_get_uint_16(S)(S s) pure
        {
            return PNG_get_uint_16(s);
        }

        auto png_get_int_32(S)(S s) pure
        {
            return PNG_get_int_32(s);
        }
    }
}
else
{
    auto PNG_get_uint_32(S)(S s) pure
    {
        return png_get_uint_32(s);
    }

    auto PNG_get_uint_16(S)(S s) pure
    {
        return png_get_uint_16(s);
    }

    auto PNG_get_int_32(S)(S s) pure
    {
        return png_get_int_32(s);
    }
}

static if (PNG_SIMPLIFIED_READ_SUPPORTED || PNG_SIMPLIFIED_WRITE_SUPPORTED)
{
    enum PNG_IMAGE_VERSION = 1;

    struct png_control;
    alias png_controlp = png_control*;
    struct png_image
    {
        png_controlp opaque;
        png_uint_32 version_;
        png_uint_32 width;
        png_uint_32 height;
        png_uint_32 format;
        png_uint_32 flags;
        png_uint_32 colormap_entries;

        png_uint_32 warning_or_error;

        char[64] message;
    };
    alias png_imagep = png_image*;

    enum PNG_IMAGE_WARNING = 1;
    enum PNG_IMAGE_ERROR = 2;
    bool PNG_IMAGE_FAILED(ref const(png_image) png_cntrl)
    {
        return (png_cntrl.warning_or_error & 0x03) > 1;
    }

    enum PNG_FORMAT_FLAG_ALPHA = 0x01U;
    enum PNG_FORMAT_FLAG_COLOR = 0x02U;
    enum PNG_FORMAT_FLAG_LINEAR = 0x04U;
    enum PNG_FORMAT_FLAG_COLORMAP = 0x08U;

    static if (PNG_FORMAT_BGR_SUPPORTED)
    {
        enum PNG_FORMAT_FLAG_BGR = 0x10U;
    }

    static if (PNG_FORMAT_AFIRST_SUPPORTED)
    {
        enum PNG_FORMAT_FLAG_AFIRST = 0x20U;
    }

    enum PNG_FORMAT_GRAY = 0;
    enum PNG_FORMAT_GA = PNG_FORMAT_FLAG_ALPHA;
    enum PNG_FORMAT_AG = (PNG_FORMAT_GA | PNG_FORMAT_FLAG_AFIRST);
    enum PNG_FORMAT_RGB = PNG_FORMAT_FLAG_COLOR;
    enum PNG_FORMAT_BGR = (PNG_FORMAT_FLAG_COLOR | PNG_FORMAT_FLAG_BGR);
    enum PNG_FORMAT_RGBA = (PNG_FORMAT_RGB | PNG_FORMAT_FLAG_ALPHA);
    enum PNG_FORMAT_ARGB = (PNG_FORMAT_RGBA | PNG_FORMAT_FLAG_AFIRST);
    enum PNG_FORMAT_BGRA = (PNG_FORMAT_BGR | PNG_FORMAT_FLAG_ALPHA);
    enum PNG_FORMAT_ABGR = (PNG_FORMAT_BGRA | PNG_FORMAT_FLAG_AFIRST);

    enum PNG_FORMAT_LINEAR_Y = PNG_FORMAT_FLAG_LINEAR;
    enum PNG_FORMAT_LINEAR_Y_ALPHA = (PNG_FORMAT_FLAG_LINEAR | PNG_FORMAT_FLAG_ALPHA);
    enum PNG_FORMAT_LINEAR_RGB = (PNG_FORMAT_FLAG_LINEAR | PNG_FORMAT_FLAG_COLOR);
    enum PNG_FORMAT_LINEAR_RGB_ALPHA = (
                PNG_FORMAT_FLAG_LINEAR | PNG_FORMAT_FLAG_COLOR | PNG_FORMAT_FLAG_ALPHA);

    enum PNG_FORMAT_RGB_COLORMAP = (PNG_FORMAT_RGB | PNG_FORMAT_FLAG_COLORMAP);
    enum PNG_FORMAT_BGR_COLORMAP = (PNG_FORMAT_BGR | PNG_FORMAT_FLAG_COLORMAP);
    enum PNG_FORMAT_RGBA_COLORMAP = (PNG_FORMAT_RGBA | PNG_FORMAT_FLAG_COLORMAP);
    enum PNG_FORMAT_ARGB_COLORMAP = (PNG_FORMAT_ARGB | PNG_FORMAT_FLAG_COLORMAP);
    enum PNG_FORMAT_BGRA_COLORMAP = (PNG_FORMAT_BGRA | PNG_FORMAT_FLAG_COLORMAP);
    enum PNG_FORMAT_ABGR_COLORMAP = (PNG_FORMAT_ABGR | PNG_FORMAT_FLAG_COLORMAP);

    auto PNG_IMAGE_SAMPLE_CHANNELS(F)(F fmt) pure
    {
        return (((fmt) & (PNG_FORMAT_FLAG_COLOR | PNG_FORMAT_FLAG_ALPHA)) + 1);
    }

    auto PNG_IMAGE_SAMPLE_COMPONENT_SIZE(F)(F fmt) pure
    {
        return ((((fmt) & PNG_FORMAT_FLAG_LINEAR) >> 2) + 1);
    }

    auto PNG_IMAGE_SAMPLE_SIZE(F)(F fmt) pure
    {
        return (PNG_IMAGE_SAMPLE_CHANNELS(fmt) * PNG_IMAGE_SAMPLE_COMPONENT_SIZE(fmt));
    }

    auto PNG_IMAGE_MAXIMUM_COLORMAP_COMPONENTS(F)(F fmt) pure
    {
        return (PNG_IMAGE_SAMPLE_CHANNELS(fmt) * 256);
    }

    auto PNG_IMAGE_PIXEL_(string test, F)(F fmt) pure
    {
        return (((fmt) & PNG_FORMAT_FLAG_COLORMAP) ? 1 : mixin(test ~ "(fmt)"));
    }

    auto PNG_IMAGE_PIXEL_CHANNELS(F)(F fmt) pure
    {
        return PNG_IMAGE_PIXEL_!"PNG_IMAGE_SAMPLE_CHANNELS"(fmt);
    }

    auto PNG_IMAGE_PIXEL_COMPONENT_SIZE(F)(F fmt) pure
    {
        return PNG_IMAGE_PIXEL_!"PNG_IMAGE_SAMPLE_COMPONENT_SIZE"(fmt);
    }

    auto PNG_IMAGE_PIXEL_SIZE(F)(F fmt) pure
    {
        return PNG_IMAGE_PIXEL_!"PNG_IMAGE_SAMPLE_SIZE"(fmt);
    }

    auto PNG_IMAGE_ROW_STRIDE(ref const(png_image) image) pure
    {
        return (PNG_IMAGE_PIXEL_CHANNELS((image).format) * (image).width);
    }

    auto PNG_IMAGE_BUFFER_SIZE(S)(ref const(png_image) image, S row_stride) pure
    {
        return (PNG_IMAGE_PIXEL_COMPONENT_SIZE((image).format) * (image).height * (row_stride));
    }

    auto PNG_IMAGE_SIZE(ref const(png_image) image) pure
    {
        return PNG_IMAGE_BUFFER_SIZE(image, PNG_IMAGE_ROW_STRIDE(image));
    }

    auto PNG_IMAGE_COLORMAP_SIZE(ref const(png_image) image) pure
    {
        return (PNG_IMAGE_SAMPLE_SIZE((image).format) * (image).colormap_entries);
    }

    enum PNG_IMAGE_FLAG_COLORSPACE_NOT_sRGB = 0x01;

    enum PNG_IMAGE_FLAG_FAST = 0x02;

    enum PNG_IMAGE_FLAG_16BIT_sRGB = 0x04;

}

static if (PNG_SET_OPTION_SUPPORTED)
{
    enum PNG_MAXIMUM_INFLATE_WINDOW = 2;
    enum PNG_SKIP_sRGB_CHECK_PROFILE = 4;
    enum PNG_OPTION_NEXT = 6;

    enum PNG_OPTION_UNSET = 0;
    enum PNG_OPTION_INVALID = 1;
    enum PNG_OPTION_OFF = 2;
    enum PNG_OPTION_ON = 3;
}
