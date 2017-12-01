module dgt.bindings.turbojpeg.definitions;

extern (C) nothrow @nogc:
enum TJ_NUMSAMP = 5;
enum TJSAMP
{
    TJSAMP_444 = 0,
    TJSAMP_422,
    TJSAMP_420,
    TJSAMP_GRAY,
    TJSAMP_440
}

immutable(int)[TJ_NUMSAMP] tjMCUWidth = [8, 16, 16, 8, 8];
immutable(int)[TJ_NUMSAMP] tjMCUHeight = [8, 8, 16, 8, 16];
enum TJ_NUMPF = 11;
enum TJPF
{
    TJPF_RGB = 0,
    TJPF_BGR,
    TJPF_RGBX,
    TJPF_BGRX,
    TJPF_XBGR,
    TJPF_XRGB,
    TJPF_GRAY,
    TJPF_RGBA,
    TJPF_BGRA,
    TJPF_ABGR,
    TJPF_ARGB
}

immutable(int)[TJ_NUMPF] tjRedOffset = [0, 2, 0, 2, 3, 1, 0, 0, 2, 3, 1];
immutable(int)[TJ_NUMPF] tjGreenOffset = [1, 1, 1, 1, 2, 2, 0, 1, 1, 2, 2];
immutable(int)[TJ_NUMPF] tjBlueOffset = [2, 0, 2, 0, 1, 3, 0, 2, 0, 1, 3];
immutable(int)[TJ_NUMPF] tjPixelSize = [3, 3, 4, 4, 4, 4, 1, 4, 4, 4, 4];
enum TJFLAG_BOTTOMUP = 2;
enum TJFLAG_FORCEMMX = 8;
enum TJFLAG_FORCESSE = 16;
enum TJFLAG_FORCESSE2 = 32;
enum TJFLAG_FORCESSE3 = 128;
enum TJFLAG_FASTUPSAMPLE = 256;
enum TJFLAG_NOREALLOC = 1024;
enum TJFLAG_FASTDCT = 2048;
enum TJFLAG_ACCURATEDCT = 4096;
enum TJ_NUMXOP = 8;
enum TJXOP
{
    TJXOP_NONE = 0,
    TJXOP_HFLIP,
    TJXOP_VFLIP,
    TJXOP_TRANSPOSE,
    TJXOP_TRANSVERSE,
    TJXOP_ROT90,
    TJXOP_ROT180,
    TJXOP_ROT270
}

enum TJXOPT_PERFECT = 1;
enum TJXOPT_TRIM = 2;
enum TJXOPT_CROP = 4;
enum TJXOPT_GRAY = 8;
enum TJXOPT_NOOUTPUT = 16;
struct tjscalingfactor
{
    int num;
    int denom;
}

struct tjregion
{
    int x;
    int y;
    int w;
    int h;
}

struct tjtransform
{
    tjregion r;
    int op;
    int options;
    void* data;
    int function(short* coeffs, tjregion arrayRegion, tjregion planeRegion,
            int componentIndex, int transformIndex, tjtransform* transform) customFilter;
}

alias tjhandle = void*;
auto TJPAD(T)(T width)
{
    return (((width) + 3) & (~3));
}

auto TJSCALED(D, SF)(D dimension, SF scalingFactor)
{
    return (dimension * scalingFactor.num + scalingFactor.denom - 1) / scalingFactor.denom;
}

enum NUMSUBOPT = TJ_NUMSAMP;
enum TJ_444 = TJSAMP.TJSAMP_444;
enum TJ_422 = TJSAMP.TJSAMP_422;
enum TJ_420 = TJSAMP.TJSAMP_420;
enum TJ_411 = TJSAMP.TJSAMP_420;
enum TJ_GRAYSCALE = TJSAMP.TJSAMP_GRAY;
enum TJ_BGR = 1;
enum TJ_BOTTOMUP = TJFLAG_BOTTOMUP;
enum TJ_FORCEMMX = TJFLAG_FORCEMMX;
enum TJ_FORCESSE = TJFLAG_FORCESSE;
enum TJ_FORCESSE2 = TJFLAG_FORCESSE2;
enum TJ_ALPHAFIRST = 64;
enum TJ_FORCESSE3 = TJFLAG_FORCESSE3;
enum TJ_FASTUPSAMPLE = TJFLAG_FASTUPSAMPLE;
enum TJ_YUV = 512;
