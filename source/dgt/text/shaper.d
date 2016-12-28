module dgt.text.shaper;

import dgt.text.layout;
import dgt.text.font;
import dgt.core.resource;
import dgt.bindings.harfbuzz;
import dgt.math.vec;

import std.string;


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
    FVec2 offset;
}

private __gshared TextShaper _instance;

/// Shape items of text given by a text layout
class TextShaper : Disposable
{
    // called by Application.initialize
    package(dgt) static TextShaper initialize()
    in
    {
        assert(_instance is null);
    }
    body
    {
        _instance = new TextShaper();
        return _instance;
    }

    /// Returns the singleton instance.
    /// Should not be called before Application is created.
    public static TextShaper instance()
    in
    {
        assert(_instance !is null);
    }
    body
    {
        return _instance;
    }

    private this()
    {
        loadHarfbuzzSymbols();
    }

    override void dispose()
    {

    }

    TextShape shape(TextItem item)
    {
        auto hbf = hb_ft_font_create(item.font.ftFace, null);
        scope(exit) hb_font_destroy(hbf);
        auto hbb = hb_buffer_create();
        scope(exit) hb_buffer_destroy(hbb);
        hb_buffer_add_utf8(hbb, item.text.ptr, cast(int)item.text.length, 0, -1);
        hb_buffer_guess_segment_properties(hbb);
        hb_shape(hbf, hbb, null, 0);
        auto numGlyphs = hb_buffer_get_length(hbb);
        auto glyphInfos = hb_buffer_get_glyph_infos(hbb, null);
        auto glyphPos = hb_buffer_get_glyph_positions(hbb, null);
        auto glyphs = new GlyphInfo[numGlyphs];
        foreach (i; 0 .. numGlyphs)
        {
            glyphs[i] = GlyphInfo(
                glyphInfos[i].codepoint,
                FVec2(glyphPos[i].x_advance, glyphPos[i].y_advance),
                FVec2(glyphPos[i].x_offset, glyphPos[i].y_offset),
            );
        }
        return TextShape(item.text, item.font, glyphs);
    }

}
