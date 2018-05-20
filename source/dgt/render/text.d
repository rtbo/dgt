/// Text rendering module
module dgt.render.text;

version(none):

import dgt.core.geometry;
import dgt.core.rc;
import dgt.core.sync;
import dgt.font.library;
import dgt.font.typeface;
import dgt.math : FMat4, transpose;
import dgt.render.atlas;
import dgt.render.defs;
import dgt.render.framegraph;
import dgt.render.renderer : RenderContext;
import dgt.text.layout;
import dgt.text.shaping;

import gfx.pipeline;

class TextRenderer : Disposable
{
    alias Vertex = P2T2Vertex;
    alias Meta = TextMeta;
    alias StateObject = PipelineState!TextMeta;
    alias Data = StateObject.Data;

    this() {
        auto prog = makeRc!Program(ShaderSet.vertexPixel(
            textVShader, textFShader
        ));

        _pso = new StateObject(
            prog.obj, Primitive.triangles,
            Rasterizer.fill.withSamples()
        );
        _pso.retain();

        _mvpBlk = new ConstBuffer!MVP(1);
        _mvpBlk.retain();

        _colBlk = new ConstBuffer!Color(1);
        _colBlk.retain();

        ushort[] quadInds = [0, 1, 2, 0, 2, 3];
        _quadIBuf = new IndexBuffer!ushort(quadInds);
        _quadIBuf.retain();
    }

    override void dispose() {
        _pso.release();
        _mvpBlk.release();
        _colBlk.release();
        _quadIBuf.release();
        releaseArray(_glyphRuns);
        releaseArray(_atlases);
    }

    void framePreprocess(immutable(FGFrame) frame) {
        foreach(immutable n; breadthFirst(frame.root)) {
            if (n.type == FGNode.Type.text) {
                immutable tn = cast(immutable(FGTextNode)) n;
                foreach (s; tn.shapes) {
                    feedGlyphRun(s);
                }
            }
        }
        foreach (atlas; _atlases) {
            atlas.realize();
        }
    }

    void render(immutable(FGTextNode) node, RenderContext ctx, in FMat4 model, CommandBuffer cmdBuf)
    {
        auto encoder = Encoder(cmdBuf);
        encoder.updateConstBuffer(_colBlk, Color(node.color));

        const bearing = node.bearing;

        foreach (shape; node.shapes) {

            auto gr = _glyphRuns[shape.id].rc;

            foreach (p; gr.parts) {

                const textureSize = cast(FVec2)p.atlas.textureSize;

                foreach (gl; p.glyphs) {

                    auto an = gl.node;

                    // texel space rect
                    const fSize = FSize(an.size.x, an.size.y);
                    const txRect = FRect(cast(FVec2)an.origin, fSize);

                    // normalized rect
                    immutable normRect = FRect(
                        txRect.topLeft / textureSize,
                        FSize(txRect.width / textureSize.x, txRect.height / textureSize.y)
                    );
                    immutable vertRect = FRect(
                        gl.position, txRect.size
                    );
                    auto quadVerts = [
                        P2T2Vertex([vertRect.left+bearing.x, vertRect.top+bearing.y], [normRect.left, normRect.top]),
                        P2T2Vertex([vertRect.left+bearing.x, vertRect.bottom+bearing.y], [normRect.left, normRect.bottom]),
                        P2T2Vertex([vertRect.right+bearing.x, vertRect.bottom+bearing.y], [normRect.right, normRect.bottom]),
                        P2T2Vertex([vertRect.right+bearing.x, vertRect.top+bearing.y], [normRect.right, normRect.top]),
                    ];
                    auto vbuf = makeRc!(VertexBuffer!P2T2Vertex)(quadVerts);

                    encoder.updateConstBuffer(_mvpBlk, MVP(transpose(model), transpose(ctx.viewProj)));

                    encoder.draw!TextMeta(VertexBufferSlice(_quadIBuf), _pso, Data(
                        rc(vbuf), rc(_mvpBlk), rc(_colBlk), rc(p.atlas.srv), rc(p.atlas.sampler), rc(ctx.renderTarget)
                    ));
                }
            }
        }
    }

