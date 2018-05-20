module dgt.text.port.hb;

import dgt.bindings.harfbuzz;
import dgt.core.rc;
import dgt.font.port.ft;
import dgt.font.typeface;
import gfx.math.vec;
import dgt.text.shaping;


class HbTextShapingContext : TextShapingContext {
    mixin(atomicRcCode);

    this (FT_Face face, uint ftLoadFlags) {
        _font = hb_ft_font_create(face, null);
        hb_ft_font_set_load_flags(_font, ftLoadFlags);
    }

    override void dispose() {
        hb_font_destroy(_font);
        _font = null;
    }

    override immutable(GlyphInfo)[] shapeText(in string text) {
        auto hbb = hb_buffer_create();
        scope(exit) hb_buffer_destroy(hbb);
        hb_buffer_add_utf8(hbb, text.ptr, cast(int)text.length, 0, -1);
        hb_buffer_guess_segment_properties(hbb);
        hb_shape(_font, hbb, null, 0);
        auto numGlyphs = hb_buffer_get_length(hbb);
        auto glyphInfos = hb_buffer_get_glyph_infos(hbb, null);
        auto glyphPos = hb_buffer_get_glyph_positions(hbb, null);
        auto glyphs = new GlyphInfo[numGlyphs];
        foreach (i; 0 .. numGlyphs)
        {
            glyphs[i] = GlyphInfo(
                cast(GlyphId)glyphInfos[i].codepoint,
                fvec(glyphPos[i].x_advance/64, glyphPos[i].y_advance/64),
                fvec(glyphPos[i].x_offset/64, -glyphPos[i].y_offset/64),
            );
        }
        import std.exception : assumeUnique;
        return assumeUnique(glyphs);
    }

    private hb_font_t* _font;
}
