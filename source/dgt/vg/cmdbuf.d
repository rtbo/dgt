/// Vector graphics - Command buffer module
module dgt.vg.cmdbuf;

import dgt.core.color : Color;
import dgt.core.image : Image, ImageFormat, RImage;
import dgt.vg.path : Path, RPath;
import dgt.vg.penbrush;
import gfx.math : FMat2x3;

struct VgCmd
{
    enum Type {
        save,
        restore,

        pen,
        brush,
        transform,

        clear,
        clip,
        mask,
        drawImg,
        stroke,
        fill,
    }

    union Data {
        RPen pen;
        RBrush brush;
        FMat2x3 transform;
        Color color;
        RImage image;
        RPath path;
    }

    Type type;
    Data data;
}

immutable struct VgCmdBuf
{
    immutable(VgCmd[]) cmds;

    static VgCmdBufBuilder build()
    {
        return VgCmdBufBuilder.init;
    }
}

struct VgCmdBufBuilder
{
    private VgCmd[] _cmds;

    @disable this(this);

    VgCmdBufBuilder dup()
    {
        return VgCmdBufBuilder(_cmds.dup);
    }

    ref VgCmdBufBuilder save()
    {
        _cmds ~= VgCmd(VgCmd.Type.save);
        return this;
    }

    ref VgCmdBufBuilder restore()
    {
        _cmds ~= VgCmd(VgCmd.Type.restore);
        return this;
    }

    ref VgCmdBufBuilder pen(immutable Pen pen)
    {
        VgCmd.Data data = void;
        data.pen = pen;
        _cmds ~= VgCmd(VgCmd.Type.pen, data);
        return this;
    }

    ref VgCmdBufBuilder brush(immutable Brush brush)
    {
        VgCmd.Data data = void;
        data.brush = brush;
        _cmds ~= VgCmd(VgCmd.Type.brush, data);
        return this;
    }

    ref VgCmdBufBuilder transform(const ref FMat2x3 transform)
    {
        VgCmd.Data data = void;
        data.transform = transform;
        _cmds ~= VgCmd(VgCmd.Type.transform, data);
        return this;
    }

    ref VgCmdBufBuilder clear(const ref Color color)
    {
        VgCmd.Data data = void;
        data.color = color;
        _cmds ~= VgCmd(VgCmd.Type.clear, data);
        return this;
    }

    ref VgCmdBufBuilder clip(immutable(Path) path)
    {
        VgCmd.Data data = void;
        data.path = path;
        _cmds ~= VgCmd(VgCmd.Type.clip, data);
        return this;
    }

    ref VgCmdBufBuilder mask(immutable(Image) image)
    in (image && (image.format == ImageFormat.a1 || image.format == ImageFormat.a8))
    {
        VgCmd.Data data = void;
        data.image = image;
        _cmds ~= VgCmd(VgCmd.Type.mask, data);
        return this;
    }

    ref VgCmdBufBuilder drawImg(immutable(Image) image)
    {
        VgCmd.Data data = void;
        data.image = image;
        _cmds ~= VgCmd(VgCmd.Type.drawImg, data);
        return this;
    }

    ref VgCmdBufBuilder stroke(immutable(Path) path)
    {
        VgCmd.Data data = void;
        data.path = path;
        _cmds ~= VgCmd(VgCmd.Type.stroke, data);
        return this;
    }

    ref VgCmdBufBuilder fill(immutable(Path) path)
    {
        VgCmd.Data data = void;
        data.path = path;
        _cmds ~= VgCmd(VgCmd.Type.fill, data);
        return this;
    }

    VgCmdBuf done()
    {
        import std.exception : assumeUnique;

        return VgCmdBuf(assumeUnique(_cmds));
    }
}
