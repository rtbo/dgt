/// Vector graphics module
module dgt.vg;

public import dgt.vg.cmdbuf;
public import dgt.vg.context;
public import dgt.vg.path;
public import dgt.vg.penbrush;

import dgt.gfx.image : Image;
import gfx.core.log : LogTag;

import std.traits : Unqual;
import std.typecons : Flag, No;

enum dgtVgLogMask = 0x0200_0000;
package immutable dgtVgLog = LogTag("DGT-VG", dgtVgLogMask);

interface VgBackend
{
    string name();

    VgContext makeContext(Image image)
    in (image.vgCompatible, "Invalid image for vector graphics");
}

VgContext makeVgContext(Image image)
{
    import dgt.vg.backend.cairo : cairoBackend;

    return cairoBackend.makeContext(image);
}

/// Check whether img is compatible for vg
@property bool vgCompatible(const(Image) img)
{
    import dgt.gfx.image : ImageFormat;

    return img.format != ImageFormat.argb && img.stride % 4 == 0;
}

/// Returns img if compatible, otherwise a compatible image built from img.
Image makeVgCompatible(Image img, Flag!"allowInPlace" allowInPlace=No.allowInPlace)
in(img)
out(res; res.vgCompatible)
{
    import dgt.gfx.image : alignedStrideForWidth, apply, ImageFormat, premultiply;

    if (img.vgCompatible) return img;

    const fmt = img.format;
    const ifmt = fmt == ImageFormat.argb ? ImageFormat.argbPremult : fmt;
    const premult = fmt == ImageFormat.argb;
    const width = img.width;
    const stride = ifmt.alignedStrideForWidth(img.width);

    if (allowInPlace && premult && stride == img.stride) {
        img.apply!premultiply();
        return new Image(img.data, ImageFormat.argbPremult, width, stride);
    }

    return makeVgCompatiblePriv(img);
}
/// ditto
immutable(Image) makeVgCompatible(immutable(Image) img)
in(img)
out(res; res.vgCompatible)
{
    if (img.vgCompatible) return img;
    return makeVgCompatible(img);
}
/// ditto
const(Image) makeVgCompatible(const(Image) img)
in(img)
out(res; res.vgCompatible)
{
    if (img.vgCompatible) return img;
    return makeVgCompatible(img);
}

private ImgT makeVgCompatiblePriv(ImgT)(ImgT img)
if (is(Unqual!ImgT == Image))
{
    import dgt.gfx.image : alignedStrideForWidth, apply, ImageFormat, premultiply;

    const fmt = img.format;
    const ifmt = fmt == ImageFormat.argb ? ImageFormat.argbPremult : fmt;
    const premult = fmt == ImageFormat.argb;
    const width = img.width;
    const stride = ifmt.alignedStrideForWidth(img.width);

    ubyte[] data;

    if (stride == img.stride) {
        data = img.data.dup;
    }
    else {
        import std.algorithm : min;

        data = new ubyte[stride * img.height];
        const srcData = img.data;
        const srcStride = img.stride;
        const copyStride = min(stride, srcStride);
        foreach (l; 0 .. img.height)
        {
            data[l*stride .. l*stride+copyStride] =
                srcData[l*srcStride .. l*srcStride+copyStride];
        }
    }

    Image newImg = new Image(data, ifmt, width, stride);

    if (premult) {
        newImg.apply!premultiply();
    }

    static if (is(ImgT == immutable))
    {
        return assumeUnique(newImg);
    }
    else {
        return newImg;
    }
}
