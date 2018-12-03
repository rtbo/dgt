/// Vector graphics module
module dgt.vg;

public import dgt.vg.cmdbuf;
public import dgt.vg.context;
public import dgt.vg.path;
public import dgt.vg.penbrush;

import dgt.core.image : Image;

interface VgBackend
{
    string name();

    VgContext makeContext(Image image);
}


VgContext makeVgContext(Image image)
{
    import dgt.vg.backend.cairo : cairoBackend;

    return cairoBackend.makeContext(image);
}

/// Check wether img is compatible for vg
@property bool vgCompatible(const(Image) img)
{
    import dgt.core.image : ImageFormat;

    return img.format != ImageFormat.argb && img.stride % 4 == 0;
}

/// Returns img if compatible, otherwise a compatible image built from img.
Image makeVgCompatible(Image img)
in(img)
out(res; res.vgCompatible)
{
    import dgt.core.image : alignedStrideForWidth, apply, ImageFormat, premultiply;

    if (img.vgCompatible) return img;

    auto ifmt = img.format;
    bool premult = false;
    if (ifmt == ImageFormat.argb)
    {
        ifmt = ImageFormat.argbPremult;
        premult = true;
    }

    immutable stride = ifmt.alignedStrideForWidth(img.width);
    ubyte[] data;
    if (stride == img.stride)
    {
        data = img.data.dup;
    }
    else
    {
        import std.algorithm : min;
        data = new ubyte[stride * img.height];
        const srcData = img.data;
        immutable srcStride = img.stride;
        immutable copyStride = min(stride, srcStride);
        foreach (l; 0 .. img.height)
        {
            data[l*stride .. l*stride+copyStride] =
                srcData[l*srcStride .. l*srcStride+copyStride];
        }
    }
    auto newImg = new Image(data, ifmt, img.width, stride);
    if (premult)
    {
        newImg.apply!premultiply();
    }
    return newImg;
}
