module dgt.bindings.harfbuzz.symbols;

import dgt.bindings.harfbuzz.definitions;
import dgt.bindings;

import derelict.freetype.ft;

// // blob

// __gshared Symbol!(hb_blob_t*, const(char)*, uint, hb_memory_mode_t, void*, hb_destroy_func_t) hb_blob_create;

// __gshared Symbol!(hb_blob_t*, hb_blob_t*, uint, uint) hb_blob_create_sub_blob;

// __gshared Symbol!(hb_blob_t*) hb_blob_get_empty;

// __gshared Symbol!(hb_blob_t*, hb_blob_t*) hb_blob_reference;

// __gshared Symbol!(void, hb_blob_t*) hb_blob_destroy;

// __gshared Symbol!(hb_bool_t, hb_blob_t*, hb_user_data_key_t*, void*,
//         hb_destroy_func_t, hb_bool_t) hb_blob_set_user_data;

// __gshared Symbol!(void*, hb_blob_t*, hb_user_data_key_t*) hb_blob_get_user_data;

// __gshared Symbol!(void, hb_blob_t*) hb_blob_make_immutable;

// __gshared Symbol!(hb_bool_t, hb_blob_t*) hb_blob_is_immutable;

// __gshared Symbol!(uint, hb_blob_t*) hb_blob_get_length;

// __gshared Symbol!(const(char)*, hb_blob_t*, uint*) hb_blob_get_data;

// __gshared Symbol!(char*, hb_blob_t*, uint*) hb_blob_get_data_writable;

// // buffer

// __gshared Symbol!(hb_bool_t, const(hb_segment_properties_t)*, const(hb_segment_properties_t)*) hb_segment_properties_equal;

// __gshared Symbol!(uint, const(hb_segment_properties_t)*) hb_segment_properties_hash;

// __gshared Symbol!(hb_buffer_t*) hb_buffer_create;

// __gshared Symbol!(hb_buffer_t*) hb_buffer_get_empty;

// __gshared Symbol!(hb_buffer_t*, hb_buffer_t*) hb_buffer_reference;

// __gshared Symbol!(void, hb_buffer_t*) hb_buffer_destroy;

// __gshared Symbol!(hb_bool_t, hb_buffer_t*, hb_user_data_key_t*, void*,
//         hb_destroy_func_t, hb_bool_t) hb_buffer_set_user_data;

// __gshared Symbol!(void*, hb_buffer_t*, hb_user_data_key_t*) hb_buffer_get_user_data;

// __gshared Symbol!(void, hb_buffer_t*, hb_buffer_content_type_t) hb_buffer_set_content_type;

// __gshared Symbol!(hb_buffer_content_type_t, hb_buffer_t*) hb_buffer_get_content_type;

// __gshared Symbol!(void, hb_buffer_t*, hb_unicode_funcs_t*) hb_buffer_set_unicode_funcs;

// __gshared Symbol!(hb_unicode_funcs_t*, hb_buffer_t*) hb_buffer_get_unicode_funcs;

// __gshared Symbol!(void, hb_buffer_t*, hb_direction_t) hb_buffer_set_direction;

// __gshared Symbol!(hb_direction_t, hb_buffer_t*) hb_buffer_get_direction;

// __gshared Symbol!(void, hb_buffer_t*, hb_script_t) hb_buffer_set_script;

// __gshared Symbol!(hb_script_t, hb_buffer_t*) hb_buffer_get_script;

// __gshared Symbol!(void, hb_buffer_t*, hb_language_t) hb_buffer_set_language;

// __gshared Symbol!(hb_language_t, hb_buffer_t*) hb_buffer_get_language;

// __gshared Symbol!(void, hb_buffer_t*, const(hb_segment_properties_t)*) hb_buffer_set_segment_properties;

// __gshared Symbol!(void, hb_buffer_t*, hb_segment_properties_t*) hb_buffer_get_segment_properties;

// __gshared Symbol!(void, hb_buffer_t*) hb_buffer_guess_segment_properties;

// __gshared Symbol!(void, hb_buffer_t*, hb_buffer_flags_t) hb_buffer_set_flags;

// __gshared Symbol!(hb_buffer_flags_t, hb_buffer_t*) hb_buffer_get_flags;