    private void feedGlyphRun(in TextShape shape)
    {
        if (shape.id in _glyphRuns) return;

        GlyphRun.Part[] parts;
        auto advance = fvec(0, 0);

        auto tf = FontLibrary.get.getById(shape.fontId);
        assert(tf);
        tf.synchronize!((Typeface tf) {
            ScalingContext sc = tf.getScalingContext(shape.size).rc;
            foreach (const GlyphInfo gi; shape.glyphs) {
                import std.algorithm : find;
                import std.exception : enforce;
                Glyph glyph = sc.renderGlyph(gi.index);
                if (!glyph) continue;
                if (glyph.isWhitespace) {
                    advance += gi.advance;
                    continue;
                }

                const metrics = glyph.metrics;
                const position = gi.offset + advance +
                        fvec(metrics.horBearing.x, -metrics.horBearing.y);

                advance += gi.advance;

                AtlasNode node = cast(AtlasNode)glyph.rendererData;

                if (!node) {
                    // this glyph is not yet in an atlas, let's pack it
                    const size = glyph.img.size.asVec;
                    auto atlasF = _atlases.find!(a => a.couldPack(size));
                    if (atlasF.length) {
                        node = atlasF[0].pack(size, glyph);
                    }
                    if (!node) {
                        // could not find an atlas with room left, or did not create atlas at all yet
                        auto atlas = new GlyphAtlas(ivec(128, 128), ivec(512, 512), 1);
                        atlas.retain();
                        _atlases ~= atlas;
                        node = enforce(atlas.pack(size, glyph),
                                "could not pack a glyph into a new atlas. What size is this glyph??");
                    }
                    glyph.rendererData = node;
                }

                auto atlas = node.atlas.lock();
                assert(atlas, "Atlas not found");

                auto grg = GRGlyph(position, node);

                if (!parts.length || parts[$-1].atlas !is atlas) {
                    parts ~= GlyphRun.Part(atlas, [ grg ]);
                }
                else {
                    parts[$-1].glyphs ~= grg;
                }

            }
        });

        if (parts.length) {
            auto run = new GlyphRun;
            run.parts = parts;
            run.retain();
            _glyphRuns[shape.id] = run;
        }
    }

    private GlyphAtlas[] _atlases;
    private GlyphRun[size_t] _glyphRuns;

    private StateObject _pso;
    private ConstBuffer!MVP _mvpBlk;
    private ConstBuffer!Color _colBlk;
    private IndexBuffer!ushort _quadIBuf;
}


private:

class GlyphRun : RefCounted {
    mixin(rcCode);

    // most runs will have a single part, but if there are a lot of glyphs with
    // big size, it can happen that we come to an atlas boundary and then the
    // end of the run arrives on a second atlas
    struct Part {
        Rc!GlyphAtlas atlas;
        GRGlyph[] glyphs;  // ordered array - each node map to a glyph
    }

    Part[] parts;

    override void dispose() {
        reinitArray(parts);
    }
}

struct GRGlyph {
    FVec2 position;
    AtlasNode node;
}

struct Color {
    FVec4 color;
}

struct TextMeta
{
    VertexInput!P2T2Vertex   input;

    @GfxName("MVP")
    ConstantBlock!MVP       mvp;

    @GfxName("Color")
    ConstantBlock!Color       color;

    @GfxName("t_Sampler")
    ResourceView!Alpha8          texture;

    @GfxName("t_Sampler")
    ResourceSampler             sampler;

    @GfxName("o_Color")
    @GfxBlend(Blend( Equation.add, Factor.one, Factor.oneMinusSrcAlpha ))
    BlendOutput!Rgba8           outColor;
}

enum textVShader = `
    #version 330
    in vec2 a_Pos;
    in vec2 a_Tex;

    uniform MVP {
        mat4 u_modelMat;
        mat4 u_viewProjMat;
    };

    out vec2 v_Tex;

    void main() {
        v_Tex = a_Tex;
        vec4 worldPos = u_modelMat * vec4(a_Pos, 0, 1);
        gl_Position = u_viewProjMat * vec4(worldPos.xy, 0, 1);
    }
`;
enum textFShader = `
    #version 330

    in vec2 v_Tex;

    uniform sampler2D t_Sampler;
    uniform Color {
        vec4 u_Color;
    };

    out vec4 o_Color;

    void main() {
        vec4 sample = texture(t_Sampler, v_Tex);
        const float gamma = 1.8;
        o_Color = pow(sample.r, gamma) * u_Color;
        // o_Color = sample.r * u_Color;
    }
`;
