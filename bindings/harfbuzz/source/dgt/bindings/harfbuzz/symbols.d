module dgt.bindings.harfbuzz.symbols;

import dgt.bindings.harfbuzz.definitions;

import derelict.freetype.ft;

extern(C) nothrow @nogc __gshared
{

    // hb-blob.h

    alias da_hb_blob_create = hb_blob_t * function (const(char)* data,
            uint       length,
            hb_memory_mode_t   mode,
            void              *user_data,
            hb_destroy_func_t  destroy);

    alias da_hb_blob_create_sub_blob = hb_blob_t * function (hb_blob_t    *parent,
                uint  offset,
                uint  length);

    alias da_hb_blob_get_empty = hb_blob_t * function ();

    alias da_hb_blob_reference = hb_blob_t * function (hb_blob_t *blob);

    alias da_hb_blob_destroy = void function (hb_blob_t *blob);

    alias da_hb_blob_set_user_data = hb_bool_t function (hb_blob_t          *blob,
                hb_user_data_key_t *key,
                void *              data,
                hb_destroy_func_t   destroy,
                hb_bool_t           replace);


    alias da_hb_blob_get_user_data = void * function (hb_blob_t          *blob,
                hb_user_data_key_t *key);


    alias da_hb_blob_make_immutable = void function (hb_blob_t *blob);

    alias da_hb_blob_is_immutable = hb_bool_t function (hb_blob_t *blob);


    alias da_hb_blob_get_length = uint function (hb_blob_t *blob);

    alias da_hb_blob_get_data = const(char)* function (hb_blob_t *blob, uint *length);

    alias da_hb_blob_get_data_writable = char * function (hb_blob_t *blob, uint *length);


    // hb-buffer.h


    alias da_hb_segment_properties_equal = hb_bool_t function (const(hb_segment_properties_t)* a,
                    const(hb_segment_properties_t)* b);

    alias da_hb_segment_properties_hash = uint function (const(hb_segment_properties_t)* p);



    alias da_hb_buffer_create = hb_buffer_t * function ();

    alias da_hb_buffer_get_empty = hb_buffer_t * function ();

    alias da_hb_buffer_reference = hb_buffer_t * function (hb_buffer_t *buffer);

    alias da_hb_buffer_destroy = void function (hb_buffer_t *buffer);

    alias da_hb_buffer_set_user_data = hb_bool_t function (hb_buffer_t        *buffer,
                hb_user_data_key_t *key,
                void *              data,
                hb_destroy_func_t   destroy,
                hb_bool_t           replace);

    alias da_hb_buffer_get_user_data = void * function (hb_buffer_t        *buffer,
                hb_user_data_key_t *key);

    alias da_hb_buffer_set_content_type = void function (hb_buffer_t              *buffer,
                    hb_buffer_content_type_t  content_type);

    alias da_hb_buffer_get_content_type = hb_buffer_content_type_t function (hb_buffer_t *buffer);


    alias da_hb_buffer_set_unicode_funcs = void function (hb_buffer_t        *buffer,
                    hb_unicode_funcs_t *unicode_funcs);

    alias da_hb_buffer_get_unicode_funcs = hb_unicode_funcs_t * function (hb_buffer_t        *buffer);

    alias da_hb_buffer_set_direction = void function (hb_buffer_t    *buffer,
                hb_direction_t  direction);

    alias da_hb_buffer_get_direction = hb_direction_t function (hb_buffer_t *buffer);

    alias da_hb_buffer_set_script = void function (hb_buffer_t *buffer,
                hb_script_t  script);

    alias da_hb_buffer_get_script = hb_script_t function (hb_buffer_t *buffer);

    alias da_hb_buffer_set_language = void function (hb_buffer_t   *buffer,
                hb_language_t  language);


    alias da_hb_buffer_get_language = hb_language_t function (hb_buffer_t *buffer);

    alias da_hb_buffer_set_segment_properties = void function (hb_buffer_t *buffer,
                    const(hb_segment_properties_t)* props);

    alias da_hb_buffer_get_segment_properties = void function (hb_buffer_t *buffer,
                    hb_segment_properties_t *props);

    alias da_hb_buffer_guess_segment_properties = void function (hb_buffer_t *buffer);


    alias da_hb_buffer_set_flags = void function (hb_buffer_t       *buffer,
                hb_buffer_flags_t  flags);

    alias da_hb_buffer_get_flags = hb_buffer_flags_t function (hb_buffer_t *buffer);


    alias da_hb_buffer_set_cluster_level = void function (hb_buffer_t               *buffer,
                    hb_buffer_cluster_level_t  cluster_level);

    alias da_hb_buffer_get_cluster_level = hb_buffer_cluster_level_t function (hb_buffer_t *buffer);


    alias da_hb_buffer_set_replacement_codepoint = void function (hb_buffer_t    *buffer,
                        hb_codepoint_t  replacement);

    alias da_hb_buffer_get_replacement_codepoint = hb_codepoint_t function (hb_buffer_t    *buffer);


    alias da_hb_buffer_reset = void function (hb_buffer_t *buffer);

    alias da_hb_buffer_clear_contents = void function (hb_buffer_t *buffer);

    alias da_hb_buffer_pre_allocate = hb_bool_t function (hb_buffer_t  *buffer,
                    uint  size);


    alias da_hb_buffer_allocation_successful = hb_bool_t function (hb_buffer_t  *buffer);

    alias da_hb_buffer_reverse = void function (hb_buffer_t *buffer);

    alias da_hb_buffer_reverse_range = void function (hb_buffer_t *buffer,
                uint start, uint end);

    alias da_hb_buffer_reverse_clusters = void function (hb_buffer_t *buffer);


    alias da_hb_buffer_add = void function (hb_buffer_t    *buffer,
            hb_codepoint_t  codepoint,
            uint    cluster);

    alias da_hb_buffer_add_utf8 = void function (hb_buffer_t  *buffer,
                const(char)* text,
                int           text_length,
                uint  item_offset,
                int           item_length);

    alias da_hb_buffer_add_utf16 = void function (hb_buffer_t    *buffer,
                const(wchar)* text,
                int             text_length,
                uint    item_offset,
                int             item_length);

    alias da_hb_buffer_add_utf32 = void function (hb_buffer_t    *buffer,
                const(dchar)* text,
                int             text_length,
                uint    item_offset,
                int             item_length);

    alias da_hb_buffer_add_latin1 = void function (hb_buffer_t   *buffer,
                const(char)* text,
                int            text_length,
                uint   item_offset,
                int            item_length);

    alias da_hb_buffer_add_codepoints = void function (hb_buffer_t          *buffer,
                const(hb_codepoint_t)* text,
                int                   text_length,
                uint          item_offset,
                int                   item_length);


    alias da_hb_buffer_set_length = hb_bool_t function (hb_buffer_t  *buffer,
                uint  length);

    alias da_hb_buffer_get_length = uint function (hb_buffer_t *buffer);


    alias da_hb_buffer_get_glyph_infos = hb_glyph_info_t * function (hb_buffer_t  *buffer,
                            uint *length);

    alias da_hb_buffer_get_glyph_positions = hb_glyph_position_t * function (hb_buffer_t  *buffer,
                                uint *length);


    alias da_hb_buffer_normalize_glyphs = void function (hb_buffer_t *buffer);



    alias da_hb_buffer_serialize_format_from_string = hb_buffer_serialize_format_t function (const(char)* str, int len);

    alias da_hb_buffer_serialize_format_to_string = const(char)* function (hb_buffer_serialize_format_t format);

    alias da_hb_buffer_serialize_list_formats = const(char)* * function ();

    alias da_hb_buffer_serialize_glyphs = uint function (hb_buffer_t *buffer,
                    uint start,
                    uint end,
                    char *buf,
                    uint buf_size,
                    uint *buf_consumed,
                    hb_font_t *font,
                    hb_buffer_serialize_format_t format,
                    hb_buffer_serialize_flags_t flags);

    alias da_hb_buffer_deserialize_glyphs = hb_bool_t function (hb_buffer_t *buffer,
                    const(char)* buf,
                    int buf_len,
                    const(char)* *end_ptr,
                    hb_font_t *font,
                    hb_buffer_serialize_format_t format);



    alias da_hb_buffer_set_message_func = void function (hb_buffer_t *buffer,
                    hb_buffer_message_func_t func,
                    void *user_data, hb_destroy_func_t destroy);

    // hb-common.h

    alias da_hb_tag_from_string = hb_tag_t function (const(char)* str, int len);

    alias da_hb_tag_to_string = void function (hb_tag_t tag, char* buf);

    alias da_hb_direction_from_string = hb_direction_t function (const(char)* str, int len);

    alias da_hb_direction_to_string = const(char)* function (hb_direction_t direction);

    alias da_hb_language_from_string = hb_language_t function (const(char)* str, int len);

    alias da_hb_language_to_string = const(char)* function (hb_language_t language);

    alias da_hb_language_get_default = hb_language_t function ();

    alias da_hb_script_from_iso15924_tag = hb_script_t function (hb_tag_t tag);

    alias da_hb_script_from_string = hb_script_t function (const(char)* str, int len);

    alias da_hb_script_to_iso15924_tag = hb_tag_t function (hb_script_t script);

    alias da_hb_script_get_horizontal_direction = hb_direction_t function (hb_script_t script);

    // hb-face.h


    alias da_hb_face_create = hb_face_t * function (hb_blob_t    *blob,
            uint  index);


    alias da_hb_face_create_for_tables = hb_face_t * function (hb_reference_table_func_t  reference_table_func,
                void                      *user_data,
                hb_destroy_func_t          destroy);

    alias da_hb_face_get_empty = hb_face_t * function ();

    alias da_hb_face_reference = hb_face_t * function (hb_face_t *face);

    alias da_hb_face_destroy = void function (hb_face_t *face);

    alias da_hb_face_set_user_data = hb_bool_t function (hb_face_t          *face,
                hb_user_data_key_t *key,
                void *              data,
                hb_destroy_func_t   destroy,
                hb_bool_t           replace);


    alias da_hb_face_get_user_data = void * function (hb_face_t          *face,
                hb_user_data_key_t *key);

    alias da_hb_face_make_immutable = void function (hb_face_t *face);

    alias da_hb_face_is_immutable = hb_bool_t function (hb_face_t *face);


    alias da_hb_face_reference_table = hb_blob_t * function (hb_face_t *face,
                hb_tag_t   tag);

    alias da_hb_face_reference_blob = hb_blob_t * function (hb_face_t *face);

    alias da_hb_face_set_index = void function (hb_face_t    *face,
            uint  index);

    alias da_hb_face_get_index = uint function (hb_face_t    *face);

    alias da_hb_face_set_upem = void function (hb_face_t    *face,
            uint  upem);

    alias da_hb_face_get_upem = uint function (hb_face_t *face);

    alias da_hb_face_set_glyph_count = void function (hb_face_t    *face,
                uint  glyph_count);

    alias da_hb_face_get_glyph_count = uint function (hb_face_t *face);


    // hb-font.h


    alias da_hb_font_funcs_create = hb_font_funcs_t * function ();

    alias da_hb_font_funcs_get_empty = hb_font_funcs_t * function ();

    alias da_hb_font_funcs_reference = hb_font_funcs_t * function (hb_font_funcs_t *ffuncs);

    alias da_hb_font_funcs_destroy = void function (hb_font_funcs_t *ffuncs);

    alias da_hb_font_funcs_set_user_data = hb_bool_t function (hb_font_funcs_t    *ffuncs,
                    hb_user_data_key_t *key,
                    void *              data,
                    hb_destroy_func_t   destroy,
                    hb_bool_t           replace);


    alias da_hb_font_funcs_get_user_data = void * function (hb_font_funcs_t    *ffuncs,
                    hb_user_data_key_t *key);


    alias da_hb_font_funcs_make_immutable = void function (hb_font_funcs_t *ffuncs);

    alias da_hb_font_funcs_is_immutable = hb_bool_t function (hb_font_funcs_t *ffuncs);




    alias da_hb_font_funcs_set_font_h_extents_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_font_h_extents_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_font_funcs_set_font_v_extents_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_font_v_extents_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_font_funcs_set_nominal_glyph_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_nominal_glyph_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_font_funcs_set_variation_glyph_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_variation_glyph_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_font_funcs_set_glyph_h_advance_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_h_advance_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_font_funcs_set_glyph_v_advance_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_v_advance_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_font_funcs_set_glyph_h_origin_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_h_origin_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_font_funcs_set_glyph_v_origin_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_v_origin_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_font_funcs_set_glyph_h_kerning_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_h_kerning_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_font_funcs_set_glyph_v_kerning_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_v_kerning_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_font_funcs_set_glyph_extents_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_extents_func_t func,
                        void *user_data, hb_destroy_func_t destroy);

    alias da_hb_font_funcs_set_glyph_contour_point_func = void function (hb_font_funcs_t *ffuncs,
                            hb_font_get_glyph_contour_point_func_t func,
                            void *user_data, hb_destroy_func_t destroy);

    alias da_hb_font_funcs_set_glyph_name_func = void function (hb_font_funcs_t *ffuncs,
                    hb_font_get_glyph_name_func_t func,
                    void *user_data, hb_destroy_func_t destroy);

    alias da_hb_font_funcs_set_glyph_from_name_func = void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_from_name_func_t func,
                        void *user_data, hb_destroy_func_t destroy);

    alias da_hb_font_get_h_extents = hb_bool_t function (hb_font_t *font,
                hb_font_extents_t *extents);
    alias da_hb_font_get_v_extents = hb_bool_t function (hb_font_t *font,
                hb_font_extents_t *extents);

    alias da_hb_font_get_nominal_glyph = hb_bool_t function (hb_font_t *font,
                hb_codepoint_t unicode,
                hb_codepoint_t *glyph);
    alias da_hb_font_get_variation_glyph = hb_bool_t function (hb_font_t *font,
                    hb_codepoint_t unicode, hb_codepoint_t variation_selector,
                    hb_codepoint_t *glyph);

    alias da_hb_font_get_glyph_h_advance = hb_position_t function (hb_font_t *font,
                    hb_codepoint_t glyph);
    alias da_hb_font_get_glyph_v_advance = hb_position_t function (hb_font_t *font,
                    hb_codepoint_t glyph);

    alias da_hb_font_get_glyph_h_origin = hb_bool_t function (hb_font_t *font,
                    hb_codepoint_t glyph,
                    hb_position_t *x, hb_position_t *y);
    alias da_hb_font_get_glyph_v_origin = hb_bool_t function (hb_font_t *font,
                    hb_codepoint_t glyph,
                    hb_position_t *x, hb_position_t *y);

    alias da_hb_font_get_glyph_h_kerning = hb_position_t function (hb_font_t *font,
                    hb_codepoint_t left_glyph, hb_codepoint_t right_glyph);
    alias da_hb_font_get_glyph_v_kerning = hb_position_t function (hb_font_t *font,
                    hb_codepoint_t top_glyph, hb_codepoint_t bottom_glyph);

    alias da_hb_font_get_glyph_extents = hb_bool_t function (hb_font_t *font,
                hb_codepoint_t glyph,
                hb_glyph_extents_t *extents);

    alias da_hb_font_get_glyph_contour_point = hb_bool_t function (hb_font_t *font,
                    hb_codepoint_t glyph, uint point_index,
                    hb_position_t *x, hb_position_t *y);

    alias da_hb_font_get_glyph_name = hb_bool_t function (hb_font_t *font,
                hb_codepoint_t glyph,
                char *name, uint size);
    alias da_hb_font_get_glyph_from_name = hb_bool_t function (hb_font_t *font,
                    const(char)* name, int len,
                    hb_codepoint_t *glyph);





    alias da_hb_font_get_glyph = hb_bool_t function (hb_font_t *font,
            hb_codepoint_t unicode, hb_codepoint_t variation_selector,
            hb_codepoint_t *glyph);

    alias da_hb_font_get_extents_for_direction = void function (hb_font_t *font,
                    hb_direction_t direction,
                    hb_font_extents_t *extents);
    alias da_hb_font_get_glyph_advance_for_direction = void function (hb_font_t *font,
                        hb_codepoint_t glyph,
                        hb_direction_t direction,
                        hb_position_t *x, hb_position_t *y);
    alias da_hb_font_get_glyph_origin_for_direction = void function (hb_font_t *font,
                        hb_codepoint_t glyph,
                        hb_direction_t direction,
                        hb_position_t *x, hb_position_t *y);
    alias da_hb_font_add_glyph_origin_for_direction = void function (hb_font_t *font,
                        hb_codepoint_t glyph,
                        hb_direction_t direction,
                        hb_position_t *x, hb_position_t *y);
    alias da_hb_font_subtract_glyph_origin_for_direction = void function (hb_font_t *font,
                            hb_codepoint_t glyph,
                            hb_direction_t direction,
                            hb_position_t *x, hb_position_t *y);

    alias da_hb_font_get_glyph_kerning_for_direction = void function (hb_font_t *font,
                        hb_codepoint_t first_glyph, hb_codepoint_t second_glyph,
                        hb_direction_t direction,
                        hb_position_t *x, hb_position_t *y);

    alias da_hb_font_get_glyph_extents_for_origin = hb_bool_t function (hb_font_t *font,
                        hb_codepoint_t glyph,
                        hb_direction_t direction,
                        hb_glyph_extents_t *extents);

    alias da_hb_font_get_glyph_contour_point_for_origin = hb_bool_t function (hb_font_t *font,
                            hb_codepoint_t glyph, uint point_index,
                            hb_direction_t direction,
                            hb_position_t *x, hb_position_t *y);


    alias da_hb_font_glyph_to_string = void function (hb_font_t *font,
                hb_codepoint_t glyph,
                char *s, uint size);

    alias da_hb_font_glyph_from_string = hb_bool_t function (hb_font_t *font,
                const(char)* s, int len,
                hb_codepoint_t *glyph);






    alias da_hb_font_create = hb_font_t * function (hb_face_t *face);

    alias da_hb_font_create_sub_font = hb_font_t * function (hb_font_t *parent);

    alias da_hb_font_get_empty = hb_font_t * function ();

    alias da_hb_font_reference = hb_font_t * function (hb_font_t *font);

    alias da_hb_font_destroy = void function (hb_font_t *font);

    alias da_hb_font_set_user_data = hb_bool_t function (hb_font_t          *font,
                hb_user_data_key_t *key,
                void *              data,
                hb_destroy_func_t   destroy,
                hb_bool_t           replace);


    alias da_hb_font_get_user_data = void * function (hb_font_t          *font,
                hb_user_data_key_t *key);

    alias da_hb_font_make_immutable = void function (hb_font_t *font);

    alias da_hb_font_is_immutable = hb_bool_t function (hb_font_t *font);

    alias da_hb_font_set_parent = void function (hb_font_t *font,
                hb_font_t *parent);

    alias da_hb_font_get_parent = hb_font_t * function (hb_font_t *font);

    alias da_hb_font_get_face = hb_face_t * function (hb_font_t *font);


    alias da_hb_font_set_funcs = void function (hb_font_t         *font,
            hb_font_funcs_t   *klass,
            void              *font_data,
            hb_destroy_func_t  destroy);


    alias da_hb_font_set_funcs_data = void function (hb_font_t         *font,
                    void              *font_data,
                    hb_destroy_func_t  destroy);


    alias da_hb_font_set_scale = void function (hb_font_t *font,
            int x_scale,
            int y_scale);

    alias da_hb_font_get_scale = void function (hb_font_t *font,
            int *x_scale,
            int *y_scale);


    alias da_hb_font_set_ppem = void function (hb_font_t *font,
            uint x_ppem,
            uint y_ppem);

    alias da_hb_font_get_ppem = void function (hb_font_t *font,
            uint *x_ppem,
            uint *y_ppem);


    alias da_hb_font_set_var_coords_normalized = void function (hb_font_t *font,
                    int *coords,
                    uint coords_length);

    // hb-set.h


    alias da_hb_set_create = hb_set_t * function ();

    alias da_hb_set_get_empty = hb_set_t * function ();

    alias da_hb_set_reference = hb_set_t * function (hb_set_t *set);

    alias da_hb_set_destroy = void function (hb_set_t *set);

    alias da_hb_set_set_user_data = hb_bool_t function (hb_set_t           *set,
                hb_user_data_key_t *key,
                void *              data,
                hb_destroy_func_t   destroy,
                hb_bool_t           replace);

    alias da_hb_set_get_user_data = void * function (hb_set_t           *set,
                hb_user_data_key_t *key);



    alias da_hb_set_allocation_successful = hb_bool_t function (const(hb_set_t)* set);

    alias da_hb_set_clear = void function (hb_set_t *set);

    alias da_hb_set_is_empty = hb_bool_t function (const(hb_set_t)* set);

    alias da_hb_set_has = hb_bool_t function (const(hb_set_t)* set,
            hb_codepoint_t  codepoint);


    alias da_hb_set_add = void function (hb_set_t       *set,
            hb_codepoint_t  codepoint);

    alias da_hb_set_add_range = void function (hb_set_t       *set,
            hb_codepoint_t  first,
            hb_codepoint_t  last);

    alias da_hb_set_del = void function (hb_set_t       *set,
            hb_codepoint_t  codepoint);

    alias da_hb_set_del_range = void function (hb_set_t       *set,
            hb_codepoint_t  first,
            hb_codepoint_t  last);

    alias da_hb_set_is_equal = hb_bool_t function (const(hb_set_t)* set,
            const(hb_set_t)* other);

    alias da_hb_set_set = void function (hb_set_t       *set,
            const(hb_set_t)* other);

    alias da_hb_set_union = void function (hb_set_t       *set,
            const(hb_set_t)* other);

    alias da_hb_set_intersect = void function (hb_set_t       *set,
            const(hb_set_t)* other);

    alias da_hb_set_subtract = void function (hb_set_t       *set,
            const(hb_set_t)* other);

    alias da_hb_set_symmetric_difference = void function (hb_set_t       *set,
                    const(hb_set_t)* other);

    alias da_hb_set_invert = void function (hb_set_t *set);

    alias da_hb_set_get_population = uint function (const(hb_set_t)* set);


    alias da_hb_set_get_min = hb_codepoint_t function (const(hb_set_t)* set);


    alias da_hb_set_get_max = hb_codepoint_t function (const(hb_set_t)* set);


    alias da_hb_set_next = hb_bool_t function (const(hb_set_t)* set,
            hb_codepoint_t *codepoint);


    alias da_hb_set_next_range = hb_bool_t function (const(hb_set_t)* set,
            hb_codepoint_t *first,
            hb_codepoint_t *last);

    // hb-shape.h


    alias da_hb_feature_from_string = hb_bool_t function (const(char)* str, int len,
                hb_feature_t *feature);

    alias da_hb_feature_to_string = void function (hb_feature_t *feature,
                char *buf, uint size);


    alias da_hb_shape = void function (hb_font_t           *font,
        hb_buffer_t         *buffer,
        const(hb_feature_t)* features,
        uint         num_features);

    alias da_hb_shape_full = hb_bool_t function (hb_font_t          *font,
            hb_buffer_t        *buffer,
            const(hb_feature_t)* features,
            uint        num_features,
            const(char*)* shaper_list);

    alias da_hb_shape_list_shapers = const(char)* * function ();

    // hb-shape-plan.h


    alias da_hb_shape_plan_create = hb_shape_plan_t * function (hb_face_t                     *face,
                const(hb_segment_properties_t)* props,
                const(hb_feature_t)* user_features,
                uint                   num_user_features,
                const(char*)* shaper_list);

    alias da_hb_shape_plan_create_cached = hb_shape_plan_t * function (hb_face_t                     *face,
                    const(hb_segment_properties_t)* props,
                    const(hb_feature_t)* user_features,
                    uint                   num_user_features,
                    const(char*)* shaper_list);

    alias da_hb_shape_plan_create2 = hb_shape_plan_t * function (hb_face_t                     *face,
                const(hb_segment_properties_t)* props,
                const(hb_feature_t)* user_features,
                uint                   num_user_features,
                const(int)* coords,
                uint                   num_coords,
                const(char*)* shaper_list);

    alias da_hb_shape_plan_create_cached2 = hb_shape_plan_t * function (hb_face_t                     *face,
                    const(hb_segment_properties_t)* props,
                    const(hb_feature_t)* user_features,
                    uint                   num_user_features,
                    const(int)* coords,
                    uint                   num_coords,
                    const(char*)* shaper_list);


    alias da_hb_shape_plan_get_empty = hb_shape_plan_t * function ();

    alias da_hb_shape_plan_reference = hb_shape_plan_t * function (hb_shape_plan_t *shape_plan);

    alias da_hb_shape_plan_destroy = void function (hb_shape_plan_t *shape_plan);

    alias da_hb_shape_plan_set_user_data = hb_bool_t function (hb_shape_plan_t    *shape_plan,
                    hb_user_data_key_t *key,
                    void *              data,
                    hb_destroy_func_t   destroy,
                    hb_bool_t           replace);

    alias da_hb_shape_plan_get_user_data = void * function (hb_shape_plan_t    *shape_plan,
                    hb_user_data_key_t *key);


    alias da_hb_shape_plan_execute = hb_bool_t function (hb_shape_plan_t    *shape_plan,
                hb_font_t          *font,
                hb_buffer_t        *buffer,
                const(hb_feature_t)* features,
                uint        num_features);

    alias da_hb_shape_plan_get_shaper = const(char)* function (hb_shape_plan_t *shape_plan);

    // hb-unicode.h

    alias da_hb_unicode_funcs_get_default = hb_unicode_funcs_t * function ();


    alias da_hb_unicode_funcs_create = hb_unicode_funcs_t * function (hb_unicode_funcs_t *parent);

    alias da_hb_unicode_funcs_get_empty = hb_unicode_funcs_t * function ();

    alias da_hb_unicode_funcs_reference = hb_unicode_funcs_t * function (hb_unicode_funcs_t *ufuncs);

    alias da_hb_unicode_funcs_destroy = void function (hb_unicode_funcs_t *ufuncs);

    alias da_hb_unicode_funcs_set_user_data = hb_bool_t function (hb_unicode_funcs_t *ufuncs,
                        hb_user_data_key_t *key,
                        void *              data,
                        hb_destroy_func_t   destroy,
                    hb_bool_t           replace);


    alias da_hb_unicode_funcs_get_user_data = void * function (hb_unicode_funcs_t *ufuncs,
                        hb_user_data_key_t *key);


    alias da_hb_unicode_funcs_make_immutable = void function (hb_unicode_funcs_t *ufuncs);

    alias da_hb_unicode_funcs_is_immutable = hb_bool_t function (hb_unicode_funcs_t *ufuncs);

    alias da_hb_unicode_funcs_get_parent = hb_unicode_funcs_t * function (hb_unicode_funcs_t *ufuncs);





    alias da_hb_unicode_funcs_set_combining_class_func = void function (hb_unicode_funcs_t *ufuncs,
                        hb_unicode_combining_class_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_unicode_funcs_set_eastasian_width_func = void function (hb_unicode_funcs_t *ufuncs,
                        hb_unicode_eastasian_width_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_unicode_funcs_set_general_category_func = void function (hb_unicode_funcs_t *ufuncs,
                            hb_unicode_general_category_func_t func,
                            void *user_data, hb_destroy_func_t destroy);


    alias da_hb_unicode_funcs_set_mirroring_func = void function (hb_unicode_funcs_t *ufuncs,
                        hb_unicode_mirroring_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_unicode_funcs_set_script_func = void function (hb_unicode_funcs_t *ufuncs,
                    hb_unicode_script_func_t func,
                    void *user_data, hb_destroy_func_t destroy);


    alias da_hb_unicode_funcs_set_compose_func = void function (hb_unicode_funcs_t *ufuncs,
                    hb_unicode_compose_func_t func,
                    void *user_data, hb_destroy_func_t destroy);


    alias da_hb_unicode_funcs_set_decompose_func = void function (hb_unicode_funcs_t *ufuncs,
                        hb_unicode_decompose_func_t func,
                        void *user_data, hb_destroy_func_t destroy);


    alias da_hb_unicode_funcs_set_decompose_compatibility_func = void function (hb_unicode_funcs_t *ufuncs,
                            hb_unicode_decompose_compatibility_func_t func,
                            void *user_data, hb_destroy_func_t destroy);




    alias da_hb_unicode_combining_class = hb_unicode_combining_class_t function (hb_unicode_funcs_t *ufuncs,
                    hb_codepoint_t unicode);


    alias da_hb_unicode_eastasian_width = uint function (hb_unicode_funcs_t *ufuncs,
                    hb_codepoint_t unicode);


    alias da_hb_unicode_general_category = hb_unicode_general_category_t function (hb_unicode_funcs_t *ufuncs,
                    hb_codepoint_t unicode);


    alias da_hb_unicode_mirroring = hb_codepoint_t function (hb_unicode_funcs_t *ufuncs,
                hb_codepoint_t unicode);


    alias da_hb_unicode_script = hb_script_t function (hb_unicode_funcs_t *ufuncs,
            hb_codepoint_t unicode);

    alias da_hb_unicode_compose = hb_bool_t function (hb_unicode_funcs_t *ufuncs,
                hb_codepoint_t      a,
                hb_codepoint_t      b,
                hb_codepoint_t     *ab);

    alias da_hb_unicode_decompose = hb_bool_t function (hb_unicode_funcs_t *ufuncs,
                hb_codepoint_t      ab,
                hb_codepoint_t     *a,
                hb_codepoint_t     *b);

    alias da_hb_unicode_decompose_compatibility = uint function (hb_unicode_funcs_t *ufuncs,
                        hb_codepoint_t      u,
                        hb_codepoint_t     *decomposed);

    // hb-version.h


    alias da_hb_version = void function (uint *major,
            uint *minor,
            uint *micro);

    alias da_hb_version_string = const(char)* function ();

    alias da_hb_version_atleast = hb_bool_t function (uint major,
                uint minor,
                uint micro);

    // hb-ft.h

    alias da_hb_ft_face_create = hb_face_t * function (FT_Face           ft_face,
                    hb_destroy_func_t destroy);

    alias da_hb_ft_face_create_cached = hb_face_t * function (FT_Face ft_face);

    alias da_hb_ft_face_create_referenced = hb_face_t * function (FT_Face ft_face);

    alias da_hb_ft_font_create = hb_font_t * function (FT_Face           ft_face,
                    hb_destroy_func_t destroy);

    alias da_hb_ft_font_create_referenced = hb_font_t * function (FT_Face ft_face);

    alias da_hb_ft_font_get_face = FT_Face function (hb_font_t *font);

    alias da_hb_ft_font_set_load_flags = void function (hb_font_t *font, int load_flags);

    alias da_hb_ft_font_get_load_flags = int function (hb_font_t *font);

    alias da_hb_ft_font_set_funcs = void function (hb_font_t *font);
}

__gshared
{

    // hb-blob.h

    da_hb_blob_create hb_blob_create;

    da_hb_blob_create_sub_blob hb_blob_create_sub_blob;

    da_hb_blob_get_empty hb_blob_get_empty;

    da_hb_blob_reference hb_blob_reference;

    da_hb_blob_destroy hb_blob_destroy;

    da_hb_blob_set_user_data hb_blob_set_user_data;


    da_hb_blob_get_user_data hb_blob_get_user_data;


    da_hb_blob_make_immutable hb_blob_make_immutable;

    da_hb_blob_is_immutable hb_blob_is_immutable;


    da_hb_blob_get_length hb_blob_get_length;

    da_hb_blob_get_data hb_blob_get_data;

    da_hb_blob_get_data_writable hb_blob_get_data_writable;


    // hb-buffer.h


    da_hb_segment_properties_equal hb_segment_properties_equal;

    da_hb_segment_properties_hash hb_segment_properties_hash;



    da_hb_buffer_create hb_buffer_create;

    da_hb_buffer_get_empty hb_buffer_get_empty;

    da_hb_buffer_reference hb_buffer_reference;

    da_hb_buffer_destroy hb_buffer_destroy;

    da_hb_buffer_set_user_data hb_buffer_set_user_data;

    da_hb_buffer_get_user_data hb_buffer_get_user_data;

    da_hb_buffer_set_content_type hb_buffer_set_content_type;

    da_hb_buffer_get_content_type hb_buffer_get_content_type;


    da_hb_buffer_set_unicode_funcs hb_buffer_set_unicode_funcs;

    da_hb_buffer_get_unicode_funcs hb_buffer_get_unicode_funcs;

    da_hb_buffer_set_direction hb_buffer_set_direction;

    da_hb_buffer_get_direction hb_buffer_get_direction;

    da_hb_buffer_set_script hb_buffer_set_script;

    da_hb_buffer_get_script hb_buffer_get_script;

    da_hb_buffer_set_language hb_buffer_set_language;


    da_hb_buffer_get_language hb_buffer_get_language;

    da_hb_buffer_set_segment_properties hb_buffer_set_segment_properties;

    da_hb_buffer_get_segment_properties hb_buffer_get_segment_properties;

    da_hb_buffer_guess_segment_properties hb_buffer_guess_segment_properties;


    da_hb_buffer_set_flags hb_buffer_set_flags;

    da_hb_buffer_get_flags hb_buffer_get_flags;


    da_hb_buffer_set_cluster_level hb_buffer_set_cluster_level;

    da_hb_buffer_get_cluster_level hb_buffer_get_cluster_level;


    da_hb_buffer_set_replacement_codepoint hb_buffer_set_replacement_codepoint;

    da_hb_buffer_get_replacement_codepoint hb_buffer_get_replacement_codepoint;


    da_hb_buffer_reset hb_buffer_reset;

    da_hb_buffer_clear_contents hb_buffer_clear_contents;

    da_hb_buffer_pre_allocate hb_buffer_pre_allocate;


    da_hb_buffer_allocation_successful hb_buffer_allocation_successful;

    da_hb_buffer_reverse hb_buffer_reverse;

    da_hb_buffer_reverse_range hb_buffer_reverse_range;

    da_hb_buffer_reverse_clusters hb_buffer_reverse_clusters;


    da_hb_buffer_add hb_buffer_add;

    da_hb_buffer_add_utf8 hb_buffer_add_utf8;

    da_hb_buffer_add_utf16 hb_buffer_add_utf16;

    da_hb_buffer_add_utf32 hb_buffer_add_utf32;

    da_hb_buffer_add_latin1 hb_buffer_add_latin1;

    da_hb_buffer_add_codepoints hb_buffer_add_codepoints;


    da_hb_buffer_set_length hb_buffer_set_length;

    da_hb_buffer_get_length hb_buffer_get_length;


    da_hb_buffer_get_glyph_infos hb_buffer_get_glyph_infos;

    da_hb_buffer_get_glyph_positions hb_buffer_get_glyph_positions;


    da_hb_buffer_normalize_glyphs hb_buffer_normalize_glyphs;



    da_hb_buffer_serialize_format_from_string hb_buffer_serialize_format_from_string;

    da_hb_buffer_serialize_format_to_string hb_buffer_serialize_format_to_string;

    da_hb_buffer_serialize_list_formats hb_buffer_serialize_list_formats;

    da_hb_buffer_serialize_glyphs hb_buffer_serialize_glyphs;

    da_hb_buffer_deserialize_glyphs hb_buffer_deserialize_glyphs;



    da_hb_buffer_set_message_func hb_buffer_set_message_func;

    // hb-common.h

    da_hb_tag_from_string hb_tag_from_string;

    da_hb_tag_to_string hb_tag_to_string;

    da_hb_direction_from_string hb_direction_from_string;

    da_hb_direction_to_string hb_direction_to_string;

    da_hb_language_from_string hb_language_from_string;

    da_hb_language_to_string hb_language_to_string;

    da_hb_language_get_default hb_language_get_default;

    da_hb_script_from_iso15924_tag hb_script_from_iso15924_tag;

    da_hb_script_from_string hb_script_from_string;

    da_hb_script_to_iso15924_tag hb_script_to_iso15924_tag;

    da_hb_script_get_horizontal_direction hb_script_get_horizontal_direction;

    // hb-face.h


    da_hb_face_create hb_face_create;


    da_hb_face_create_for_tables hb_face_create_for_tables;

    da_hb_face_get_empty hb_face_get_empty;

    da_hb_face_reference hb_face_reference;

    da_hb_face_destroy hb_face_destroy;

    da_hb_face_set_user_data hb_face_set_user_data;


    da_hb_face_get_user_data hb_face_get_user_data;

    da_hb_face_make_immutable hb_face_make_immutable;

    da_hb_face_is_immutable hb_face_is_immutable;


    da_hb_face_reference_table hb_face_reference_table;

    da_hb_face_reference_blob hb_face_reference_blob;

    da_hb_face_set_index hb_face_set_index;

    da_hb_face_get_index hb_face_get_index;

    da_hb_face_set_upem hb_face_set_upem;

    da_hb_face_get_upem hb_face_get_upem;

    da_hb_face_set_glyph_count hb_face_set_glyph_count;

    da_hb_face_get_glyph_count hb_face_get_glyph_count;


    // hb-font.h


    da_hb_font_funcs_create hb_font_funcs_create;

    da_hb_font_funcs_get_empty hb_font_funcs_get_empty;

    da_hb_font_funcs_reference hb_font_funcs_reference;

    da_hb_font_funcs_destroy hb_font_funcs_destroy;

    da_hb_font_funcs_set_user_data hb_font_funcs_set_user_data;


    da_hb_font_funcs_get_user_data hb_font_funcs_get_user_data;


    da_hb_font_funcs_make_immutable hb_font_funcs_make_immutable;

    da_hb_font_funcs_is_immutable hb_font_funcs_is_immutable;




    da_hb_font_funcs_set_font_h_extents_func hb_font_funcs_set_font_h_extents_func;


    da_hb_font_funcs_set_font_v_extents_func hb_font_funcs_set_font_v_extents_func;


    da_hb_font_funcs_set_nominal_glyph_func hb_font_funcs_set_nominal_glyph_func;


    da_hb_font_funcs_set_variation_glyph_func hb_font_funcs_set_variation_glyph_func;


    da_hb_font_funcs_set_glyph_h_advance_func hb_font_funcs_set_glyph_h_advance_func;


    da_hb_font_funcs_set_glyph_v_advance_func hb_font_funcs_set_glyph_v_advance_func;


    da_hb_font_funcs_set_glyph_h_origin_func hb_font_funcs_set_glyph_h_origin_func;


    da_hb_font_funcs_set_glyph_v_origin_func hb_font_funcs_set_glyph_v_origin_func;


    da_hb_font_funcs_set_glyph_h_kerning_func hb_font_funcs_set_glyph_h_kerning_func;


    da_hb_font_funcs_set_glyph_v_kerning_func hb_font_funcs_set_glyph_v_kerning_func;


    da_hb_font_funcs_set_glyph_extents_func hb_font_funcs_set_glyph_extents_func;

    da_hb_font_funcs_set_glyph_contour_point_func hb_font_funcs_set_glyph_contour_point_func;

    da_hb_font_funcs_set_glyph_name_func hb_font_funcs_set_glyph_name_func;

    da_hb_font_funcs_set_glyph_from_name_func hb_font_funcs_set_glyph_from_name_func;

    da_hb_font_get_h_extents hb_font_get_h_extents;
    da_hb_font_get_v_extents hb_font_get_v_extents;

    da_hb_font_get_nominal_glyph hb_font_get_nominal_glyph;
    da_hb_font_get_variation_glyph hb_font_get_variation_glyph;

    da_hb_font_get_glyph_h_advance hb_font_get_glyph_h_advance;
    da_hb_font_get_glyph_v_advance hb_font_get_glyph_v_advance;

    da_hb_font_get_glyph_h_origin hb_font_get_glyph_h_origin;
    da_hb_font_get_glyph_v_origin hb_font_get_glyph_v_origin;

    da_hb_font_get_glyph_h_kerning hb_font_get_glyph_h_kerning;
    da_hb_font_get_glyph_v_kerning hb_font_get_glyph_v_kerning;

    da_hb_font_get_glyph_extents hb_font_get_glyph_extents;

    da_hb_font_get_glyph_contour_point hb_font_get_glyph_contour_point;

    da_hb_font_get_glyph_name hb_font_get_glyph_name;
    da_hb_font_get_glyph_from_name hb_font_get_glyph_from_name;





    da_hb_font_get_glyph hb_font_get_glyph;

    da_hb_font_get_extents_for_direction hb_font_get_extents_for_direction;
    da_hb_font_get_glyph_advance_for_direction hb_font_get_glyph_advance_for_direction;
    da_hb_font_get_glyph_origin_for_direction hb_font_get_glyph_origin_for_direction;
    da_hb_font_add_glyph_origin_for_direction hb_font_add_glyph_origin_for_direction;
    da_hb_font_subtract_glyph_origin_for_direction hb_font_subtract_glyph_origin_for_direction;

    da_hb_font_get_glyph_kerning_for_direction hb_font_get_glyph_kerning_for_direction;

    da_hb_font_get_glyph_extents_for_origin hb_font_get_glyph_extents_for_origin;

    da_hb_font_get_glyph_contour_point_for_origin hb_font_get_glyph_contour_point_for_origin;


    da_hb_font_glyph_to_string hb_font_glyph_to_string;

    da_hb_font_glyph_from_string hb_font_glyph_from_string;






    da_hb_font_create hb_font_create;

    da_hb_font_create_sub_font hb_font_create_sub_font;

    da_hb_font_get_empty hb_font_get_empty;

    da_hb_font_reference hb_font_reference;

    da_hb_font_destroy hb_font_destroy;

    da_hb_font_set_user_data hb_font_set_user_data;


    da_hb_font_get_user_data hb_font_get_user_data;

    da_hb_font_make_immutable hb_font_make_immutable;

    da_hb_font_is_immutable hb_font_is_immutable;

    da_hb_font_set_parent hb_font_set_parent;

    da_hb_font_get_parent hb_font_get_parent;

    da_hb_font_get_face hb_font_get_face;


    da_hb_font_set_funcs hb_font_set_funcs;


    da_hb_font_set_funcs_data hb_font_set_funcs_data;


    da_hb_font_set_scale hb_font_set_scale;

    da_hb_font_get_scale hb_font_get_scale;


    da_hb_font_set_ppem hb_font_set_ppem;

    da_hb_font_get_ppem hb_font_get_ppem;


    da_hb_font_set_var_coords_normalized hb_font_set_var_coords_normalized;

    // hb-set.h


    da_hb_set_create hb_set_create;

    da_hb_set_get_empty hb_set_get_empty;

    da_hb_set_reference hb_set_reference;

    da_hb_set_destroy hb_set_destroy;

    da_hb_set_set_user_data hb_set_set_user_data;

    da_hb_set_get_user_data hb_set_get_user_data;



    da_hb_set_allocation_successful hb_set_allocation_successful;

    da_hb_set_clear hb_set_clear;

    da_hb_set_is_empty hb_set_is_empty;

    da_hb_set_has hb_set_has;


    da_hb_set_add hb_set_add;

    da_hb_set_add_range hb_set_add_range;

    da_hb_set_del hb_set_del;

    da_hb_set_del_range hb_set_del_range;

    da_hb_set_is_equal hb_set_is_equal;

    da_hb_set_set hb_set_set;

    da_hb_set_union hb_set_union;

    da_hb_set_intersect hb_set_intersect;

    da_hb_set_subtract hb_set_subtract;

    da_hb_set_symmetric_difference hb_set_symmetric_difference;

    da_hb_set_invert hb_set_invert;

    da_hb_set_get_population hb_set_get_population;


    da_hb_set_get_min hb_set_get_min;


    da_hb_set_get_max hb_set_get_max;


    da_hb_set_next hb_set_next;


    da_hb_set_next_range hb_set_next_range;

    // hb-shape.h


    da_hb_feature_from_string hb_feature_from_string;

    da_hb_feature_to_string hb_feature_to_string;


    da_hb_shape hb_shape;

    da_hb_shape_full hb_shape_full;

    da_hb_shape_list_shapers hb_shape_list_shapers;

    // hb-shape-plan.h


    da_hb_shape_plan_create hb_shape_plan_create;

    da_hb_shape_plan_create_cached hb_shape_plan_create_cached;

    da_hb_shape_plan_create2 hb_shape_plan_create2;

    da_hb_shape_plan_create_cached2 hb_shape_plan_create_cached2;


    da_hb_shape_plan_get_empty hb_shape_plan_get_empty;

    da_hb_shape_plan_reference hb_shape_plan_reference;

    da_hb_shape_plan_destroy hb_shape_plan_destroy;

    da_hb_shape_plan_set_user_data hb_shape_plan_set_user_data;

    da_hb_shape_plan_get_user_data hb_shape_plan_get_user_data;


    da_hb_shape_plan_execute hb_shape_plan_execute;

    da_hb_shape_plan_get_shaper hb_shape_plan_get_shaper;

    // hb-unicode.h

    da_hb_unicode_funcs_get_default hb_unicode_funcs_get_default;


    da_hb_unicode_funcs_create hb_unicode_funcs_create;

    da_hb_unicode_funcs_get_empty hb_unicode_funcs_get_empty;

    da_hb_unicode_funcs_reference hb_unicode_funcs_reference;

    da_hb_unicode_funcs_destroy hb_unicode_funcs_destroy;

    da_hb_unicode_funcs_set_user_data hb_unicode_funcs_set_user_data;


    da_hb_unicode_funcs_get_user_data hb_unicode_funcs_get_user_data;


    da_hb_unicode_funcs_make_immutable hb_unicode_funcs_make_immutable;

    da_hb_unicode_funcs_is_immutable hb_unicode_funcs_is_immutable;

    da_hb_unicode_funcs_get_parent hb_unicode_funcs_get_parent;





    da_hb_unicode_funcs_set_combining_class_func hb_unicode_funcs_set_combining_class_func;


    da_hb_unicode_funcs_set_eastasian_width_func hb_unicode_funcs_set_eastasian_width_func;


    da_hb_unicode_funcs_set_general_category_func hb_unicode_funcs_set_general_category_func;


    da_hb_unicode_funcs_set_mirroring_func hb_unicode_funcs_set_mirroring_func;


    da_hb_unicode_funcs_set_script_func hb_unicode_funcs_set_script_func;


    da_hb_unicode_funcs_set_compose_func hb_unicode_funcs_set_compose_func;


    da_hb_unicode_funcs_set_decompose_func hb_unicode_funcs_set_decompose_func;


    da_hb_unicode_funcs_set_decompose_compatibility_func hb_unicode_funcs_set_decompose_compatibility_func;




    da_hb_unicode_combining_class hb_unicode_combining_class;


    da_hb_unicode_eastasian_width hb_unicode_eastasian_width;


    da_hb_unicode_general_category hb_unicode_general_category;


    da_hb_unicode_mirroring hb_unicode_mirroring;


    da_hb_unicode_script hb_unicode_script;

    da_hb_unicode_compose hb_unicode_compose;

    da_hb_unicode_decompose hb_unicode_decompose;

    da_hb_unicode_decompose_compatibility hb_unicode_decompose_compatibility;

    // hb-version.h


    da_hb_version hb_version;

    da_hb_version_string hb_version_string;

    da_hb_version_atleast hb_version_atleast;

    // hb-ft.h

    da_hb_ft_face_create hb_ft_face_create;

    da_hb_ft_face_create_cached hb_ft_face_create_cached;

    da_hb_ft_face_create_referenced hb_ft_face_create_referenced;

    da_hb_ft_font_create hb_ft_font_create;

    da_hb_ft_font_create_referenced hb_ft_font_create_referenced;

    da_hb_ft_font_get_face hb_ft_font_get_face;

    da_hb_ft_font_set_load_flags hb_ft_font_set_load_flags;

    da_hb_ft_font_get_load_flags hb_ft_font_get_load_flags;

    da_hb_ft_font_set_funcs hb_ft_font_set_funcs;
}