// __gshared Symbol!(void, hb_buffer_t*, hb_buffer_cluster_level_t) hb_buffer_set_cluster_level;

// __gshared Symbol!(hb_buffer_cluster_level_t, hb_buffer_t*) hb_buffer_get_cluster_level;

// __gshared Symbol!(void, hb_buffer_t*, hb_codepoint_t) hb_buffer_set_replacement_codepoint;

// __gshared Symbol!(hb_codepoint_t, hb_buffer_t*) hb_buffer_get_replacement_codepoint;

// __gshared Symbol!(void, hb_buffer_t*) hb_buffer_reset;

// __gshared Symbol!(void, hb_buffer_t*) hb_buffer_clear_contents;

// __gshared Symbol!(hb_bool_t, hb_buffer_t*, uint) hb_buffer_pre_allocate;

// __gshared Symbol!(hb_bool_t, hb_buffer_t*) hb_buffer_allocation_successful;

// __gshared Symbol!(void, hb_buffer_t*) hb_buffer_reverse;

// __gshared Symbol!(void, hb_buffer_t*, uint, uint) hb_buffer_reverse_range;

// __gshared Symbol!(void, hb_buffer_t*) hb_buffer_reverse_clusters;

// __gshared Symbol!(void, hb_buffer_t*, hb_codepoint_t, uint) hb_buffer_add;

// __gshared Symbol!(void, hb_buffer_t*, const(char)*, int, uint, int) hb_buffer_add_utf8;

// __gshared Symbol!(void, hb_buffer_t*, const(ushort)*, int, uint, int) hb_buffer_add_utf16;

// __gshared Symbol!(void, hb_buffer_t*, const(uint)*, int, uint, int) hb_buffer_add_utf32;

// __gshared Symbol!(void, hb_buffer_t*, const(ubyte)*, int, uint, int) hb_buffer_add_latin1;

// __gshared Symbol!(void, hb_buffer_t*, const(hb_codepoint_t)*, int, uint, int) hb_buffer_add_codepoints;

// __gshared Symbol!(hb_bool_t, hb_buffer_t*, uint) hb_buffer_set_length;

// __gshared Symbol!(uint, hb_buffer_t*) hb_buffer_get_length;

// __gshared Symbol!(hb_glyph_info_t*, hb_buffer_t*, uint*) hb_buffer_get_glyph_infos;

// __gshared Symbol!(hb_glyph_position_t*, hb_buffer_t*, uint*) hb_buffer_get_glyph_positions;

// __gshared Symbol!(void, hb_buffer_t*) hb_buffer_normalize_glyphs;

// __gshared Symbol!(hb_buffer_serialize_format_t, const(char)*, int) hb_buffer_serialize_format_from_string;

// __gshared Symbol!(const(char)*, hb_buffer_serialize_format_t) hb_buffer_serialize_format_to_string;

// __gshared Symbol!(const(char)**) hb_buffer_serialize_list_formats;

// __gshared Symbol!(uint, hb_buffer_t*, uint, uint, char*, uint, uint*,
//         hb_font_t*, hb_buffer_serialize_format_t, hb_buffer_serialize_flags_t) hb_buffer_serialize_glyphs;

// __gshared Symbol!(hb_bool_t, hb_buffer_t*, const(char)*, int,
//         const(char)**, hb_font_t*, hb_buffer_serialize_format_t) hb_buffer_deserialize_glyphs;

// // debug

// alias hb_buffer_message_func_t = hb_bool_t function(hb_buffer_t* buffer,
//         hb_font_t* font, const(char)* message, void* user_data);

// __gshared Symbol!(void, hb_buffer_t*, hb_buffer_message_func_t, void*, hb_destroy_func_t) hb_buffer_set_message_func;

// // common

// /* len=-1 means str is NUL-terminated. */
// __gshared Symbol!(hb_tag_t, const(char)*, int) hb_tag_from_string;

// /* buf should have 4 bytes. */
// __gshared Symbol!(void, hb_tag_t, char*) hb_tag_to_string;

// /* len=-1 means str is NUL-terminated */
// __gshared Symbol!(hb_direction_t, const(char)*, int) hb_direction_from_string;

