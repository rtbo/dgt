module dgt.bindings.harfbuzz;

public import dgt.bindings.harfbuzz.definitions;
public import dgt.bindings.harfbuzz.symbols;
import dgt.bindings;

import std.meta : AliasSeq;
import std.typecons : Yes;

/// Load the harfbuzz library symbols.
/// Must be called before any use of hb_* functions.
/// If no libNames is provided, a per-platform guess is performed.
public void loadHarfbuzzSymbols(string[] libNames = [])
{
    version (linux)
    {
        auto defaultLibNames = ["libharfbuzz.so", "libharfbuzz.so.0"];
    }
    if (libNames.length == 0)
    {
        libNames = defaultLibNames;
    }
    harfbuzzLoader.load(libNames);
}

/// Checks whether harfbuzz is loaded
public @property bool harfbuzzLoaded()
{
    return harfbuzzLoader.loaded;
}

private __gshared HarfbuzzLoader harfbuzzLoader;

alias HarfbuzzLoader = SymbolLoader!(
    // HarfbuzzBlobSymbols,
    HarfbuzzBufferSymbols,
    // HarfbuzzCommonSymbols,
    // HarfbuzzDebugSymbols,
    // HarfbuzzFaceSymbols,
    HarfbuzzFontSymbols,
    // HarfbuzzSetSymbols,
    HarfbuzzShapeSymbols,
    // HarfbuzzShapePlanSymbols,
    // HarfbuzzUnicodeSymbols,
    // HarfbuzzVersionSymbols,
    HarfbuzzFreetypeSymbols
);

