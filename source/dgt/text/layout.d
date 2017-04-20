/// Text layout and shaping
module dgt.text.layout;

import dgt.text.fontcache;
import dgt.text.font;
import gfx.foundation.rc;
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

/// Metrics of text drawn to screen
struct TextMetrics
{
    /// Offset of the text bounding box to the pen start position.
    /// Bounding box origin is top-left
    /// Positive in x means that pen start position is right of the bounding box origin.
    /// Positive in y means that pen start position is lower than the bounding box origin.
    IVec2 bearing;
    /// Size of the text bounding box
    IVec2 size;
    /// Advance equals (pen end position - pen start position)
    /// Pen end position can be the start position of another text concatenated
    /// to the one those metrics refer to.
    IVec2 advance;

    invariant()
    {
        assert(advance.x == 0 || advance.y == 0);
    }

    /// True if this refers to an horizontal text metrics
    @property bool horizontal() const
    {
        return advance.y == 0;
    }

    /// True if this refers to a vertical text metrics
    @property bool vertical() const
    {
        return advance.x == 0;
    }
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
        reinit(_matchedFonts);
        reinit(_items);
        reinit(_shapes);
    }

    /// This is the operation of splitting the text into items and to shape
    /// each of them.
    void layout()
    {
        import std.algorithm : find, all;
        reinit(_items);
        reinit(_shapes);

        // find the first font that cover the whole string
        auto mf = _matchedFonts.find!(
            (ref m) {
                import std.utf : byDchar;
                auto cov = m.coverage;
                return byDchar(_text).all!(c => cov[c]);
            }
        );

        enforce(mf.length, "Could not find a font matching for \""~_text~"\"");

        // only plain text single item support
        _items = [TextItem(
            _text, makeRc!Font(mf[0]), ImageFormat.a8, 0,
        )];
        foreach(ref i; _items)
        {
            _shapes ~= shapeItem(i);
        }
    }

    /// Perform a rendering simulation (without rasterizing any glyph) and
    /// return the metrics associated to this layout.
    public @property TextMetrics metrics()
    {
        import std.algorithm : min, max;
        import std.math : round;
        // FIXME: vertical
        float bearingX;
        float width;
        float top = 0;
        float bottom =0;
        auto advance = fvec(0, 0);

        foreach (TextShape ts; _shapes)
        {
            foreach (i, GlyphInfo gi; ts.glyphs)
            {
                immutable gm = ts.font.glyphMetrics(gi.index);
                if (i == 0)
                {
                    bearingX = -gm.horBearing.x;
                    width = -gm.horBearing.x;
                }
                if (i == ts.glyphs.length-1)
                {
                    // width = total advance wo last char       +
                    //         horizontal bearing of last char  +
                    //         width of last char               -
                    //         horizontal bearing of first char
                    width += (advance.x + gm.horBearing.x + gm.size.x);
                }
                top = max(top, gm.horBearing.y);
                bottom = min(bottom, gm.horBearing.y - gm.size.y);
                advance += gi.advance;
            }
        }
        return TextMetrics(
            ivec(round(bearingX), round(top)),
            ivec(round(width), round(top-bottom)),
            ivec(round(advance.x), round(advance.y))
        );
    }

    /// Render the layout into the supplied context.
    public void renderInto(VgContext context)
    {
        import std.math : floor;
        context.save();
        scope(exit)
            context.restore();

        immutable origTr = context.transform;
        auto advance = fvec(0, 0);
        foreach (TextShape ts; _shapes)
        {
            foreach (i, GlyphInfo gi; ts.glyphs)
            {
                auto rg = ts.font.rasterizeGlyph(gi.index);
                if (rg)
                {
                    context.transform = origTr.translate(
                        gi.offset +
                        ivec(rg.bearing.x, -rg.bearing.y) +
                        ivec(floor(advance.x), floor(advance.y))
                    );
                    context.mask(rg.image);
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