// __gshared Symbol!(const(char)*, hb_direction_t) hb_direction_to_string;

// __gshared Symbol!(hb_language_t, const(char)*, int) hb_language_from_string;

// __gshared Symbol!(const(char)*, hb_language_t) hb_language_to_string;

// enum HB_LANGUAGE_INVALID = cast(hb_language_t) null;

// __gshared Symbol!(hb_language_t) hb_language_get_default;

// __gshared Symbol!(hb_script_t, hb_tag_t) hb_script_from_iso15924_tag;

// __gshared Symbol!(hb_script_t, const(char)*, int) hb_script_from_string;

// __gshared Symbol!(hb_tag_t, hb_script_t) hb_script_to_iso15924_tag;

// __gshared Symbol!(hb_direction_t, hb_script_t) hb_script_get_horizontal_direction;

// // face

// __gshared Symbol!(hb_face_t*, hb_blob_t*, uint) hb_face_create;

// __gshared Symbol!(hb_face_t*, hb_reference_table_func_t, void*, hb_destroy_func_t) hb_face_create_for_tables;

// __gshared Symbol!(hb_face_t*) hb_face_get_empty;

// __gshared Symbol!(hb_face_t*, hb_face_t*) hb_face_reference;

// __gshared Symbol!(void, hb_face_t*) hb_face_destroy;

// __gshared Symbol!(hb_bool_t, hb_face_t*, hb_user_data_key_t*, void*,
//         hb_destroy_func_t, hb_bool_t) hb_face_set_user_data;

// __gshared Symbol!(void*, hb_face_t*, hb_user_data_key_t*) hb_face_get_user_data;

// __gshared Symbol!(void, hb_face_t*) hb_face_make_immutable;

// __gshared Symbol!(hb_bool_t, hb_face_t*) hb_face_is_immutable;

// __gshared Symbol!(hb_blob_t*, hb_face_t*, hb_tag_t) hb_face_reference_table;

// __gshared Symbol!(hb_blob_t*, hb_face_t*) hb_face_reference_blob;

// __gshared Symbol!(void, hb_face_t*, uint) hb_face_set_index;

// __gshared Symbol!(uint, hb_face_t*) hb_face_get_index;

// __gshared Symbol!(void, hb_face_t*, uint) hb_face_set_upem;

// __gshared Symbol!(uint, hb_face_t*) hb_face_get_upem;

// __gshared Symbol!(void, hb_face_t*, uint) hb_face_set_glyph_count;

// __gshared Symbol!(uint, hb_face_t*) hb_face_get_glyph_count;

// // font

// __gshared Symbol!(hb_font_funcs_t*) hb_font_funcs_create;

// __gshared Symbol!(hb_font_funcs_t*) hb_font_funcs_get_empty;

// __gshared Symbol!(hb_font_funcs_t*, hb_font_funcs_t*) hb_font_funcs_reference;

// __gshared Symbol!(void, hb_font_funcs_t*) hb_font_funcs_destroy;

// __gshared Symbol!(hb_bool_t, hb_font_funcs_t*, hb_user_data_key_t*, void*,
//         hb_destroy_func_t, hb_bool_t) hb_font_funcs_set_user_data;

// __gshared Symbol!(void*, hb_font_funcs_t*, hb_user_data_key_t*) hb_font_funcs_get_user_data;

// __gshared Symbol!(void, hb_font_funcs_t*) hb_font_funcs_make_immutable;

// __gshared Symbol!(hb_bool_t, hb_font_funcs_t*) hb_font_funcs_is_immutable;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_font_h_extents_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_font_h_extents_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_font_v_extents_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_font_v_extents_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_nominal_glyph_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_nominal_glyph_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_variation_glyph_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_variation_glyph_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_glyph_h_advance_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_glyph_h_advance_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_glyph_v_advance_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_glyph_v_advance_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_glyph_h_origin_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_glyph_h_origin_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_glyph_v_origin_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_glyph_v_origin_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_glyph_h_kerning_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_glyph_h_kerning_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_glyph_v_kerning_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_glyph_v_kerning_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_glyph_extents_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_glyph_extents_func;

