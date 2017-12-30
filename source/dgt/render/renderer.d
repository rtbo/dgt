module dgt.render.renderer;

import dgt.core.geometry;
import dgt.core.rc;
import dgt.core.sync;
import dgt.font.library;
import dgt.font.typeface;
import dgt.render.atlas;
import dgt.render.defs;
import dgt.render.framegraph;
import dgt.text.layout;
import dgt.text.shaping;
import gfx.device;
import gfx.pipeline;

struct RenderOptions {
    int samples;
}

class Renderer : Disposable {

    this(Device device, RenderOptions options) {
        _device = device;
        _options = options;
    }

    void dispose() {
        if (_cmdBuf.loaded) {
            _rtv.unload();
            _surf.unload();
            _cmdBuf.unload();
        }
        _device.unload();
    }

    private void initialize() {
        assert(!_cmdBuf);
        _cmdBuf = _device.makeCommandBuffer();
        // TODO pass actual window size
        _surf = new BuiltinSurface!Rgba8(
            _device.builtinSurface, 1, 1, cast(ubyte)_options.samples
        );
        _rtv = _surf.viewAsRenderTarget();
    }

    void renderFrame(immutable(FGFrame) frame) {
        if (!_cmdBuf) {
            initialize();
        }

        immutable vp = cast(Rect!ushort)frame.viewport;
        auto encoder = Encoder(_cmdBuf);
        encoder.setViewport(vp.x, vp.y, vp.width, vp.height);

        import std.algorithm : each;
        frame.clearColor.each!(
            c => encoder.clear!Rgba8(_rtv, [c.r, c.g, c.b, c.a])
        );

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


        encoder.flush(_device);
    }

    private void feedGlyphRun(in TextShape shape) {

        if (shape.id in _glyphRuns) return;

        GlyphRun.Part[] parts;

        auto tf = FontLibrary.get.matchFamilyStyle(shape.style.family, shape.style.style);
        tf.synchronize!((Typeface tf) {
            ScalingContext sc = tf.makeScalingContext(shape.style.size).rc;
            foreach (const GlyphInfo gi; shape.glyphs) {
                import std.algorithm : find;
                import std.exception : enforce;
                Glyph glyph = sc.renderGlyph(gi.index);
                if (!glyph || !glyph.img) continue;
                const size = glyph.img.size.asVec;
                auto atlasF = _atlases.find!(a => a.couldPack(size));
                GlyphAtlas atlas;
                AtlasNode node;
                if (atlasF.length) {
                    atlas = atlasF[0];
                    node = atlas.pack(size, glyph);
                }
                if (!node) {
                    // could not find an atlas with room left, or did not create atlas at all yet
                    atlas = new GlyphAtlas(ivec(128, 128), ivec(512, 512), 1);
                    atlas.retain();
                    _atlases ~= atlas;
                    node = enforce(atlas.pack(size, glyph),
                            "could not pack a glyph into a new atlas. What size is this glyph??");
                }
                if (!parts.length || atlas !is parts[$-1].atlas) {
                    // starting a new part
                    parts ~= GlyphRun.Part(atlas.rc, [ node ]);
                }
                else {
                    // continue the previous one
                    parts[$-1].nodes ~= node;
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

    class GlyphRun : RefCounted {
        mixin(rcCode);

        struct Part {
            Rc!GlyphAtlas atlas;
            AtlasNode[] nodes; // ordered array - each node contains a glyph
        }

        Part[] parts;

        override void dispose() {
            reinitArray(parts);
        }
    }

    private Rc!Device _device;
    private RenderOptions _options;
    private Rc!CommandBuffer _cmdBuf;
    private Rc!(BuiltinSurface!Rgba8) _surf;
    private Rc!(RenderTargetView!Rgba8) _rtv;

    private GlyphAtlas[] _atlases;
    private GlyphRun[size_t] _glyphRuns;
}
