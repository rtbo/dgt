/// Vector graphics - Command buffer module
module dgt.vg.cmdbuf;

import dgt.gfx.color : Color;
import dgt.gfx.geometry : FMargins, FRect, FPoint, IRect;
import dgt.gfx.image : Image, ImageFormat, RImage;
import dgt.gfx.paint : Paint, RPaint;
import dgt.vg.path : Path, RPath;
import dgt.vg.penbrush;
import gfx.math : FMat2x3, FVec2;

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

    ref CmdBufBuilder save() return
    {
        _cmds ~= Cmd(CmdType.save);
        return this;
    }

    ref CmdBufBuilder restore() return
    {
        _cmds ~= Cmd(CmdType.restore);
        return this;
    }

    ref CmdBufBuilder transform(in FMat2x3 transform) return
    {
        CmdData data = void;
        data.transform = transform;
        _cmds ~= Cmd(CmdType.transform, data);
        return this;
    }

    ref CmdBufBuilder mulTransform(in FMat2x3 transform) return
    {
        CmdData data = void;
        data.transform = transform;
        _cmds ~= Cmd(CmdType.mulTransform, data);
        return this;
    }

    ref CmdBufBuilder clip(immutable(Path) path) return
    {
        CmdData data = void;
        data.clipPath = path;
        _cmds ~= Cmd(CmdType.clip, data);
        return this;
    }

    ref CmdBufBuilder mask(immutable(Image) image, immutable(Paint) paint) return
    in (image && (image.format == ImageFormat.a1 || image.format == ImageFormat.a8))
    {
        CmdData data = void;
        data.mask.mask = image;
        data.mask.paint = paint;
        _cmds ~= Cmd(CmdType.mask, data);
        return this;
    }

    ref CmdBufBuilder drawImg(immutable(Image) image) return
    {
        CmdData data = void;
        data.drawImg = image;
        _cmds ~= Cmd(CmdType.drawImage, data);
        return this;
    }

    ref CmdBufBuilder stroke(immutable(Path) path, immutable(Pen) pen=null) return
    {
        CmdData data = void;
        data.stroke.path = path;
        data.stroke.pen = pen ? pen : defaultPen;
        _cmds ~= Cmd(CmdType.stroke, data);
        return this;
    }

    ref CmdBufBuilder fill(immutable(Path) path, immutable(Brush) brush=null) return
    {
        CmdData data = void;
        data.fill.path = path;
        data.fill.brush = brush ? brush : defaultBrush;
        _cmds ~= Cmd(CmdType.fill, data);
        return this;
    }

    ref CmdBufBuilder bounds(in FRect bounds) return
    {
        _bounds = bounds;
        _boundsSet = true;
        return this;
    }

    immutable(CmdBuf) done()
    {
        import std.exception : assumeUnique;

        if (_boundsSet) {
            return immutable CmdBuf( assumeUnique(_cmds), _bounds );
        }
        else {
            return immutable CmdBuf( assumeUnique(_cmds) );
        }
    }

    CmdBuf doneMut()
    {
        if (_boundsSet) {
            return CmdBuf( _cmds, _bounds );
        }
        else {
            return CmdBuf( _cmds );
        }
    }
}

struct AnchoredImage
{
    FVec2 orig;
    immutable(Image) image;
}

private IRect ceiledRect(in FRect rect)
{
    import std.math : ceil, floor;

    const l = cast(int)floor(rect.x);
    const t = cast(int)floor(rect.y);
    const r = cast(int)ceil(rect.right);
    const b = cast(int)ceil(rect.bottom);

    return IRect(l, t, r-l, b-t);
}

AnchoredImage execute(const(CmdBuf) cmdBuf)
{
    import dgt.gfx.image : alignedStrideForWidth, assumeUnique, ImageFormat;

    const bounds = cmdBuf.bounds;
    const imgBounds = ceiledRect(bounds);
    const orig = cast(FVec2)-imgBounds.topLeft;
    const fmt = ImageFormat.argbPremult;
    const stride = alignedStrideForWidth(fmt, imgBounds.width);
    auto data = new ubyte[stride * imgBounds.height];
    auto dest = new Image(data, fmt, imgBounds.width, stride);

    executeImpl(cmdBuf, dest, orig);

    return AnchoredImage(orig, assumeUnique(dest));
}

void execute(const(CmdBuf) cmdBuf, Image dest, in FVec2 orig)
{
    executeImpl(cmdBuf, dest, orig);
}

private bool fitsImage(const(CmdBuf) cmdBuf, Image dest, in FVec2 orig)
{
    const bounds = cmdBuf.bounds;
    const tl = orig + bounds.topLeft;
    const br = orig + bounds.bottomRight;
    const destSize = dest.size;

    return tl.x >= 0 &&  tl.y >= 0 && br.x < destSize.width && br.y < destSize.height;
}

private void executeImpl(const(CmdBuf) cmdBuf, Image dest, in FVec2 orig)
{
    import dgt.vg : makeVgContext;
    import gfx.math : affineMult, affineTranslation;

    assert(fitsImage(cmdBuf, dest, orig), "VG command buffer does not fit in image");

    auto ctx = makeVgContext(dest);
    scope(exit) ctx.dispose();

    const origMat = affineTranslation(orig);
    ctx.transform = origMat;
    int stackNb = 0;

    foreach (ref cmd; cmdBuf.cmds)
    {
        final switch (cmd.type) {
        case CmdType.save:
            ctx.save();
            stackNb++;
            break;
        case CmdType.restore:
            ctx.restore();
            stackNb--;
            break;
        case CmdType.transform:
            if (stackNb == 0) {
                ctx.transform = affineMult(origMat, cmd.data.transform);
            }
            else {
                ctx.transform = cmd.data.transform;
            }
            break;
        case CmdType.mulTransform:
            ctx.mulTransform(cmd.data.transform);
            break;
        case CmdType.clip:
            ctx.clip(cmd.data.clipPath);
            break;
        case CmdType.mask:
            ctx.mask(cmd.data.mask.mask, cmd.data.mask.paint);
            break;
        case CmdType.drawImage:
            ctx.drawImage(cmd.data.drawImg);
            break;
        case CmdType.stroke:
            ctx.stroke(cmd.data.stroke.path, cmd.data.stroke.pen);
            break;
        case CmdType.fill:
            ctx.fill(cmd.data.fill.path, cmd.data.fill.brush);
            break;
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
        import dgt.gfx.geometry : extend;

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
        import dgt.gfx.geometry : extend;

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
        import dgt.gfx.geometry : FSize, transformBounds;
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
                mat = cmd.data.transform;
                break;
            case CmdType.mulTransform:
                mat = affineMult(mat, cmd.data.transform);
                break;
            case CmdType.clip:
                break;
            case CmdType.mask:
                add( transformBounds(FRect(0f, 0f, cast(FSize)cmd.data.mask.mask.size), mat) );
                break;
            case CmdType.drawImage:
                add( transformBounds(FRect(0f, 0f, cast(FSize)cmd.data.drawImg.size), mat) );
                break;
            case CmdType.stroke:
                const margins = FMargins(cmd.data.stroke.pen.width / 2f);
                add( cmd.data.stroke.path.computeBounds(mat) + margins );
                break;
            case CmdType.fill:
                add( cmd.data.fill.path.computeBounds(mat) );
                break;
            }
        }
    }
}

private FRect computeBufBounds(const(Cmd)[] cmds)
{
    import dgt.gfx.geometry : extend;

    auto calc = BoundsCalc(cmds, 0);

    calc.frame(FMat2x3.identity);

    return calc.bounds;
}