// __gshared Symbol!(void, hb_font_funcs_t*,
//         hb_font_get_glyph_contour_point_func_t, void*, hb_destroy_func_t) hb_font_funcs_set_glyph_contour_point_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_glyph_name_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_glyph_name_func;

// __gshared Symbol!(void, hb_font_funcs_t*, hb_font_get_glyph_from_name_func_t,
//         void*, hb_destroy_func_t) hb_font_funcs_set_glyph_from_name_func;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_font_extents_t*) hb_font_get_h_extents;
// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_font_extents_t*) hb_font_get_v_extents;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_codepoint_t, hb_codepoint_t*) hb_font_get_nominal_glyph;
// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_codepoint_t, hb_codepoint_t, hb_codepoint_t*) hb_font_get_variation_glyph;

// __gshared Symbol!(hb_position_t, hb_font_t*, hb_codepoint_t) hb_font_get_glyph_h_advance;
// __gshared Symbol!(hb_position_t, hb_font_t*, hb_codepoint_t) hb_font_get_glyph_v_advance;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_codepoint_t, hb_position_t*, hb_position_t*) hb_font_get_glyph_h_origin;
// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_codepoint_t, hb_position_t*, hb_position_t*) hb_font_get_glyph_v_origin;

// __gshared Symbol!(hb_position_t, hb_font_t*, hb_codepoint_t, hb_codepoint_t) hb_font_get_glyph_h_kerning;
// __gshared Symbol!(hb_position_t, hb_font_t*, hb_codepoint_t, hb_codepoint_t) hb_font_get_glyph_v_kerning;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_codepoint_t, hb_glyph_extents_t*) hb_font_get_glyph_extents;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_codepoint_t, uint, hb_position_t*, hb_position_t*) hb_font_get_glyph_contour_point;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_codepoint_t, char*, uint) hb_font_get_glyph_name;
// __gshared Symbol!(hb_bool_t, hb_font_t*, const(char)*, int, /* -1 means nul-terminated */
//         hb_codepoint_t*) hb_font_get_glyph_from_name;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_codepoint_t, hb_codepoint_t, hb_codepoint_t*) hb_font_get_glyph;

// __gshared Symbol!(void, hb_font_t*, hb_direction_t, hb_font_extents_t*) hb_font_get_extents_for_direction;
// __gshared Symbol!(void, hb_font_t*, hb_codepoint_t, hb_direction_t,
//         hb_position_t*, hb_position_t*) hb_font_get_glyph_advance_for_direction;
// __gshared Symbol!(void, hb_font_t*, hb_codepoint_t, hb_direction_t,
//         hb_position_t*, hb_position_t*) hb_font_get_glyph_origin_for_direction;
// __gshared Symbol!(void, hb_font_t*, hb_codepoint_t, hb_direction_t,
//         hb_position_t*, hb_position_t*) hb_font_add_glyph_origin_for_direction;
// __gshared Symbol!(void, hb_font_t*, hb_codepoint_t, hb_direction_t,
//         hb_position_t*, hb_position_t*) hb_font_subtract_glyph_origin_for_direction;

// __gshared Symbol!(void, hb_font_t*, hb_codepoint_t, hb_codepoint_t,
//         hb_direction_t, hb_position_t*, hb_position_t*) hb_font_get_glyph_kerning_for_direction;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_codepoint_t, hb_direction_t, hb_glyph_extents_t*) hb_font_get_glyph_extents_for_origin;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_codepoint_t, uint, hb_direction_t,
//         hb_position_t*, hb_position_t*) hb_font_get_glyph_contour_point_for_origin;

// __gshared Symbol!(void, hb_font_t*, hb_codepoint_t, char*, uint) hb_font_glyph_to_string;

// __gshared Symbol!(hb_bool_t, hb_font_t*, const(char)*, int, /* -1 means nul-terminated */
//         hb_codepoint_t*) hb_font_glyph_from_string;

// __gshared Symbol!(hb_font_t*, hb_face_t*) hb_font_create;

// __gshared Symbol!(hb_font_t*, hb_font_t*) hb_font_create_sub_font;

// __gshared Symbol!(hb_font_t*) hb_font_get_empty;

// __gshared Symbol!(hb_font_t*, hb_font_t*) hb_font_reference;

