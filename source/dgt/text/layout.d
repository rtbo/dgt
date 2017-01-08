module dgt.text.layout;

import dgt.text.fontcache;
import dgt.text.font;
import dgt.core.resource;
import dgt.vg.context;
import dgt.image;
import dgt.math.vec;
import dgt.math.mat;
import dgt.math.transform;
import dgt.bindings.harfbuzz;

import std.exception;

/// Format in which the text is submitted
enum TextFormat
{
    plain,
    html,
}

/// The layout is divided in different items, for example because a word
/// is in italic or in another color, or due to bidirectional text (unimplemented).
struct TextItem
{
    string text;
    Rc!Font font;
    ImageFormat renderFormat;
    uint argbColor;
}

/// A shape of text
struct TextShape
{
    string text;
    Rc!Font font;
    GlyphInfo[] glyphs;
}

/// Per glyph info issued from the text shaper
struct GlyphInfo
{
    uint index;
    FVec2 advance;
    IVec2 offset;
}

/// A single line text layout
class TextLayout : RefCounted
{
    mixin(rcCode);
    /// Builds a layout
    this(string text, TextFormat format, FontRequest font)
    {
        _text = text;
        _format = format;
        _matchedFonts = FontCache.instance.requestFont(font);
        enforce(_matchedFonts.length, "Text layout could not match any font");
    }

    override void dispose()
    {
        reinit(_items);
        reinit(_shapes);
    }

    /// This is the operation of splitting the text into items and to shape
    /// each of them.
    void layout()
    {
        reinit(_items);
        reinit(_shapes);
        // only plain text single item support
        _items = [TextItem(
            _text, makeRc!Font(_matchedFonts[0]), ImageFormat.a8, 0,
        )];
        foreach(ref i; _items)
        {
            _shapes ~= shapeItem(i);
        }
    }

    /// Render the layout into the supplied context.
    public void renderInto(VgContext context)
    {
        import std.math : floor;
        context.save();
        scope(exit)
            context.restore();

        auto backend = context.backend;

        immutable origTr = context.transform;
        auto advance = fvec(0, 0);
        foreach (TextShape ts; _shapes)
        {
            foreach (i, GlyphInfo gi; ts.glyphs)
            {
                auto rg = ts.font.rasterizeGlyph(gi.index, backend);
                if (rg)
                {
                    context.transform = origTr.translate(
                        gi.offset +
                        ivec(rg.bearing.x, -rg.bearing.y) +
                        ivec(floor(advance.x), floor(advance.y))
                    );
                    context.mask(rg.bitmapTex);
                }
                advance += gi.advance;
            }
        }
    }

    private TextShape shapeItem(TextItem item)
    {
        auto hbb = hb_buffer_create();
        scope(exit) hb_buffer_destroy(hbb);
        hb_buffer_add_utf8(hbb, item.text.ptr, cast(int)item.text.length, 0, -1);
        hb_buffer_guess_segment_properties(hbb);
        hb_shape(item.font.hbFont, hbb, null, 0);
        auto numGlyphs = hb_buffer_get_length(hbb);
        auto glyphInfos = hb_buffer_get_glyph_infos(hbb, null);
        auto glyphPos = hb_buffer_get_glyph_positions(hbb, null);
        auto glyphs = new GlyphInfo[numGlyphs];
        foreach (i; 0 .. numGlyphs)
        {
            glyphs[i] = GlyphInfo(
                glyphInfos[i].codepoint,
                fvec(glyphPos[i].x_advance/64, glyphPos[i].y_advance/64),
                ivec(glyphPos[i].x_offset/64, -glyphPos[i].y_offset/64),
            );
        }
        return TextShape(item.text, item.font, glyphs);
    }

    private string _text;
    private TextFormat _format;
    private FontResult[] _matchedFonts;
    private TextItem[] _items;
    private TextShape[] _shapes;
}
