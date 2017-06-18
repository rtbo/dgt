module dgt.sg.rect;

import dgt.color;
import dgt.geometry;
import dgt.math;
import dgt.paint;
import dgt.sg.context;
import dgt.sg.defs;
import dgt.sg.geometry;
import dgt.sg.node;

import gfx.foundation.rc;
import gfx.pipeline;

import std.experimental.logger;

alias Color = dgt.color.Color;

// this is the approach I use for a rounded rectangle:
// https://mortoray.com/2015/06/05/quickly-drawing-a-rounded-rectangle-with-a-gl-shader/
// rounded version still needs blending in order to have anti aliased corners

enum maxNumStops = 8;

/// Rounded rectangle node
class SGRectNode : SGDrawNode
{
    this() {}

    @property FRect rect()
    {
        return _rect;
    }
    @property void rect(in FRect rect)
    {
        if (rect != _rect) {
            _rect = rect;
            _dirty |= Dirty.buf;
        }
    }

    @property float radius()
    {
        return _radius;
    }
    @property void radius(in float radius)
    {
        if (radius != _radius) {
            _radius = radius;
            _dirty |= Dirty.buf;
        }
    }

    @property Paint fillPaint()
    {
        return _fillPaint;
    }
    @property void fillPaint(Paint paint)
    {
        if (paint !is _fillPaint) {
            bool dirtyBuf = true;
            if (paint && _fillPaint && paint.type == PaintType.linearGradient &&
                    _fillPaint.type == PaintType.linearGradient)
            {
                auto lgp = cast(LinearGradientPaint)paint;
                auto _lgp = cast(LinearGradientPaint)_fillPaint;
                dirtyBuf = (lgp.computeAngle(rect.size) != _lgp.computeAngle(rect.size));
            }
            _fillPaint = paint;
            _dirty |= Dirty.col;
            if (dirtyBuf) _dirty |= Dirty.buf;
        }
    }

    @property Color strokeColor()
    {
        return _strokeColor;
    }
    @property void strokeColor(in Color strokeCol)
    {
        if (_strokeColor != strokeCol) {
            _strokeColor = strokeCol;
            _dirty |= Dirty.col;
        }
    }

    @property float strokeWidth()
    {
        return _strokeWidth;
    }
    @property void strokeWidth(in float width)
    {
        if (_strokeWidth != width) {
            _strokeWidth = width;
            _dirty |= Dirty.buf;
            _dirty |= Dirty.col;
        }
    }