// __gshared Symbol!(void, hb_font_t*) hb_font_destroy;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_user_data_key_t*, void*,
//         hb_destroy_func_t, hb_bool_t) hb_font_set_user_data;

// __gshared Symbol!(void*, hb_font_t*, hb_user_data_key_t*) hb_font_get_user_data;

// __gshared Symbol!(void, hb_font_t*) hb_font_make_immutable;

// __gshared Symbol!(hb_bool_t, hb_font_t*) hb_font_is_immutable;

// __gshared Symbol!(void, hb_font_t*, hb_font_t*) hb_font_set_parent;

// __gshared Symbol!(hb_font_t*, hb_font_t*) hb_font_get_parent;

// __gshared Symbol!(hb_face_t*, hb_font_t*) hb_font_get_face;

// __gshared Symbol!(void, hb_font_t*, hb_font_funcs_t*, void*, hb_destroy_func_t) hb_font_set_funcs;

// __gshared Symbol!(void, hb_font_t*, void*, hb_destroy_func_t) hb_font_set_funcs_data;

// __gshared Symbol!(void, hb_font_t*, int, int) hb_font_set_scale;

// __gshared Symbol!(void, hb_font_t*, int*, int*) hb_font_get_scale;

// __gshared Symbol!(void, hb_font_t*, uint, uint) hb_font_set_ppem;

// __gshared Symbol!(void, hb_font_t*, uint*, uint*) hb_font_get_ppem;

// __gshared Symbol!(void, hb_font_t*, int*, uint) hb_font_set_var_coords_normalized;

// // set

// __gshared Symbol!(hb_set_t*) hb_set_create;

// __gshared Symbol!(hb_set_t*) hb_set_get_empty;

// __gshared Symbol!(hb_set_t*, hb_set_t*) hb_set_reference;

// __gshared Symbol!(void, hb_set_t*) hb_set_destroy;

// __gshared Symbol!(hb_bool_t, hb_set_t*, hb_user_data_key_t*, void*,
//         hb_destroy_func_t, hb_bool_t) hb_set_set_user_data;

// __gshared Symbol!(void*, hb_set_t*, hb_user_data_key_t*) hb_set_get_user_data;

// __gshared Symbol!(hb_bool_t, const(hb_set_t)*) hb_set_allocation_successful;

// __gshared Symbol!(void, hb_set_t*) hb_set_clear;

// __gshared Symbol!(hb_bool_t, const(hb_set_t)*) hb_set_is_empty;

// __gshared Symbol!(hb_bool_t, const(hb_set_t)*, hb_codepoint_t) hb_set_has;

// /* Right now limited to 16-bit integers.  Eventually will do full codepoint range, sans -1
//  * which we will use as a sentinel. */
// __gshared Symbol!(void, hb_set_t*, hb_codepoint_t) hb_set_add;

// __gshared Symbol!(void, hb_set_t*, hb_codepoint_t, hb_codepoint_t) hb_set_add_range;

// __gshared Symbol!(void, hb_set_t*, hb_codepoint_t) hb_set_del;

// __gshared Symbol!(void, hb_set_t*, hb_codepoint_t, hb_codepoint_t) hb_set_del_range;

// __gshared Symbol!(hb_bool_t, const(hb_set_t)*, const(hb_set_t)*) hb_set_is_equal;

// __gshared Symbol!(void, hb_set_t*, const(hb_set_t)*) hb_set_set;

// __gshared Symbol!(void, hb_set_t*, const(hb_set_t)*) hb_set_union;

// __gshared Symbol!(void, hb_set_t*, const(hb_set_t)*) hb_set_intersect;

// __gshared Symbol!(void, hb_set_t*, const(hb_set_t)*) hb_set_subtract;

// __gshared Symbol!(void, hb_set_t*, const(hb_set_t)*) hb_set_symmetric_difference;

// __gshared Symbol!(void, hb_set_t*) hb_set_invert;

// __gshared Symbol!(uint, const(hb_set_t)*) hb_set_get_population;

// /* Returns -1 if set empty. */
// __gshared Symbol!(hb_codepoint_t, const(hb_set_t)*) hb_set_get_min;