// alias HarfbuzzBlobSymbols = AliasSeq!(
//     hb_blob_create,
//     hb_blob_create_sub_blob,
//     hb_blob_get_empty,
//     hb_blob_reference,
//     hb_blob_destroy,
//     hb_blob_set_user_data,
//     hb_blob_get_user_data,
//     hb_blob_make_immutable,
//     hb_blob_is_immutable,
//     hb_blob_get_length,
//     hb_blob_get_data,
//     hb_blob_get_data_writable,
// );
alias HarfbuzzBufferSymbols = AliasSeq!(
//     hb_segment_properties_equal,
//     hb_segment_properties_hash,
    hb_buffer_create,
//     hb_buffer_get_empty,
//     hb_buffer_reference,
    hb_buffer_destroy,
//     hb_buffer_set_user_data,
//     hb_buffer_get_user_data,
//     hb_buffer_set_content_type,
//     hb_buffer_get_content_type,
//     hb_buffer_set_unicode_funcs,
//     hb_buffer_get_unicode_funcs,
//     hb_buffer_set_direction,
    hb_buffer_get_direction,
//     hb_buffer_set_script,
//     hb_buffer_get_script,
//     hb_buffer_set_language,
//     hb_buffer_get_language,
//     hb_buffer_set_segment_properties,
//     hb_buffer_get_segment_properties,
    hb_buffer_guess_segment_properties,
//     hb_buffer_set_flags,
//     hb_buffer_get_flags,
//     hb_buffer_set_cluster_level,
//     hb_buffer_get_cluster_level,
//     hb_buffer_set_replacement_codepoint,
//     hb_buffer_get_replacement_codepoint,
//     hb_buffer_reset,
//     hb_buffer_clear_contents,
//     hb_buffer_pre_allocate,
//     hb_buffer_allocation_successful,
//     hb_buffer_reverse,
//     hb_buffer_reverse_range,
//     hb_buffer_reverse_clusters,
//     hb_buffer_add,
    hb_buffer_add_utf8,
//     hb_buffer_add_utf16,
//     hb_buffer_add_utf32,
//     hb_buffer_add_latin1,
//     hb_buffer_add_codepoints,
//     hb_buffer_set_length,
    hb_buffer_get_length,
    hb_buffer_get_glyph_infos,
    hb_buffer_get_glyph_positions,
//     hb_buffer_normalize_glyphs,
//     hb_buffer_serialize_format_from_string,
//     hb_buffer_serialize_format_to_string,
//     hb_buffer_serialize_list_formats,
//     hb_buffer_serialize_glyphs,
//     hb_buffer_deserialize_glyphs,
);
// alias HarfbuzzDebugSymbols = AliasSeq!(
//     hb_buffer_set_message_func,
// );
// alias HarfbuzzCommonSymbols = AliasSeq!(
//     hb_tag_from_string,
//     hb_tag_to_string,
//     hb_direction_from_string,
//     hb_direction_to_string,
//     hb_language_from_string,
//     hb_language_to_string,
//     hb_language_get_default,
//     hb_script_from_iso15924_tag,
//     hb_script_from_string,
//     hb_script_to_iso15924_tag,
//     hb_script_get_horizontal_direction,
// );
// alias HarfbuzzFaceSymbols = AliasSeq!(
//     hb_face_create,
//     hb_face_create_for_tables,
//     hb_face_get_empty,
//     hb_face_reference,
//     hb_face_destroy,
//     hb_face_set_user_data,
//     hb_face_get_user_data,
//     hb_face_make_immutable,
//     hb_face_is_immutable,
//     hb_face_reference_table,
//     hb_face_reference_blob,
//     hb_face_set_index,
//     hb_face_get_index,
//     hb_face_set_upem,
//     hb_face_get_upem,
//     hb_face_set_glyph_count,
//     hb_face_get_glyph_count,
// );
alias HarfbuzzFontSymbols = AliasSeq!(
//     hb_font_funcs_create,
//     hb_font_funcs_get_empty,
//     hb_font_funcs_reference,
//     hb_font_funcs_destroy,
//     hb_font_funcs_set_user_data,
//     hb_font_funcs_get_user_data,
//     hb_font_funcs_make_immutable,
//     hb_font_funcs_is_immutable,
//     hb_font_funcs_set_font_h_extents_func,
//     hb_font_funcs_set_font_v_extents_func,
//     hb_font_funcs_set_nominal_glyph_func,
//     hb_font_funcs_set_variation_glyph_func,
//     hb_font_funcs_set_glyph_h_advance_func,
//     hb_font_funcs_set_glyph_v_advance_func,
//     hb_font_funcs_set_glyph_h_origin_func,
//     hb_font_funcs_set_glyph_v_origin_func,
//     hb_font_funcs_set_glyph_h_kerning_func,
//     hb_font_funcs_set_glyph_v_kerning_func,
//     hb_font_funcs_set_glyph_extents_func,
//     hb_font_funcs_set_glyph_contour_point_func,
//     hb_font_funcs_set_glyph_name_func,
//     hb_font_funcs_set_glyph_from_name_func,
//     hb_font_get_h_extents,
//     hb_font_get_v_extents,
//     hb_font_get_nominal_glyph,
//     hb_font_get_variation_glyph,
//     hb_font_get_glyph_h_advance,
//     hb_font_get_glyph_v_advance,
//     hb_font_get_glyph_h_origin,
//     hb_font_get_glyph_v_origin,
//     hb_font_get_glyph_h_kerning,
//     hb_font_get_glyph_v_kerning,
//     hb_font_get_glyph_extents,
//     hb_font_get_glyph_contour_point,
//     hb_font_get_glyph_name,
//     hb_font_get_glyph_from_name,
//     hb_font_get_glyph,
//     hb_font_get_extents_for_direction,
//     hb_font_get_glyph_advance_for_direction,
//     hb_font_get_glyph_origin_for_direction,
//     hb_font_add_glyph_origin_for_direction,
//     hb_font_subtract_glyph_origin_for_direction,
//     hb_font_get_glyph_kerning_for_direction,
//     hb_font_get_glyph_extents_for_origin,
//     hb_font_get_glyph_contour_point_for_origin,
//     hb_font_glyph_to_string,
//     hb_font_glyph_from_string,
//     hb_font_create,
//     hb_font_create_sub_font,
//     hb_font_get_empty,
//     hb_font_reference,
    hb_font_destroy,
//     hb_font_set_user_data,
//     hb_font_get_user_data,
//     hb_font_make_immutable,
//     hb_font_is_immutable,
//     hb_font_set_parent,
//     hb_font_get_parent,
//     hb_font_get_face,
//     hb_font_set_funcs,
//     hb_font_set_funcs_data,
//     hb_font_set_scale,
//     hb_font_get_scale,
//     hb_font_set_ppem,
//     hb_font_get_ppem,
//     hb_font_set_var_coords_normalized,              Yes.optional,
);
// alias HarfbuzzSetSymbols = AliasSeq!(
//     hb_set_create,
//     hb_set_get_empty,
//     hb_set_reference,
//     hb_set_destroy,
//     hb_set_set_user_data,
//     hb_set_get_user_data,
//     hb_set_allocation_successful,
//     hb_set_clear,
//     hb_set_is_empty,
//     hb_set_has,
//     hb_set_add,
//     hb_set_add_range,
//     hb_set_del,
//     hb_set_del_range,
//     hb_set_is_equal,
//     hb_set_set,
//     hb_set_union,
//     hb_set_intersect,
//     hb_set_subtract,
//     hb_set_symmetric_difference,
//     hb_set_invert,
//     hb_set_get_population,
//     hb_set_get_min,
//     hb_set_get_max,
//     hb_set_next,
//     hb_set_next_range,
// );
alias HarfbuzzShapeSymbols = AliasSeq!(
//     hb_feature_from_string,
//     hb_feature_to_string,
    hb_shape,
//     hb_shape_full,
//     hb_shape_list_shapers,
);
// alias HarfbuzzShapePlanSymbols = AliasSeq!(
//     hb_shape_plan_create,
//     hb_shape_plan_create_cached,
//     hb_shape_plan_create2,                          Yes.optional,
//     hb_shape_plan_create_cached2,                   Yes.optional,
//     hb_shape_plan_get_empty,
//     hb_shape_plan_reference,
//     hb_shape_plan_destroy,
//     hb_shape_plan_set_user_data,
//     hb_shape_plan_get_user_data,
//     hb_shape_plan_execute,
//     hb_shape_plan_get_shaper,
// );
// alias HarfbuzzUnicodeSymbols = AliasSeq!(
//     hb_unicode_funcs_get_default,
//     hb_unicode_funcs_create,
//     hb_unicode_funcs_get_empty,
//     hb_unicode_funcs_reference,
//     hb_unicode_funcs_destroy,
//     hb_unicode_funcs_set_user_data,
//     hb_unicode_funcs_get_user_data,
//     hb_unicode_funcs_make_immutable,
//     hb_unicode_funcs_is_immutable,
//     hb_unicode_funcs_get_parent,
//     hb_unicode_funcs_set_combining_class_func,
//     hb_unicode_funcs_set_eastasian_width_func,
//     hb_unicode_funcs_set_general_category_func,
//     hb_unicode_funcs_set_mirroring_func,
//     hb_unicode_funcs_set_script_func,
//     hb_unicode_funcs_set_compose_func,
//     hb_unicode_funcs_set_decompose_func,
//     hb_unicode_funcs_set_decompose_compatibility_func,
//     hb_unicode_combining_class,
//     hb_unicode_eastasian_width,
//     hb_unicode_general_category,
//     hb_unicode_mirroring,
//     hb_unicode_script,
//     hb_unicode_compose,
//     hb_unicode_decompose,
//     hb_unicode_decompose_compatibility,
// );
// alias HarfbuzzVersionSymbols = AliasSeq!(
//     hb_version,
//     hb_version_string,
//     hb_version_atleast,
// );
alias HarfbuzzFreetypeSymbols = AliasSeq!(
//     hb_ft_face_create,
//     hb_ft_face_create_cached,
//     hb_ft_face_create_referenced,
    hb_ft_font_create,
//     hb_ft_font_create_referenced,
//     hb_ft_font_get_face,
//     hb_ft_font_set_load_flags,
//     hb_ft_font_get_load_flags,
//     hb_ft_font_set_funcs,
);
