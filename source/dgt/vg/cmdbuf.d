/// Vector graphics - Command buffer module
module dgt.vg.cmdbuf;

import dgt.core.color : Color;
import dgt.core.geometry : FMargins, FRect, FPoint;
import dgt.core.image : Image, ImageFormat, RImage;
import dgt.core.paint : Paint, RPaint;
import dgt.vg.path : Path, RPath;
import dgt.vg.penbrush;
import gfx.math : FMat2x3;

struct CmdBuf
{
    private Cmd[] cmds;
    private FRect _bounds;
    private bool _boundsCached;

    this (Cmd[] cmds) {
        this.cmds = cmds;
        _boundsCached = false;
    }

    this (Cmd[] cmds, in FRect bounds) {
        this.cmds = cmds;
        _bounds = bounds;
        _boundsCached = true;
    }

    immutable this (immutable(Cmd)[] cmds) {
        this.cmds = cmds;
        _boundsCached = false;
    }

    immutable this (immutable(Cmd)[] cmds, in FRect bounds) {
        this.cmds = cmds;
        _bounds = bounds;
        _boundsCached = true;
    }

    @property bool boundsCached() const
    {
        return _boundsCached;
    }

    @property FRect bounds() const
    {
        if (_boundsCached) return _bounds;
        else return computeBufBounds(cmds);
    }

    @property FRect bounds()
    {
        if (!_boundsCached) {
            _bounds = computeBufBounds(cmds);
            _boundsCached = true;
        }
        return _bounds;
    }

    static CmdBufBuilder build()
    {
        return CmdBufBuilder.init;
    }
}

struct CmdBufBuilder
{
    private Cmd[] _cmds;
    private FRect _bounds;
    private bool _boundsSet;

    @disable this(this);

    CmdBufBuilder dup()
    {
        return CmdBufBuilder(_cmds.dup);
    }

    ref CmdBufBuilder save()
    {
        _cmds ~= Cmd(CmdType.save);
        return this;
    }

    ref CmdBufBuilder restore()
    {
        _cmds ~= Cmd(CmdType.restore);
        return this;
    }

    ref CmdBufBuilder transform(in FMat2x3 transform)
    {
        CmdData data = void;
        data.transform = transform;
        _cmds ~= Cmd(CmdType.transform, data);
        return this;
    }

    ref CmdBufBuilder mulTransform(in FMat2x3 transform)
    {
        CmdData data = void;
        data.transform = transform;
        _cmds ~= Cmd(CmdType.mulTransform, data);
        return this;
    }

    ref CmdBufBuilder clip(immutable(Path) path)
    {
        CmdData data = void;
        data.clipPath = path;
        _cmds ~= Cmd(CmdType.clip, data);
        return this;
    }

    ref CmdBufBuilder mask(immutable(Image) image, immutable(Paint) paint)
    in (image && (image.format == ImageFormat.a1 || image.format == ImageFormat.a8))
    {
        CmdData data = void;
        data.mask.mask = image;
        data.mask.paint = paint;
        _cmds ~= Cmd(CmdType.mask, data);
        return this;
    }

    ref CmdBufBuilder drawImg(immutable(Image) image)
    {
        CmdData data = void;
        data.drawImg = image;
        _cmds ~= Cmd(CmdType.drawImage, data);
        return this;
    }

    ref CmdBufBuilder stroke(immutable(Path) path, immutable(Pen) pen=null)
    {
        CmdData data = void;
        data.stroke.path = path;
        data.stroke.pen = pen ? pen : defaultPen;
        _cmds ~= Cmd(CmdType.stroke, data);
        return this;
    }

    ref CmdBufBuilder fill(immutable(Path) path, immutable(Brush) brush=null)
    {
        CmdData data = void;
        data.fill.path = path;
        data.fill.brush = brush ? brush : defaultBrush;
        _cmds ~= Cmd(CmdType.fill, data);
        return this;
    }

    ref CmdBufBuilder bounds(in FRect bounds)
    {
        _bounds = bounds;
        _boundsSet = true;
        return this;
    }

    immutable(CmdBuf) done()
    {
        import std.exception : assumeUnique;

        if (_boundsSet) {
            return immutable CmdBuf( assumeUnique(_cmds) );
        }
        else {
            return immutable CmdBuf( assumeUnique(_cmds), _bounds );
        }
    }

    CmdBuf doneMut()
    {
        if (_boundsSet) {
            return CmdBuf( _cmds );
        }
        else {
            return CmdBuf( _cmds, _bounds );
        }
    }
}

private struct Cmd
{
    CmdType type;
    CmdData data;
}

private enum CmdType
{
    save,
    restore,
    transform,
    mulTransform,
    clip,
    mask,
    drawImage,
    stroke,
    fill,
}

private union CmdData
{
    FMat2x3 transform;
    Color color;
    RPath clipPath;
    RImage drawImg;
    MaskData mask;
    StrokeData stroke;
    FillData fill;
}

private struct MaskData
{
    RImage mask;
    RPaint paint;
}

private struct StrokeData
{
    RPath path;
    RPen pen;
}

private struct FillData
{
    RPath path;
    RBrush brush;
}

private struct BoundsCalc
{
    const(Cmd)[] cmds;
    size_t cmdCursor;
    FRect bounds = void;
    bool set;

    void add(FPoint point)
    {
        import dgt.core.geometry : extend;

        if (set) {
            bounds.extend(point);
        }
        else {
            bounds = FRect(point, 0f, 0f);
            set = true;
        }
    }

    void add(FRect rect)
    {
        import dgt.core.geometry : extend;

        if (set) {
            bounds.extend(rect);
        }
        else {
            bounds = rect;
            set = true;
        }
    }

    void frame(FMat2x3 mat)
    {
        import dgt.core.geometry : FSize;
        import gfx.math : affineMult;

        while (cmdCursor < cmds.length) {
            const cmd = cmds[cmdCursor++];
            final switch (cmd.type)
            {
            case CmdType.save:
                frame(mat);
                break;
            case CmdType.restore:
                return;
            case CmdType.transform:
                frame(cmd.data.transform);
                break;
            case CmdType.mulTransform:
                frame(affineMult(mat, cmd.data.transform));
                break;
            case CmdType.clip:
                break;
            case CmdType.mask:
                add( FRect(0f, 0f, cast(FSize)cmd.data.mask.mask.size) );
                break;
            case CmdType.drawImage:
                add( FRect(0f, 0f, cast(FSize)cmd.data.drawImg.size) );
                break;
            case CmdType.stroke:
                const margins = FMargins(cmd.data.stroke.pen.width / 2f);
                add( cmd.data.stroke.path.bounds + margins );
                break;
            case CmdType.fill:
                add( cmd.data.fill.path.bounds );
                break;
            }
        }
    }
}

private FRect computeBufBounds(const(Cmd)[] cmds)
{
    import dgt.core.geometry : extend;

    auto calc = BoundsCalc(cmds, 0);

    calc.frame(FMat2x3.identity);

    return calc.bounds;
}