// /* Returns -1 if set empty. */
// __gshared Symbol!(hb_codepoint_t, const(hb_set_t)*) hb_set_get_max;

// /* Pass -1 in to get started. */
// __gshared Symbol!(hb_bool_t, const(hb_set_t)*, hb_codepoint_t*) hb_set_next;

// /* Pass -1 for first and last to get started. */
// __gshared Symbol!(hb_bool_t, const(hb_set_t)*, hb_codepoint_t*, hb_codepoint_t*) hb_set_next_range;

// // shape

// __gshared Symbol!(hb_bool_t, const(char)*, int, hb_feature_t*) hb_feature_from_string;

// __gshared Symbol!(void, hb_feature_t*, char*, uint) hb_feature_to_string;

// __gshared Symbol!(void, hb_font_t*, hb_buffer_t*, const hb_feature_t*, uint) hb_shape;

// __gshared Symbol!(hb_bool_t, hb_font_t*, hb_buffer_t*, const(hb_feature_t)*,
//         uint, const(char*)*) hb_shape_full;

// __gshared Symbol!(const(char)**) hb_shape_list_shapers;

// // shape-plan

// __gshared Symbol!(hb_shape_plan_t*, hb_face_t*,
//         const(hb_segment_properties_t)*, const(hb_feature_t)*, uint, const(char*)*) hb_shape_plan_create;

// __gshared Symbol!(hb_shape_plan_t*, hb_face_t*,
//         const(hb_segment_properties_t)*, const(hb_feature_t)*, uint, const(char*)*) hb_shape_plan_create_cached;

// __gshared Symbol!(hb_shape_plan_t*, hb_face_t*, const(hb_segment_properties_t)*,
//         const(hb_feature_t)*, uint, const(int)*, uint, const(char*)*) hb_shape_plan_create2;

// __gshared Symbol!(hb_shape_plan_t*, hb_face_t*, const(hb_segment_properties_t)*,
//         const(hb_feature_t)*, uint, const(int)*, uint, const(char*)*) hb_shape_plan_create_cached2;

// __gshared Symbol!(hb_shape_plan_t*) hb_shape_plan_get_empty;

// __gshared Symbol!(hb_shape_plan_t*, hb_shape_plan_t*) hb_shape_plan_reference;

// __gshared Symbol!(void, hb_shape_plan_t*) hb_shape_plan_destroy;

// __gshared Symbol!(hb_bool_t, hb_shape_plan_t*, hb_user_data_key_t*, void*,
//         hb_destroy_func_t, hb_bool_t) hb_shape_plan_set_user_data;

// __gshared Symbol!(void*, hb_shape_plan_t*, hb_user_data_key_t*) hb_shape_plan_get_user_data;

// __gshared Symbol!(hb_bool_t, hb_shape_plan_t*, hb_font_t*, hb_buffer_t*,
//         const(hb_feature_t)*, uint) hb_shape_plan_execute;

// __gshared Symbol!(const(char)*, hb_shape_plan_t*) hb_shape_plan_get_shaper;

// // unicode

// __gshared Symbol!(hb_unicode_funcs_t*) hb_unicode_funcs_get_default;

// __gshared Symbol!(hb_unicode_funcs_t*, hb_unicode_funcs_t*) hb_unicode_funcs_create;

// __gshared Symbol!(hb_unicode_funcs_t*) hb_unicode_funcs_get_empty;

// __gshared Symbol!(hb_unicode_funcs_t*, hb_unicode_funcs_t*) hb_unicode_funcs_reference;

// __gshared Symbol!(void, hb_unicode_funcs_t*) hb_unicode_funcs_destroy;

// __gshared Symbol!(hb_bool_t, hb_unicode_funcs_t*, hb_user_data_key_t*,
//         void*, hb_destroy_func_t, hb_bool_t) hb_unicode_funcs_set_user_data;

// __gshared Symbol!(void*, hb_unicode_funcs_t*, hb_user_data_key_t*) hb_unicode_funcs_get_user_data;

// __gshared Symbol!(void, hb_unicode_funcs_t*) hb_unicode_funcs_make_immutable;

// __gshared Symbol!(hb_bool_t, hb_unicode_funcs_t*) hb_unicode_funcs_is_immutable;

