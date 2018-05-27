module dgt.render.text2;

import gfx.core.rc : AtomicRefCounted, Disposable;

class TextRenderer : Disposable
{
    import dgt.render.atlas : GlyphAtlas;
    import dgt.render.framegraph : FGFrame, FGTextNode;
    import dgt.render.renderer2 : RenderContext;
    import dgt.text.layout : TextShape;
    import gfx.core.rc : Rc;
    import gfx.decl.store : DeclarativeStore;
    import gfx.graal.device : Device;
    import gfx.graal.pipeline : Pipeline;
    import gfx.math.mat : FMat4;
    import gfx.memalloc : Allocator;

    private Rc!Device device;
    private Rc!Pipeline pipeline;
    private Rc!Allocator allocator;
    private AtlasTexture[] atlases;
    private GlyphRun[size_t] glyphRuns;

    this(Device device, DeclarativeStore store, Allocator allocator)
    {
        this.device = device;
        this.pipeline = store.expect!Pipeline("text_pl");
        this.allocator = allocator;
    }

    override void dispose()
    {
        allocator.unload();
        pipeline.unload();
        device.unload();
    }

    void framePreprocess(immutable(FGFrame) frame)
    {
        import dgt.render.framegraph : breadthFirst, FGNode;

        foreach(immutable n; breadthFirst(frame.root)) {
            if (n.type == FGNode.Type.text) {
                immutable tn = cast(immutable(FGTextNode)) n;
                foreach (s; tn.shapes) {
                    feedGlyphRun(s);
                }
            }
        }
        foreach (ref at; atlases) {
            if (at.atlas.realize()) {
                // rebuild and upload texture
                import gfx.core.rc : releaseObj, retainObj;
                import gfx.graal.format : Format;
                import gfx.graal.image :    ImageAspect, ImageInfo, ImageSubresourceRange,
                                            ImageTiling, ImageType, ImageUsage,
                                            SamplerInfo, Swizzle;
                import gfx.graal.memory :   MemoryRequirements, MemProps;
                import gfx.memalloc : AllocationInfo, MemoryUsage;
                import std.format : format;
                import std.exception : enforce;

                releaseObj(at.img);
                releaseObj(at.view);
                releaseObj(at.sampler);
                releaseObj(at.alloc);

                auto atImg = at.atlas.image;
                const sz = atImg.size;

                auto img = device.createImage(
                    ImageInfo.d2(sz.width, sz.height)
                        .withFormat(Format.r8_uNorm)
                        .withUsage(ImageUsage.sampled)
                        .withTiling(ImageTiling.optimal)
                );
                auto alloc = enforce(allocator.allocate(
                    img.memoryRequirements,
                    AllocationInfo.forUsage(MemoryUsage.gpuOnly).withPreferredProps(MemProps.hostVisible)
                ), format("could not allocate for %s", img.memoryRequirements));
                img.bindMemory(alloc.mem, alloc.offset);

                auto view = img.createView(
                    ImageType.d2, ImageSubresourceRange(ImageAspect.color),
                    Swizzle.identity
                );
                auto sampler = device.createSampler(SamplerInfo.nearest);

                at.img = retainObj(img);
                at.view = retainObj(view);
                at.sampler = retainObj(sampler);
                at.alloc = retainObj(alloc);
            }
        }
    }

    void render(immutable(FGTextNode) node, RenderContext ctx, in FMat4 model)
    {

    }

    private void feedGlyphRun(in TextShape shape)
    {
        import dgt.core.sync : synchronize;
        import dgt.font.library : FontLibrary;
        import dgt.font.typeface : Glyph, ScalingContext, Typeface;
        import dgt.render.atlas : AtlasNode;
        import dgt.text.shaping : GlyphInfo;
        import gfx.core.rc : rc;
        import gfx.math : fvec, ivec;

        if (shape.id in glyphRuns) return;

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
                    auto atlasF = atlases.find!(a => a.atlas.couldPack(size));
                    if (atlasF.length) {
                        node = atlasF[0].atlas.pack(size, glyph);
                    }
                    if (!node) {
                        // could not find an atlas with room left, or did not create atlas at all yet
                        auto atlas = new GlyphAtlas(ivec(128, 128), ivec(512, 512), 1);
                        atlases ~= AtlasTexture(atlas);
                        node = enforce(atlas.pack(size, glyph),
                                "could not pack a glyph into a new atlas. What size is this glyph??");
                    }
                    glyph.rendererData = node;
                }

                auto atlas = node.atlas;

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
            glyphRuns[shape.id] = run;
        }
    }

}


private:

struct AtlasTexture
{
    import dgt.render.atlas : GlyphAtlas;
    import gfx.graal.image : Image, ImageView, Sampler;
    import gfx.memalloc : Allocation;

    GlyphAtlas atlas;
    Allocation alloc;
    Image img;
    ImageView view;
    Sampler sampler;
}


class GlyphRun
{
    import dgt.render.atlas : AtlasNode, GlyphAtlas;

    // most runs will have a single part, but if there are a lot of glyphs with
    // big size, it can happen that we come to an atlas boundary and then the
    // end of the run arrives on a second atlas
    struct Part {
        GlyphAtlas atlas;
        GRGlyph[] glyphs;  // ordered array - each node map to a glyph
    }

    Part[] parts;
}

struct GRGlyph
{
    import dgt.render.atlas : AtlasNode;
    import gfx.math : FVec2;

    FVec2 position;
    AtlasNode node;
}
