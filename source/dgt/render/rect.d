/// Rect rendering module.
/// implements hardware rendering of rect, possibly with rounded corners,
/// with border, and paint (solid, linear gradient)
module dgt.render.rect;

import dgt.core.geometry;
import dgt.core.rc;
import dgt.core.paint;
import dgt.math;
import dgt.render.defs;
import dgt.render.framegraph;
import dgt.render.renderer;
import gfx.pipeline;

import std.experimental.logger;

class RectRenderer : Disposable
{
    this() {
        mvpBlk = new ConstBuffer!MVP(1);
        sharpIndBuf = new IndexBuffer!ushort(sharpIndices);
        roundedIndBuf = new IndexBuffer!ushort(roundedIndices);

        colPipe = new ColPipe(
            new Program(ShaderSet.vertexPixel(
                import("rect_col_vx.glsl"), import("rect_col_px.glsl")
            )),
            Primitive.triangles, Rasterizer.fill.withSamples()
        );
        imgPipe = new ImgPipe(
            new Program(ShaderSet.vertexPixel(
                import("rect_img_vx.glsl"), import("rect_img_px.glsl")
            )),
            Primitive.triangles, Rasterizer.fill.withSamples()
        );
    }

    override void dispose() {
        mvpBlk.unload();
        sharpIndBuf.unload();
        roundedIndBuf.unload();
        colPipe.unload();
        imgPipe.unload();
    }


    void render(immutable(FGRectNode) node, RenderContext ctx,
                in FMat4 model, CommandBuffer cmdBuf)
    {
        if (!node.paint) {
            renderCol(node, ctx, model, cmdBuf);
            return;
        }
        switch (node.paint.type) {
        case PaintType.color:
        case PaintType.linearGradient:
            renderCol(node, ctx, model, cmdBuf);
            break;
        case PaintType.image:
            renderImg(node, ctx, model, cmdBuf);
            break;
        default:
            warningf("RectRenderer: unsupported paint type: %s", node.paint.type);
            break;
        }
    }

    private void renderCol(immutable(FGRectNode) node, RenderContext ctx,
                   in FMat4 model, CommandBuffer cmdBuf)
    {
        auto encoder = Encoder(cmdBuf);

        auto verts = buildVertices!ColVertex(node);
        setGPos(verts, node);
        auto vbuf = makeRc!(VertexBuffer!ColVertex)(verts);

        auto csBlk = makeRc!(ConstBuffer!ColorStop)(8);
        auto fsBlk = makeRc!(ConstBuffer!FillStroke)(1);

        import std.algorithm : each, map, min;
        import std.array : array;
        import std.range : take;

        FillStroke fs;
        node.border.each!((RectBorder b) {
            fs.stroke = b.color;
            fs.strokeWidth = b.width;
        });

        if (!node.paint) {
            fs.numStops = 1;
            encoder.updateConstBuffer(csBlk, [ColorStop(fvec(0, 0, 0, 0), 0f)]);
        }
        else {
            switch (node.paint.type) {
            case PaintType.color:
                immutable cp = cast(immutable(ColorPaint))node.paint;
                fs.numStops = 1;
                encoder.updateConstBuffer(csBlk, [ColorStop(cp.color.asVec, 0f)]);
                break;
            case PaintType.linearGradient:
                enum maxStops = 8;
                immutable lgp = cast(immutable(LinearGradientPaint))node.paint;
                fs.numStops = min(lgp.stops.length, maxStops);
                const stops = lgp.stops
                            .take(maxStops)
                            .map!(s => ColorStop(s.color.asVec, s.position))
                            .array;
                encoder.updateConstBuffer(csBlk, stops);
                break;
            default:
                assert(false);
            }
        }

        encoder.updateConstBuffer(fsBlk, fs);
        encoder.updateConstBuffer(mvpBlk, MVP(transpose(model), transpose(ctx.viewProj)));

        auto ibuf = node.radius > 0 ? roundedIndBuf : sharpIndBuf;

        encoder.draw!ColPipeMeta(VertexBufferSlice(ibuf), colPipe, ColPipe.Data(
            vbuf, mvpBlk, fsBlk, csBlk, ctx.renderTarget.rc
        ));
    }