// __gshared Symbol!(hb_unicode_funcs_t*, hb_unicode_funcs_t*) hb_unicode_funcs_get_parent;

// __gshared Symbol!(void, hb_unicode_funcs_t*,
//         hb_unicode_combining_class_func_t, void*, hb_destroy_func_t) hb_unicode_funcs_set_combining_class_func;

// __gshared Symbol!(void, hb_unicode_funcs_t*,
//         hb_unicode_eastasian_width_func_t, void*, hb_destroy_func_t) hb_unicode_funcs_set_eastasian_width_func;

// __gshared Symbol!(void, hb_unicode_funcs_t*,
//         hb_unicode_general_category_func_t, void*, hb_destroy_func_t) hb_unicode_funcs_set_general_category_func;

// __gshared Symbol!(void, hb_unicode_funcs_t*, hb_unicode_mirroring_func_t,
//         void*, hb_destroy_func_t) hb_unicode_funcs_set_mirroring_func;

// __gshared Symbol!(void, hb_unicode_funcs_t*, hb_unicode_script_func_t, void*, hb_destroy_func_t) hb_unicode_funcs_set_script_func;

// __gshared Symbol!(void, hb_unicode_funcs_t*, hb_unicode_compose_func_t,
//         void*, hb_destroy_func_t) hb_unicode_funcs_set_compose_func;

// __gshared Symbol!(void, hb_unicode_funcs_t*, hb_unicode_decompose_func_t,
//         void*, hb_destroy_func_t) hb_unicode_funcs_set_decompose_func;

// __gshared Symbol!(void, hb_unicode_funcs_t*,
//         hb_unicode_decompose_compatibility_func_t, void*, hb_destroy_func_t) hb_unicode_funcs_set_decompose_compatibility_func;

// __gshared Symbol!(hb_unicode_combining_class_t, hb_unicode_funcs_t*, hb_codepoint_t) hb_unicode_combining_class;

// __gshared Symbol!(uint, hb_unicode_funcs_t*, hb_codepoint_t) hb_unicode_eastasian_width;

// __gshared Symbol!(hb_unicode_general_category_t, hb_unicode_funcs_t*, hb_codepoint_t) hb_unicode_general_category;

// __gshared Symbol!(hb_codepoint_t, hb_unicode_funcs_t*, hb_codepoint_t) hb_unicode_mirroring;

// __gshared Symbol!(hb_script_t, hb_unicode_funcs_t*, hb_codepoint_t) hb_unicode_script;

// __gshared Symbol!(hb_bool_t, hb_unicode_funcs_t*, hb_codepoint_t,
//         hb_codepoint_t, hb_codepoint_t*) hb_unicode_compose;

// __gshared Symbol!(hb_bool_t, hb_unicode_funcs_t*, hb_codepoint_t,
//         hb_codepoint_t*, hb_codepoint_t*) hb_unicode_decompose;

// __gshared Symbol!(uint, hb_unicode_funcs_t*, hb_codepoint_t, hb_codepoint_t*) hb_unicode_decompose_compatibility;

// // version

// __gshared Symbol!(void, uint*, uint*, uint*) hb_version;

// __gshared Symbol!(const(char)*) hb_version_string;

// __gshared Symbol!(hb_bool_t, uint, uint, uint) hb_version_atleast;

// // ft

// __gshared Symbol!(hb_face_t*, FT_Face, hb_destroy_func_t) hb_ft_face_create;

// __gshared Symbol!(hb_face_t*, FT_Face) hb_ft_face_create_cached;

// __gshared Symbol!(hb_face_t*, FT_Face) hb_ft_face_create_referenced;

// __gshared Symbol!(hb_font_t*, FT_Face, hb_destroy_func_t) hb_ft_font_create;

// __gshared Symbol!(hb_font_t*, FT_Face) hb_ft_font_create_referenced;

// __gshared Symbol!(FT_Face, hb_font_t*) hb_ft_font_get_face;

// __gshared Symbol!(void, hb_font_t*, int) hb_ft_font_set_load_flags;

// __gshared Symbol!(int, hb_font_t*) hb_ft_font_get_load_flags;

// __gshared Symbol!(void, hb_font_t*) hb_ft_font_set_funcs;