    override void draw (CommandBuffer cmdBuf, SGContext context, in FMat4 modelMat)
    {
        if (_dirty & Dirty.buf) {
            _vbuf.unload();
            _ibuf.unload();
            _dirty &= ~Dirty.buf;
        }

        if (_rect.area <= 0) return;

        if (!_vbuf) {
            import std.algorithm : min;

            immutable r = rect;
            immutable hm = min(r.width, r.height) / 2; // half min
            immutable hw = _strokeWidth / 2;

            // inner rect
            immutable ir = r - FPadding(hm);
            // extent rect
            immutable er = r + FMargins(hw);

            RectVertex[] verts;
            ushort[] inds;

            if (radius > 0) {
                immutable rd = min(hm, radius);
                if (rd != radius) {
                    warning("specified radius for rect is too big");
                }
                verts.reserve(40);
                inds.reserve(6*4 + 12*4);

                // top left corner
                immutable tlEdge = fvec(r.left+rd, r.top+rd, rd);
                verts ~= RectVertex(fvec(er.left, er.top), tlEdge);     // 0
                verts ~= RectVertex(fvec(r.left+rd, er.top), tlEdge);     // 1
                verts ~= RectVertex(fvec(r.left+rd, r.top+rd), tlEdge);     // 2
                verts ~= RectVertex(fvec(er.left, r.top+rd), tlEdge);     // 3
                inds ~= [0, 1, 2, 0, 2, 3];
                // top right corner
                immutable trEdge = fvec(r.right-rd, r.top+rd, rd);
                verts ~= RectVertex(fvec(r.right-rd, er.top), trEdge);    // 4
                verts ~= RectVertex(fvec(er.right, er.top), trEdge);    // 5
                verts ~= RectVertex(fvec(er.right, r.top+rd), trEdge);    // 6
                verts ~= RectVertex(fvec(r.right-rd, r.top+rd), trEdge);    // 7
                inds ~= [4, 5, 6, 4, 6, 7];
                // bottom right corner
                immutable brEdge = fvec(r.right-rd, r.bottom-rd, rd);
                verts ~= RectVertex(fvec(r.right-rd, r.bottom-rd), brEdge); // 8
                verts ~= RectVertex(fvec(er.right, r.bottom-rd), brEdge); // 9
                verts ~= RectVertex(fvec(er.right, er.bottom), brEdge); // 10
                verts ~= RectVertex(fvec(r.right-rd, er.bottom), brEdge); // 11
                inds ~= [8, 9, 10, 8, 10, 11];
                // bottom left corner
                immutable blEdge = fvec(r.left+rd, r.bottom-rd, rd);
                verts ~= RectVertex(fvec(er.left, r.bottom-rd), blEdge);  // 12
                verts ~= RectVertex(fvec(r.left+rd, r.bottom-rd), blEdge);  // 13
                verts ~= RectVertex(fvec(r.left+rd, er.bottom), blEdge);  // 14
                verts ~= RectVertex(fvec(er.left, er.bottom), blEdge);  // 15
                inds ~= [12, 13, 14, 12, 14, 15];

                // sides
                verts ~= [
                    // top
                    RectVertex(fvec(r.left+rd, er.top), fvec(r.left+rd, ir.top, hm)),           // 16
                    RectVertex(fvec(r.right-rd, er.top), fvec(r.right-rd, ir.top, hm)),
                    RectVertex(fvec(r.left+rd, r.top+rd), fvec(r.left+rd, ir.top, hm)),
                    RectVertex(fvec(r.right-rd, r.top+rd), fvec(r.right-rd, ir.top, hm)),
                    RectVertex(ir.topLeft, fvec(ir.topLeft, hm)),
                    RectVertex(ir.topRight, fvec(ir.topRight, hm)),
                    // right
                    RectVertex(fvec(er.right, r.top+rd), fvec(ir.right, r.top+rd, hm)),         // 22
                    RectVertex(fvec(er.right, r.bottom-rd), fvec(ir.right, r.bottom-rd, hm)),
                    RectVertex(fvec(r.right-rd, r.top+rd), fvec(ir.right, r.top+rd, hm)),
                    RectVertex(fvec(r.right-rd, r.bottom-rd), fvec(ir.right, r.bottom-rd, hm)),
                    RectVertex(ir.topRight, fvec(ir.topRight, hm)),
                    RectVertex(ir.bottomRight, fvec(ir.bottomRight, hm)),
                    // bottom
                    RectVertex(fvec(r.right-rd, er.bottom), fvec(r.right-rd, ir.bottom, hm)),   // 28
                    RectVertex(fvec(r.left+rd, er.bottom), fvec(r.left+rd, ir.bottom, hm)),
                    RectVertex(fvec(r.right-rd, r.bottom-rd), fvec(r.right-rd, ir.bottom, hm)),
                    RectVertex(fvec(r.left+rd, r.bottom-rd), fvec(r.left+rd, ir.bottom, hm)),
                    RectVertex(ir.bottomRight, fvec(ir.bottomRight, hm)),
                    RectVertex(ir.bottomLeft, fvec(ir.bottomLeft, hm)),
                    // left
                    RectVertex(fvec(er.left, r.bottom-rd), fvec(ir.left, r.bottom-rd, hm)),         // 34
                    RectVertex(fvec(er.left, r.top+rd), fvec(ir.left, r.top+rd, hm)),
                    RectVertex(fvec(r.left+rd, r.bottom-rd), fvec(ir.left, r.bottom-rd, hm)),
                    RectVertex(fvec(r.left+rd, r.top+rd), fvec(ir.left, r.top+rd, hm)),
                    RectVertex(ir.bottomLeft, fvec(ir.bottomLeft, hm)),
                    RectVertex(ir.topLeft, fvec(ir.topLeft, hm)),
                ];

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
            }
            else {

                verts.reserve(16);
                inds.reserve(8*3);

                verts ~= [
                    // top side
                    RectVertex(er.topLeft, fvec(er.left, ir.top, hm)),
                    RectVertex(er.topRight, fvec(er.right, ir.top, hm)),
                    RectVertex(ir.topLeft, fvec(ir.topLeft, hm)),
                    RectVertex(ir.topRight, fvec(ir.topRight, hm)),
                    // right side
                    RectVertex(er.topRight, fvec(ir.right, er.top, hm)),
                    RectVertex(er.bottomRight, fvec(ir.right, er.bottom, hm)),
                    RectVertex(ir.topRight, fvec(ir.topRight, hm)),
                    RectVertex(ir.bottomRight, fvec(ir.bottomRight, hm)),
                    // bottom side
                    RectVertex(er.bottomRight, fvec(er.right, ir.bottom, hm)),
                    RectVertex(er.bottomLeft, fvec(er.left, ir.bottom, hm)),
                    RectVertex(ir.bottomRight, fvec(ir.bottomRight, hm)),
                    RectVertex(ir.bottomLeft, fvec(ir.bottomLeft, hm)),
                    // left side
                    RectVertex(er.bottomLeft, fvec(ir.left, er.bottom, hm)),
                    RectVertex(er.topLeft, fvec(ir.left, er.top, hm)),
                    RectVertex(ir.bottomLeft, fvec(ir.bottomLeft, hm)),
                    RectVertex(ir.topLeft, fvec(ir.topLeft, hm)),
                ];

                inds = [
                    0, 1, 2, 2, 1, 3,
                    4, 5, 6, 6, 5, 7,
                    8, 9, 10, 10, 9, 11,
                    12, 13, 14, 14, 13, 15,
                ];
            }

            setGPos(verts);

            _vbuf = new VertexBuffer!RectVertex(verts);
            _ibuf = new IndexBuffer!ushort(inds);
        }

        if (!_pipe) {
            _mvpBlk = new ConstBuffer!MVP;
            _fsBlk = new ConstBuffer!FillStroke;
            _csBlk = new ConstBuffer!ColorStop(maxNumStops);
            _pipe = new RectPipe (
                new Program(ShaderSet.vertexPixel(
                    import("rect_vx.glsl"), import("rect_px.glsl")
                )),
                Primitive.triangles, Rasterizer.fill.withSamples()
            );
        }

        auto encoder = Encoder(cmdBuf);

        encoder.updateConstBuffer(_mvpBlk, MVP(transpose(modelMat), transpose(context.viewProj)));

        if (_dirty & Dirty.col) {
            auto fs = FillStroke(_strokeColor.asVec, _strokeWidth, 0);
            if (_fillPaint) {
                switch (_fillPaint.type) {
                case PaintType.color:
                    auto cp = cast(ColorPaint)_fillPaint;
                    fs.numStops = 1;
                    encoder.updateConstBuffer(_csBlk, [ColorStop(cp.color.asVec, 0f)]);
                    break;
                case PaintType.linearGradient:
                    import std.algorithm : map;
                    import std.array : array;
                    auto lgp = cast(LinearGradientPaint)_fillPaint;
                    fs.numStops = cast(int)lgp.stops.length;
                    encoder.updateConstBuffer(
                        _csBlk, lgp.stops.map!(gs => ColorStop(gs.color.asVec, gs.position)).array
                    );
                    break;
                default:
                    break;
                }
            }
            encoder.updateConstBuffer(_fsBlk, fs);

            _dirty &= ~Dirty.col;
        }

        encoder.draw!RectPipeMeta(VertexBufferSlice(_ibuf), _pipe.obj, RectData(
            _vbuf, _mvpBlk, _fsBlk, _csBlk, context.renderTarget.rc
        ));
    }