    private void renderImg(immutable(FGRectNode) node, RenderContext ctx,
                   in FMat4 model, CommandBuffer cmdBuf)
    {
        auto encoder = Encoder(cmdBuf);

        auto verts = buildVertices!ImgVertex(node);
        setTexCoords(verts, node);
        auto vbuf = makeRc!(VertexBuffer!ImgVertex)(verts);

        import gfx.foundation.util : retypeSlice;
        import std.algorithm : each;

        Stroke s;
        node.border.each!((RectBorder b) {
            s.stroke = b.color;
            s.strokeWidth = b.width;
        });
        auto sBlk = makeRc!(ConstBuffer!Stroke)(1);
        encoder.updateConstBuffer(sBlk, s);

        immutable ip = cast(immutable(ImagePaint))node.paint;
        assert(ip);
        immutable img = ip.image;

        auto pixels = retypeSlice!(const(ubyte[4]))(img.data);
        TexUsageFlags usage = TextureUsage.shaderResource;
        auto tex = makeRc!(Texture2D!Rgba8)(
            usage, ubyte(1), cast(ushort)img.width, cast(ushort)img.height, [pixels]
        );
        auto srv = tex.viewAsShaderResource(0, 0, newSwizzle()).rc;
        auto sampler = makeRc!Sampler(
            srv, SamplerInfo(FilterMethod.anisotropic, WrapMode.init)
        );

        encoder.updateConstBuffer(mvpBlk, MVP(transpose(model), transpose(ctx.viewProj)));

        auto ibuf = node.radius > 0 ? roundedIndBuf : sharpIndBuf;

        encoder.draw!ImgPipeMeta(VertexBufferSlice(ibuf), imgPipe, ImgPipe.Data(
            vbuf, mvpBlk, sBlk, srv, sampler, ctx.renderTarget.rc
        ));
    }

    private @property ushort[] roundedIndices() {
        ushort[] inds;
        inds.reserve(6*4 + 12*4);
        inds ~= [0, 1, 2, 0, 2, 3];
        inds ~= [4, 5, 6, 4, 6, 7];
        inds ~= [8, 9, 10, 8, 10, 11];
        inds ~= [12, 13, 14, 12, 14, 15];
        void addIndices(in ushort start) {
            inds ~= [
                cast(ushort)(start+0), cast(ushort)(start+1), cast(ushort)(start+4),
                cast(ushort)(start+0), cast(ushort)(start+4), cast(ushort)(start+2),
                cast(ushort)(start+4), cast(ushort)(start+1), cast(ushort)(start+5),
                cast(ushort)(start+5), cast(ushort)(start+1), cast(ushort)(start+3),
            ];
        }
        addIndices(16);
        addIndices(22);
        addIndices(28);
        addIndices(34);
        return inds;
    }

    private @property ushort[] sharpIndices() {
        return [
            0, 1, 2, 2, 1, 3,
            4, 5, 6, 6, 5, 7,
            8, 9, 10, 10, 9, 11,
            12, 13, 14, 14, 13, 15,
        ];
    }

