module dgt.bindings.harfbuzz.load;

import dgt.bindings.harfbuzz.symbols;
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
    version (Windows)
    {
        auto defaultLibNames = ["harfbuzz.dll", "libharfbuzz.dll", "libharfbuzz-0.dll"];
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

shared static this()
{
    harfbuzzLoader = new HarfbuzzLoader();
}

shared static ~this()
{
    //harfbuzzLoader.unload();
}

private __gshared HarfbuzzLoader harfbuzzLoader;


private class HarfbuzzLoader : SharedLibLoader
{
    override void bindSymbols()
    {
        bind!(hb_blob_create)();
        bind!(hb_blob_create_sub_blob)();
        bind!(hb_blob_get_empty)();
        bind!(hb_blob_reference)();
        bind!(hb_blob_destroy)();
        bind!(hb_blob_set_user_data)();
        bind!(hb_blob_get_user_data)();
        bind!(hb_blob_make_immutable)();
        bind!(hb_blob_is_immutable)();
        bind!(hb_blob_get_length)();
        bind!(hb_blob_get_data)();
        bind!(hb_blob_get_data_writable)();

        bind!(hb_segment_properties_equal)();
        bind!(hb_segment_properties_hash)();
        bind!(hb_buffer_create)();
        bind!(hb_buffer_get_empty)();
        bind!(hb_buffer_reference)();
        bind!(hb_buffer_destroy)();
        bind!(hb_buffer_set_user_data)();
        bind!(hb_buffer_get_user_data)();
        bind!(hb_buffer_set_content_type)();
        bind!(hb_buffer_get_content_type)();
        bind!(hb_buffer_set_unicode_funcs)();
        bind!(hb_buffer_get_unicode_funcs)();
        bind!(hb_buffer_set_direction)();
        bind!(hb_buffer_get_direction)();
        bind!(hb_buffer_set_script)();
        bind!(hb_buffer_get_script)();
        bind!(hb_buffer_set_language)();
        bind!(hb_buffer_get_language)();
        bind!(hb_buffer_set_segment_properties)();
        bind!(hb_buffer_get_segment_properties)();
        bind!(hb_buffer_guess_segment_properties)();
        bind!(hb_buffer_set_flags)();
        bind!(hb_buffer_get_flags)();
        bind!(hb_buffer_set_cluster_level)();
        bind!(hb_buffer_get_cluster_level)();
        bind!(hb_buffer_set_replacement_codepoint)();
        bind!(hb_buffer_get_replacement_codepoint)();
        bind!(hb_buffer_reset)();
        bind!(hb_buffer_clear_contents)();
        bind!(hb_buffer_pre_allocate)();
        bind!(hb_buffer_allocation_successful)();
        bind!(hb_buffer_reverse)();
        bind!(hb_buffer_reverse_range)();
        bind!(hb_buffer_reverse_clusters)();
        bind!(hb_buffer_add)();
        bind!(hb_buffer_add_utf8)();
        bind!(hb_buffer_add_utf16)();
        bind!(hb_buffer_add_utf32)();
        bind!(hb_buffer_add_latin1)();
        bind!(hb_buffer_add_codepoints)();
        bind!(hb_buffer_set_length)();
        bind!(hb_buffer_get_length)();
        bind!(hb_buffer_get_glyph_infos)();
        bind!(hb_buffer_get_glyph_positions)();
        bind!(hb_buffer_normalize_glyphs)();
        bind!(hb_buffer_serialize_format_from_string)();
        bind!(hb_buffer_serialize_format_to_string)();
        bind!(hb_buffer_serialize_list_formats)();
        bind!(hb_buffer_serialize_glyphs)();
        bind!(hb_buffer_deserialize_glyphs)();

        bind!(hb_buffer_set_message_func)();

        bind!(hb_tag_from_string)();
        bind!(hb_tag_to_string)();
        bind!(hb_direction_from_string)();
        bind!(hb_direction_to_string)();
        bind!(hb_language_from_string)();
        bind!(hb_language_to_string)();
        bind!(hb_language_get_default)();
        bind!(hb_script_from_iso15924_tag)();
        bind!(hb_script_from_string)();
        bind!(hb_script_to_iso15924_tag)();
        bind!(hb_script_get_horizontal_direction)();

        bind!(hb_face_create)();
        bind!(hb_face_create_for_tables)();
        bind!(hb_face_get_empty)();
        bind!(hb_face_reference)();
        bind!(hb_face_destroy)();
        bind!(hb_face_set_user_data)();
        bind!(hb_face_get_user_data)();
        bind!(hb_face_make_immutable)();
        bind!(hb_face_is_immutable)();
        bind!(hb_face_reference_table)();
        bind!(hb_face_reference_blob)();
        bind!(hb_face_set_index)();
        bind!(hb_face_get_index)();
        bind!(hb_face_set_upem)();
        bind!(hb_face_get_upem)();
        bind!(hb_face_set_glyph_count)();
        bind!(hb_face_get_glyph_count)();

        bind!(hb_font_funcs_create)();
        bind!(hb_font_funcs_get_empty)();
        bind!(hb_font_funcs_reference)();
        bind!(hb_font_funcs_destroy)();
        bind!(hb_font_funcs_set_user_data)();
        bind!(hb_font_funcs_get_user_data)();
        bind!(hb_font_funcs_make_immutable)();
        bind!(hb_font_funcs_is_immutable)();
        bind!(hb_font_funcs_set_font_h_extents_func)();
        bind!(hb_font_funcs_set_font_v_extents_func)();
        bind!(hb_font_funcs_set_nominal_glyph_func)();
        bind!(hb_font_funcs_set_variation_glyph_func)();
        bind!(hb_font_funcs_set_glyph_h_advance_func)();
        bind!(hb_font_funcs_set_glyph_v_advance_func)();
        bind!(hb_font_funcs_set_glyph_h_origin_func)();
        bind!(hb_font_funcs_set_glyph_v_origin_func)();
        bind!(hb_font_funcs_set_glyph_h_kerning_func)();
        bind!(hb_font_funcs_set_glyph_v_kerning_func)();
        bind!(hb_font_funcs_set_glyph_extents_func)();
        bind!(hb_font_funcs_set_glyph_contour_point_func)();
        bind!(hb_font_funcs_set_glyph_name_func)();
        bind!(hb_font_funcs_set_glyph_from_name_func)();
        bind!(hb_font_get_h_extents)();
        bind!(hb_font_get_v_extents)();
        bind!(hb_font_get_nominal_glyph)();
        bind!(hb_font_get_variation_glyph)();
        bind!(hb_font_get_glyph_h_advance)();
        bind!(hb_font_get_glyph_v_advance)();
        bind!(hb_font_get_glyph_h_origin)();
        bind!(hb_font_get_glyph_v_origin)();
        bind!(hb_font_get_glyph_h_kerning)();
        bind!(hb_font_get_glyph_v_kerning)();
        bind!(hb_font_get_glyph_extents)();
        bind!(hb_font_get_glyph_contour_point)();
        bind!(hb_font_get_glyph_name)();
        bind!(hb_font_get_glyph_from_name)();
        bind!(hb_font_get_glyph)();
        bind!(hb_font_get_extents_for_direction)();
        bind!(hb_font_get_glyph_advance_for_direction)();
        bind!(hb_font_get_glyph_origin_for_direction)();
        bind!(hb_font_add_glyph_origin_for_direction)();
        bind!(hb_font_subtract_glyph_origin_for_direction)();
        bind!(hb_font_get_glyph_kerning_for_direction)();
        bind!(hb_font_get_glyph_extents_for_origin)();
        bind!(hb_font_get_glyph_contour_point_for_origin)();
        bind!(hb_font_glyph_to_string)();
        bind!(hb_font_glyph_from_string)();
        bind!(hb_font_create)();
        bind!(hb_font_create_sub_font)();
        bind!(hb_font_get_empty)();
        bind!(hb_font_reference)();
        bind!(hb_font_destroy)();
        bind!(hb_font_set_user_data)();
        bind!(hb_font_get_user_data)();
        bind!(hb_font_make_immutable)();
        bind!(hb_font_is_immutable)();
        bind!(hb_font_set_parent)();
        bind!(hb_font_get_parent)();
        bind!(hb_font_get_face)();
        bind!(hb_font_set_funcs)();
        bind!(hb_font_set_funcs_data)();
        bind!(hb_font_set_scale)();
        bind!(hb_font_get_scale)();
        bind!(hb_font_set_ppem)();
        bind!(hb_font_get_ppem)();
        bind!(hb_font_set_var_coords_normalized)(Yes.optional);

        bind!(hb_set_create)();
        bind!(hb_set_get_empty)();
        bind!(hb_set_reference)();
        bind!(hb_set_destroy)();
        bind!(hb_set_set_user_data)();
        bind!(hb_set_get_user_data)();
        bind!(hb_set_allocation_successful)();
        bind!(hb_set_clear)();
        bind!(hb_set_is_empty)();
        bind!(hb_set_has)();
        bind!(hb_set_add)();
        bind!(hb_set_add_range)();
        bind!(hb_set_del)();
        bind!(hb_set_del_range)();
        bind!(hb_set_is_equal)();
        bind!(hb_set_set)();
        bind!(hb_set_union)();
        bind!(hb_set_intersect)();
        bind!(hb_set_subtract)();
        bind!(hb_set_symmetric_difference)();
        bind!(hb_set_invert)();
        bind!(hb_set_get_population)();
        bind!(hb_set_get_min)();
        bind!(hb_set_get_max)();
        bind!(hb_set_next)();
        bind!(hb_set_next_range)();

        bind!(hb_feature_from_string)();
        bind!(hb_feature_to_string)();
        bind!(hb_shape)();
        bind!(hb_shape_full)();
        bind!(hb_shape_list_shapers)();

        bind!(hb_shape_plan_create)();
        bind!(hb_shape_plan_create_cached)();
        bind!(hb_shape_plan_create2)(Yes.optional);
        bind!(hb_shape_plan_create_cached2)(Yes.optional);
        bind!(hb_shape_plan_get_empty)();
        bind!(hb_shape_plan_reference)();
        bind!(hb_shape_plan_destroy)();
        bind!(hb_shape_plan_set_user_data)();
        bind!(hb_shape_plan_get_user_data)();
        bind!(hb_shape_plan_execute)();
        bind!(hb_shape_plan_get_shaper)();

        bind!(hb_unicode_funcs_get_default)();
        bind!(hb_unicode_funcs_create)();
        bind!(hb_unicode_funcs_get_empty)();
        bind!(hb_unicode_funcs_reference)();
        bind!(hb_unicode_funcs_destroy)();
        bind!(hb_unicode_funcs_set_user_data)();
        bind!(hb_unicode_funcs_get_user_data)();
        bind!(hb_unicode_funcs_make_immutable)();
        bind!(hb_unicode_funcs_is_immutable)();
        bind!(hb_unicode_funcs_get_parent)();
        bind!(hb_unicode_funcs_set_combining_class_func)();
        bind!(hb_unicode_funcs_set_eastasian_width_func)();
        bind!(hb_unicode_funcs_set_general_category_func)();
        bind!(hb_unicode_funcs_set_mirroring_func)();
        bind!(hb_unicode_funcs_set_script_func)();
        bind!(hb_unicode_funcs_set_compose_func)();
        bind!(hb_unicode_funcs_set_decompose_func)();
        bind!(hb_unicode_funcs_set_decompose_compatibility_func)();
        bind!(hb_unicode_combining_class)();
        bind!(hb_unicode_eastasian_width)();
        bind!(hb_unicode_general_category)();
        bind!(hb_unicode_mirroring)();
        bind!(hb_unicode_script)();
        bind!(hb_unicode_compose)();
        bind!(hb_unicode_decompose)();
        bind!(hb_unicode_decompose_compatibility)();

        bind!(hb_version)();
        bind!(hb_version_string)();
        bind!(hb_version_atleast)();

        bind!(hb_ft_face_create)();
        bind!(hb_ft_face_create_cached)();
        bind!(hb_ft_face_create_referenced)();
        bind!(hb_ft_font_create)();
        bind!(hb_ft_font_create_referenced)();
        bind!(hb_ft_font_get_face)();
        bind!(hb_ft_font_set_load_flags)();
        bind!(hb_ft_font_get_load_flags)();
        bind!(hb_ft_font_set_funcs)();
    }
}