    void setGPos(RectVertex[] verts)
    {
        auto lgp = cast(LinearGradientPaint)_fillPaint;
        if (!lgp) return;

        import std.algorithm : max;
        import std.math : cos, sin;

        // angle zero is defined to top (-Y)
        // angle 90deg is defined to right (+X)
        immutable r = rect;
        immutable angle = lgp.computeAngle(r.size);
        immutable c = r.center;
        // immutable ta = tan(angle);
        immutable ca = cos(angle);
        immutable sa = sin(angle);
        // gradient line eq
        // y = ax + b
        // immutable a = -1f / ta;
        // immutable b = c.x / ta + c.y;

        // unit vec along gradient line
        immutable u = fvec(sa, -ca);

        // signed distance from center along the gradient line
        float orthoProjDist(in FVec2 p) {
            return dot(p-c, u);
        }

        immutable tl = orthoProjDist(r.topLeft);
        immutable tr = orthoProjDist(r.topRight);
        immutable br = orthoProjDist(r.bottomRight);
        immutable bl = orthoProjDist(r.bottomLeft);
        immutable fact = 0.5 / max(tl, tr, br, bl);

        foreach (ref v; verts) {
            v.gpos = fact * orthoProjDist(v.vpos) + 0.5f;
        }
    }


    private FRect _rect;
    private float _radius = 0f;
    private Paint _fillPaint;
    private Color _strokeColor;
    private float _strokeWidth = 0f;

    private Rc!(VertexBuffer!RectVertex) _vbuf;
    private Rc!(IndexBuffer!ushort)    _ibuf;

    private Rc!RectPipe _pipe;
    private Rc!(ConstBuffer!MVP) _mvpBlk;
    private Rc!(ConstBuffer!FillStroke) _fsBlk;
    private Rc!(ConstBuffer!ColorStop) _csBlk;

    private enum Dirty {
        none    = 0,
        buf     = 1,
        col     = 2,
    }
    private Dirty _dirty = Dirty.buf | Dirty.col;
}

private:

struct RectVertex
{
    @GfxName("a_Pos")
    float[3] pos;   // z is gradient position

    @GfxName("a_Edge")
    float[3] edge;

    this(FVec2 pos, FVec3 edge) {
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

struct MVP
{
    FMat4 model;
    FMat4 viewProj;
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

struct RectPipeMeta
{
    VertexInput!RectVertex      input;

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

alias RectPipe = PipelineState!RectPipeMeta;
alias RectData = RectPipe.Data;