    private V[] buildVertices(V)(immutable(FGRectNode) node)
    {
        import std.algorithm : min;

        const r = node.rect;
        const radius = node.radius;
        const hm = min(r.width, r.height) / 2; // half min
        const hw = node.border.isSome ? node.border.get.width : 0;

        // inner rect
        const ir = r - FPadding(hm);
        // extent rect
        const er = r + FMargins(hw);

        V[] verts;

        if (radius > 0) {
            verts.reserve(40);

            immutable rd = min(hm, radius);
            if (rd != radius) {
                warning("specified radius for rect is too big");
            }

            // top left corner
            immutable tlEdge = fvec(r.left+rd, r.top+rd, rd);
            verts ~= V(fvec(er.left, er.top), tlEdge);     // 0
            verts ~= V(fvec(r.left+rd, er.top), tlEdge);     // 1
            verts ~= V(fvec(r.left+rd, r.top+rd), tlEdge);     // 2
            verts ~= V(fvec(er.left, r.top+rd), tlEdge);     // 3
            // top right corner
            immutable trEdge = fvec(r.right-rd, r.top+rd, rd);
            verts ~= V(fvec(r.right-rd, er.top), trEdge);    // 4
            verts ~= V(fvec(er.right, er.top), trEdge);    // 5
            verts ~= V(fvec(er.right, r.top+rd), trEdge);    // 6
            verts ~= V(fvec(r.right-rd, r.top+rd), trEdge);    // 7
            // bottom right corner
            immutable brEdge = fvec(r.right-rd, r.bottom-rd, rd);
            verts ~= V(fvec(r.right-rd, r.bottom-rd), brEdge); // 8
            verts ~= V(fvec(er.right, r.bottom-rd), brEdge); // 9
            verts ~= V(fvec(er.right, er.bottom), brEdge); // 10
            verts ~= V(fvec(r.right-rd, er.bottom), brEdge); // 11
            // bottom left corner
            immutable blEdge = fvec(r.left+rd, r.bottom-rd, rd);
            verts ~= V(fvec(er.left, r.bottom-rd), blEdge);  // 12
            verts ~= V(fvec(r.left+rd, r.bottom-rd), blEdge);  // 13
            verts ~= V(fvec(r.left+rd, er.bottom), blEdge);  // 14
            verts ~= V(fvec(er.left, er.bottom), blEdge);  // 15

            // sides
            verts ~= [
                // top
                V(fvec(r.left+rd, er.top), fvec(r.left+rd, ir.top, hm)),           // 16
                V(fvec(r.right-rd, er.top), fvec(r.right-rd, ir.top, hm)),
                V(fvec(r.left+rd, r.top+rd), fvec(r.left+rd, ir.top, hm)),
                V(fvec(r.right-rd, r.top+rd), fvec(r.right-rd, ir.top, hm)),
                V(ir.topLeft, fvec(ir.topLeft, hm)),
                V(ir.topRight, fvec(ir.topRight, hm)),
                // right
                V(fvec(er.right, r.top+rd), fvec(ir.right, r.top+rd, hm)),         // 22
                V(fvec(er.right, r.bottom-rd), fvec(ir.right, r.bottom-rd, hm)),
                V(fvec(r.right-rd, r.top+rd), fvec(ir.right, r.top+rd, hm)),
                V(fvec(r.right-rd, r.bottom-rd), fvec(ir.right, r.bottom-rd, hm)),
                V(ir.topRight, fvec(ir.topRight, hm)),
                V(ir.bottomRight, fvec(ir.bottomRight, hm)),
                // bottom
                V(fvec(r.right-rd, er.bottom), fvec(r.right-rd, ir.bottom, hm)),   // 28
                V(fvec(r.left+rd, er.bottom), fvec(r.left+rd, ir.bottom, hm)),
                V(fvec(r.right-rd, r.bottom-rd), fvec(r.right-rd, ir.bottom, hm)),
                V(fvec(r.left+rd, r.bottom-rd), fvec(r.left+rd, ir.bottom, hm)),
                V(ir.bottomRight, fvec(ir.bottomRight, hm)),
                V(ir.bottomLeft, fvec(ir.bottomLeft, hm)),
                // left
                V(fvec(er.left, r.bottom-rd), fvec(ir.left, r.bottom-rd, hm)),         // 34
                V(fvec(er.left, r.top+rd), fvec(ir.left, r.top+rd, hm)),
                V(fvec(r.left+rd, r.bottom-rd), fvec(ir.left, r.bottom-rd, hm)),
                V(fvec(r.left+rd, r.top+rd), fvec(ir.left, r.top+rd, hm)),
                V(ir.bottomLeft, fvec(ir.bottomLeft, hm)),
                V(ir.topLeft, fvec(ir.topLeft, hm)),
            ];

        }
        else {
            verts = [
                // top side
                V(er.topLeft, fvec(er.left, ir.top, hm)),
                V(er.topRight, fvec(er.right, ir.top, hm)),
                V(ir.topLeft, fvec(ir.topLeft, hm)),
                V(ir.topRight, fvec(ir.topRight, hm)),
                // right side
                V(er.topRight, fvec(ir.right, er.top, hm)),
                V(er.bottomRight, fvec(ir.right, er.bottom, hm)),
                V(ir.topRight, fvec(ir.topRight, hm)),
                V(ir.bottomRight, fvec(ir.bottomRight, hm)),
                // bottom side
                V(er.bottomRight, fvec(er.right, ir.bottom, hm)),
                V(er.bottomLeft, fvec(er.left, ir.bottom, hm)),
                V(ir.bottomRight, fvec(ir.bottomRight, hm)),
                V(ir.bottomLeft, fvec(ir.bottomLeft, hm)),
                // left side
                V(er.bottomLeft, fvec(ir.left, er.bottom, hm)),
                V(er.topLeft, fvec(ir.left, er.top, hm)),
                V(ir.bottomLeft, fvec(ir.bottomLeft, hm)),
                V(ir.topLeft, fvec(ir.topLeft, hm)),
            ];
        }

        return verts;
    }

    // set the gradient pos of the vertices
    private void setGPos(ColVertex[] verts, immutable(FGRectNode) node)
    {
        immutable lgp = cast(immutable(LinearGradientPaint))node.paint;
        if (!lgp) return; // setGPos is also called for solid color rects

        import std.algorithm : max;
        import std.math : cos, sin;

        // angle zero is defined to top (-Y)
        // angle 90deg is defined to right (+X)
        const r = node.rect;
        const angle = lgp.computeAngle(r.size);
        const c = r.center;
        const ca = cos(angle);
        const sa = sin(angle);

        // unit vec along gradient line
        immutable u = fvec(sa, -ca);

        // signed distance from center along the gradient line
        float orthoProjDist(in FVec2 p) {
            return dot(p-c, u);
        }

        const tl = orthoProjDist(r.topLeft);
        const tr = orthoProjDist(r.topRight);
        const br = orthoProjDist(r.bottomRight);
        const bl = orthoProjDist(r.bottomLeft);
        const fact = 0.5 / max(tl, tr, br, bl);

        foreach (ref v; verts) {
            v.gpos = fact * orthoProjDist(v.vpos) + 0.5f;
        }
    }

    private void setTexCoords(ImgVertex[] verts, immutable(FGRectNode) node) {
        immutable ip = cast(immutable(ImagePaint))node.paint;
        assert(ip);
        immutable img = ip.image;

        const factor = fvec(1f / cast(float)img.width, 1f / cast(float)img.height);
        foreach (ref v; verts) {
            v.vtex = factor * v.vpos;
        }
    }




    private Rc!(ConstBuffer!MVP) mvpBlk;
    private Rc!(IndexBuffer!ushort) roundedIndBuf;
    private Rc!(IndexBuffer!ushort) sharpIndBuf;
    private Rc!ColPipe colPipe;
    private Rc!ImgPipe imgPipe;

}

private:

// cached data set

class ColDataSet : Disposable
{
    Rc!(VertexBuffer!ColVertex) vbuf;
    Rc!(ConstBuffer!FillStroke) fsBlk;
    Rc!(ConstBuffer!ColorStop)  csBlk;

    override void dispose() {
        vbuf.unload();
        fsBlk.unload();
        csBlk.unload();
    }
}

class ImgDataSet : Disposable
{
    Rc!(VertexBuffer!ImgVertex)     vbuf;
    Rc!(ConstBuffer!Stroke)         sBlk;
    Rc!(ShaderResourceView!Rgba8)   srv;
    Rc!Sampler                      sampler;

    override void dispose() {
        vbuf.unload();
        sBlk.unload();
        srv.unload();
        sampler.unload();
    }
}


struct ColVertex
{
    @GfxName("a_Pos")
    float[3] pos;   // z is color gradient position

    @GfxName("a_Edge")
    float[3] edge;

    this(in FVec2 pos, in FVec3 edge) {
        this.pos = [pos.x, pos.y, 0f];
        this.edge = edge.array;
    }

    @property FVec2 vpos() const {
        return FVec2(pos[0 .. 2]);
    }
    @property float gpos() {
        return pos[2];
    }
    @property void gpos(in float gpos) {
        pos[2] = gpos;
    }
}

struct FillStroke
{
    FVec4 stroke;
    float strokeWidth;
    int numStops;
}

struct ColorStop
{
    FVec4 color;
    float position;
    float[3] pad;

    this(in FVec4 color, in float position) {
        this.color = color;
        this.position = position;
    }
}

struct ColPipeMeta
{
    VertexInput!ColVertex      input;

    @GfxName("MVP")
    ConstantBlock!MVP           mvp;

    @GfxName("FillStroke")
    ConstantBlock!FillStroke    fs;

    @GfxName("ColorStops")
    ConstantBlock!ColorStop     cs;

    @GfxName("o_Color")
    @GfxBlend(Blend( Equation.add, Factor.one, Factor.oneMinusSrcAlpha ))
    BlendOutput!Rgba8           outColor;
}

alias ColPipe = PipelineState!ColPipeMeta;
alias ColData = ColPipe.Data;


struct ImgVertex
{
    @GfxName("a_Pos")
    float[2] pos;

    @GfxName("a_Tex")
    float[2] tex;

    @GfxName("a_Edge")
    float[3] edge;

    this(in FVec2 pos, in FVec3 edge)
    {
        this.pos = pos.array;
        this.edge = edge.array;
    }
    this(in FVec2 pos, in FVec2 tex, in FVec3 edge)
    {
        this.pos = pos.array;
        this.tex = tex.array;
        this.edge = edge.array;
    }

    @property FVec2 vpos() const {
        return FVec2(pos);
    }
    @property void vtex(in FVec2 tex) {
        this.tex = tex.array;
    }
}

struct Stroke
{
    FVec4 stroke;
    float strokeWidth;
}

struct ImgPipeMeta
{
    VertexInput!ImgVertex      input;

    @GfxName("MVP")
    ConstantBlock!MVP           mvp;

    @GfxName("Stroke")
    ConstantBlock!Stroke        s;

    @GfxName("u_Sampler")
    ResourceView!Rgba8          texture;

    @GfxName("u_Sampler")
    ResourceSampler             sampler;

    @GfxName("o_Color")
    @GfxBlend(Blend( Equation.add, Factor.one, Factor.oneMinusSrcAlpha ))
    BlendOutput!Rgba8           outColor;
}

alias ImgPipe = PipelineState!ImgPipeMeta;
alias ImgData = ImgPipe.Data;
