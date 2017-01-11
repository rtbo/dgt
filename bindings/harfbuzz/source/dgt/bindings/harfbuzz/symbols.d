module dgt.bindings.harfbuzz.symbols;

import dgt.bindings.harfbuzz.definitions;

import derelict.freetype.ft;

extern(C) nothrow @nogc __gshared
{

    // hb-blob.h

    hb_blob_t * function (const(char)* data,
            uint       length,
            hb_memory_mode_t   mode,
            void              *user_data,
            hb_destroy_func_t  destroy)
            hb_blob_create;

    hb_blob_t * function (hb_blob_t    *parent,
                uint  offset,
                uint  length)
            hb_blob_create_sub_blob;

    hb_blob_t * function ()
            hb_blob_get_empty;

    hb_blob_t * function (hb_blob_t *blob)
            hb_blob_reference;

    void function (hb_blob_t *blob)
            hb_blob_destroy;

    hb_bool_t function (hb_blob_t          *blob,
                hb_user_data_key_t *key,
                void *              data,
                hb_destroy_func_t   destroy,
                hb_bool_t           replace)
            hb_blob_set_user_data;


    void * function (hb_blob_t          *blob,
                hb_user_data_key_t *key)
            hb_blob_get_user_data;


    void function (hb_blob_t *blob)
            hb_blob_make_immutable;

    hb_bool_t function (hb_blob_t *blob)
            hb_blob_is_immutable;


    uint function (hb_blob_t *blob)
            hb_blob_get_length;

    const(char)* function (hb_blob_t *blob, uint *length)
            hb_blob_get_data;

    char * function (hb_blob_t *blob, uint *length)
            hb_blob_get_data_writable;


    // hb-buffer.h


    hb_bool_t function (const(hb_segment_properties_t)* a,
                    const(hb_segment_properties_t)* b)
            hb_segment_properties_equal;

    uint function (const(hb_segment_properties_t)* p)
            hb_segment_properties_hash;



    hb_buffer_t * function ()
            hb_buffer_create;

    hb_buffer_t * function ()
            hb_buffer_get_empty;

    hb_buffer_t * function (hb_buffer_t *buffer)
            hb_buffer_reference;

    void function (hb_buffer_t *buffer)
            hb_buffer_destroy;

    hb_bool_t function (hb_buffer_t        *buffer,
                hb_user_data_key_t *key,
                void *              data,
                hb_destroy_func_t   destroy,
                hb_bool_t           replace)
            hb_buffer_set_user_data;

    void * function (hb_buffer_t        *buffer,
                hb_user_data_key_t *key)
            hb_buffer_get_user_data;

    void function (hb_buffer_t              *buffer,
                    hb_buffer_content_type_t  content_type)
            hb_buffer_set_content_type;

    hb_buffer_content_type_t function (hb_buffer_t *buffer)
            hb_buffer_get_content_type;


    void function (hb_buffer_t        *buffer,
                    hb_unicode_funcs_t *unicode_funcs)
            hb_buffer_set_unicode_funcs;

    hb_unicode_funcs_t * function (hb_buffer_t        *buffer)
            hb_buffer_get_unicode_funcs;

    void function (hb_buffer_t    *buffer,
                hb_direction_t  direction)
            hb_buffer_set_direction;

    hb_direction_t function (hb_buffer_t *buffer)
            hb_buffer_get_direction;

    void function (hb_buffer_t *buffer,
                hb_script_t  script)
            hb_buffer_set_script;

    hb_script_t function (hb_buffer_t *buffer)
            hb_buffer_get_script;

    void function (hb_buffer_t   *buffer,
                hb_language_t  language)
            hb_buffer_set_language;


    hb_language_t function (hb_buffer_t *buffer)
            hb_buffer_get_language;

    void function (hb_buffer_t *buffer,
                    const(hb_segment_properties_t)* props)
            hb_buffer_set_segment_properties;

    void function (hb_buffer_t *buffer,
                    hb_segment_properties_t *props)
            hb_buffer_get_segment_properties;

    void function (hb_buffer_t *buffer)
            hb_buffer_guess_segment_properties;


    void function (hb_buffer_t       *buffer,
                hb_buffer_flags_t  flags)
            hb_buffer_set_flags;

    hb_buffer_flags_t function (hb_buffer_t *buffer)
            hb_buffer_get_flags;


    void function (hb_buffer_t               *buffer,
                    hb_buffer_cluster_level_t  cluster_level)
            hb_buffer_set_cluster_level;

    hb_buffer_cluster_level_t function (hb_buffer_t *buffer)
            hb_buffer_get_cluster_level;


    void function (hb_buffer_t    *buffer,
                        hb_codepoint_t  replacement)
            hb_buffer_set_replacement_codepoint;

    hb_codepoint_t function (hb_buffer_t    *buffer)
            hb_buffer_get_replacement_codepoint;


    void function (hb_buffer_t *buffer)
            hb_buffer_reset;

    void function (hb_buffer_t *buffer)
            hb_buffer_clear_contents;

    hb_bool_t function (hb_buffer_t  *buffer,
                    uint  size)
            hb_buffer_pre_allocate;


    hb_bool_t function (hb_buffer_t  *buffer)
            hb_buffer_allocation_successful;

    void function (hb_buffer_t *buffer)
            hb_buffer_reverse;

    void function (hb_buffer_t *buffer,
                uint start, uint end)
            hb_buffer_reverse_range;

    void function (hb_buffer_t *buffer)
            hb_buffer_reverse_clusters;


    void function (hb_buffer_t    *buffer,
            hb_codepoint_t  codepoint,
            uint    cluster)
            hb_buffer_add;

    void function (hb_buffer_t  *buffer,
                const(char)* text,
                int           text_length,
                uint  item_offset,
                int           item_length)
            hb_buffer_add_utf8;

    void function (hb_buffer_t    *buffer,
                const(wchar)* text,
                int             text_length,
                uint    item_offset,
                int             item_length)
            hb_buffer_add_utf16;

    void function (hb_buffer_t    *buffer,
                const(dchar)* text,
                int             text_length,
                uint    item_offset,
                int             item_length)
            hb_buffer_add_utf32;

    void function (hb_buffer_t   *buffer,
                const(char)* text,
                int            text_length,
                uint   item_offset,
                int            item_length)
            hb_buffer_add_latin1;

    void function (hb_buffer_t          *buffer,
                const(hb_codepoint_t)* text,
                int                   text_length,
                uint          item_offset,
                int                   item_length)
            hb_buffer_add_codepoints;


    hb_bool_t function (hb_buffer_t  *buffer,
                uint  length)
            hb_buffer_set_length;

    uint function (hb_buffer_t *buffer)
            hb_buffer_get_length;


    hb_glyph_info_t * function (hb_buffer_t  *buffer,
                            uint *length)
            hb_buffer_get_glyph_infos;

    hb_glyph_position_t * function (hb_buffer_t  *buffer,
                                uint *length)
            hb_buffer_get_glyph_positions;


    void function (hb_buffer_t *buffer)
            hb_buffer_normalize_glyphs;



    hb_buffer_serialize_format_t function (const(char)* str, int len)
            hb_buffer_serialize_format_from_string;

    const(char)* function (hb_buffer_serialize_format_t format)
            hb_buffer_serialize_format_to_string;

    const(char)* * function ()
            hb_buffer_serialize_list_formats;

    uint function (hb_buffer_t *buffer,
                    uint start,
                    uint end,
                    char *buf,
                    uint buf_size,
                    uint *buf_consumed,
                    hb_font_t *font,
                    hb_buffer_serialize_format_t format,
                    hb_buffer_serialize_flags_t flags)
            hb_buffer_serialize_glyphs;

    hb_bool_t function (hb_buffer_t *buffer,
                    const(char)* buf,
                    int buf_len,
                    const(char)* *end_ptr,
                    hb_font_t *font,
                    hb_buffer_serialize_format_t format)
            hb_buffer_deserialize_glyphs;



    void function (hb_buffer_t *buffer,
                    hb_buffer_message_func_t func,
                    void *user_data, hb_destroy_func_t destroy)
            hb_buffer_set_message_func;

    // hb-common.h

    hb_tag_t function (const(char)* str, int len)
            hb_tag_from_string;

    void function (hb_tag_t tag, char* buf)
            hb_tag_to_string;

    hb_direction_t function (const(char)* str, int len)
            hb_direction_from_string;

    const(char)* function (hb_direction_t direction)
            hb_direction_to_string;

    hb_language_t function (const(char)* str, int len)
            hb_language_from_string;

    const(char)* function (hb_language_t language)
            hb_language_to_string;

    hb_language_t function ()
            hb_language_get_default;

    hb_script_t function (hb_tag_t tag)
            hb_script_from_iso15924_tag;

    hb_script_t function (const(char)* str, int len)
            hb_script_from_string;

    hb_tag_t function (hb_script_t script)
            hb_script_to_iso15924_tag;

    hb_direction_t function (hb_script_t script)
            hb_script_get_horizontal_direction;

    // hb-face.h


    hb_face_t * function (hb_blob_t    *blob,
            uint  index)
            hb_face_create;


    hb_face_t * function (hb_reference_table_func_t  reference_table_func,
                void                      *user_data,
                hb_destroy_func_t          destroy)
            hb_face_create_for_tables;

    hb_face_t * function ()
            hb_face_get_empty;

    hb_face_t * function (hb_face_t *face)
            hb_face_reference;

    void function (hb_face_t *face)
            hb_face_destroy;

    hb_bool_t function (hb_face_t          *face,
                hb_user_data_key_t *key,
                void *              data,
                hb_destroy_func_t   destroy,
                hb_bool_t           replace)
            hb_face_set_user_data;


    void * function (hb_face_t          *face,
                hb_user_data_key_t *key)
            hb_face_get_user_data;

    void function (hb_face_t *face)
            hb_face_make_immutable;

    hb_bool_t function (hb_face_t *face)
            hb_face_is_immutable;


    hb_blob_t * function (hb_face_t *face,
                hb_tag_t   tag)
            hb_face_reference_table;

    hb_blob_t * function (hb_face_t *face)
            hb_face_reference_blob;

    void function (hb_face_t    *face,
            uint  index)
            hb_face_set_index;

    uint function (hb_face_t    *face)
            hb_face_get_index;

    void function (hb_face_t    *face,
            uint  upem)
            hb_face_set_upem;

    uint function (hb_face_t *face)
            hb_face_get_upem;

    void function (hb_face_t    *face,
                uint  glyph_count)
            hb_face_set_glyph_count;

    uint function (hb_face_t *face)
            hb_face_get_glyph_count;


    // hb-font.h


    hb_font_funcs_t * function ()
            hb_font_funcs_create;

    hb_font_funcs_t * function ()
            hb_font_funcs_get_empty;

    hb_font_funcs_t * function (hb_font_funcs_t *ffuncs)
            hb_font_funcs_reference;

    void function (hb_font_funcs_t *ffuncs)
            hb_font_funcs_destroy;

    hb_bool_t function (hb_font_funcs_t    *ffuncs,
                    hb_user_data_key_t *key,
                    void *              data,
                    hb_destroy_func_t   destroy,
                    hb_bool_t           replace)
            hb_font_funcs_set_user_data;


    void * function (hb_font_funcs_t    *ffuncs,
                    hb_user_data_key_t *key)
            hb_font_funcs_get_user_data;


    void function (hb_font_funcs_t *ffuncs)
            hb_font_funcs_make_immutable;

    hb_bool_t function (hb_font_funcs_t *ffuncs)
            hb_font_funcs_is_immutable;




    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_font_h_extents_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_font_h_extents_func;


    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_font_v_extents_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_font_v_extents_func;


    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_nominal_glyph_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_nominal_glyph_func;


    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_variation_glyph_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_variation_glyph_func;


    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_h_advance_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_glyph_h_advance_func;


    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_v_advance_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_glyph_v_advance_func;


    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_h_origin_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_glyph_h_origin_func;


    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_v_origin_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_glyph_v_origin_func;


    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_h_kerning_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_glyph_h_kerning_func;


    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_v_kerning_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_glyph_v_kerning_func;


    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_extents_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_glyph_extents_func;

    void function (hb_font_funcs_t *ffuncs,
                            hb_font_get_glyph_contour_point_func_t func,
                            void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_glyph_contour_point_func;

    void function (hb_font_funcs_t *ffuncs,
                    hb_font_get_glyph_name_func_t func,
                    void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_glyph_name_func;

    void function (hb_font_funcs_t *ffuncs,
                        hb_font_get_glyph_from_name_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_font_funcs_set_glyph_from_name_func;

    hb_bool_t function (hb_font_t *font,
                hb_font_extents_t *extents)
            hb_font_get_h_extents;
    hb_bool_t function (hb_font_t *font,
                hb_font_extents_t *extents)
            hb_font_get_v_extents;

    hb_bool_t function (hb_font_t *font,
                hb_codepoint_t unicode,
                hb_codepoint_t *glyph)
            hb_font_get_nominal_glyph;
    hb_bool_t function (hb_font_t *font,
                    hb_codepoint_t unicode, hb_codepoint_t variation_selector,
                    hb_codepoint_t *glyph)
            hb_font_get_variation_glyph;

    hb_position_t function (hb_font_t *font,
                    hb_codepoint_t glyph)
            hb_font_get_glyph_h_advance;
    hb_position_t function (hb_font_t *font,
                    hb_codepoint_t glyph)
            hb_font_get_glyph_v_advance;

    hb_bool_t function (hb_font_t *font,
                    hb_codepoint_t glyph,
                    hb_position_t *x, hb_position_t *y)
            hb_font_get_glyph_h_origin;
    hb_bool_t function (hb_font_t *font,
                    hb_codepoint_t glyph,
                    hb_position_t *x, hb_position_t *y)
            hb_font_get_glyph_v_origin;

    hb_position_t function (hb_font_t *font,
                    hb_codepoint_t left_glyph, hb_codepoint_t right_glyph)
            hb_font_get_glyph_h_kerning;
    hb_position_t function (hb_font_t *font,
                    hb_codepoint_t top_glyph, hb_codepoint_t bottom_glyph)
            hb_font_get_glyph_v_kerning;

    hb_bool_t function (hb_font_t *font,
                hb_codepoint_t glyph,
                hb_glyph_extents_t *extents)
            hb_font_get_glyph_extents;

    hb_bool_t function (hb_font_t *font,
                    hb_codepoint_t glyph, uint point_index,
                    hb_position_t *x, hb_position_t *y)
            hb_font_get_glyph_contour_point;

    hb_bool_t function (hb_font_t *font,
                hb_codepoint_t glyph,
                char *name, uint size)
            hb_font_get_glyph_name;
    hb_bool_t function (hb_font_t *font,
                    const(char)* name, int len,
                    hb_codepoint_t *glyph)
            hb_font_get_glyph_from_name;





    hb_bool_t function (hb_font_t *font,
            hb_codepoint_t unicode, hb_codepoint_t variation_selector,
            hb_codepoint_t *glyph)
            hb_font_get_glyph;

    void function (hb_font_t *font,
                    hb_direction_t direction,
                    hb_font_extents_t *extents)
            hb_font_get_extents_for_direction;
    void function (hb_font_t *font,
                        hb_codepoint_t glyph,
                        hb_direction_t direction,
                        hb_position_t *x, hb_position_t *y)
            hb_font_get_glyph_advance_for_direction;
    void function (hb_font_t *font,
                        hb_codepoint_t glyph,
                        hb_direction_t direction,
                        hb_position_t *x, hb_position_t *y)
            hb_font_get_glyph_origin_for_direction;
    void function (hb_font_t *font,
                        hb_codepoint_t glyph,
                        hb_direction_t direction,
                        hb_position_t *x, hb_position_t *y)
            hb_font_add_glyph_origin_for_direction;
    void function (hb_font_t *font,
                            hb_codepoint_t glyph,
                            hb_direction_t direction,
                            hb_position_t *x, hb_position_t *y)
            hb_font_subtract_glyph_origin_for_direction;

    void function (hb_font_t *font,
                        hb_codepoint_t first_glyph, hb_codepoint_t second_glyph,
                        hb_direction_t direction,
                        hb_position_t *x, hb_position_t *y)
            hb_font_get_glyph_kerning_for_direction;

    hb_bool_t function (hb_font_t *font,
                        hb_codepoint_t glyph,
                        hb_direction_t direction,
                        hb_glyph_extents_t *extents)
            hb_font_get_glyph_extents_for_origin;

    hb_bool_t function (hb_font_t *font,
                            hb_codepoint_t glyph, uint point_index,
                            hb_direction_t direction,
                            hb_position_t *x, hb_position_t *y)
            hb_font_get_glyph_contour_point_for_origin;


    void function (hb_font_t *font,
                hb_codepoint_t glyph,
                char *s, uint size)
            hb_font_glyph_to_string;

    hb_bool_t function (hb_font_t *font,
                const(char)* s, int len,
                hb_codepoint_t *glyph)
            hb_font_glyph_from_string;






    hb_font_t * function (hb_face_t *face)
            hb_font_create;

    hb_font_t * function (hb_font_t *parent)
            hb_font_create_sub_font;

    hb_font_t * function ()
            hb_font_get_empty;

    hb_font_t * function (hb_font_t *font)
            hb_font_reference;

    void function (hb_font_t *font)
            hb_font_destroy;

    hb_bool_t function (hb_font_t          *font,
                hb_user_data_key_t *key,
                void *              data,
                hb_destroy_func_t   destroy,
                hb_bool_t           replace)
            hb_font_set_user_data;


    void * function (hb_font_t          *font,
                hb_user_data_key_t *key)
            hb_font_get_user_data;

    void function (hb_font_t *font)
            hb_font_make_immutable;

    hb_bool_t function (hb_font_t *font)
            hb_font_is_immutable;

    void function (hb_font_t *font,
                hb_font_t *parent)
            hb_font_set_parent;

    hb_font_t * function (hb_font_t *font)
            hb_font_get_parent;

    hb_face_t * function (hb_font_t *font)
            hb_font_get_face;


    void function (hb_font_t         *font,
            hb_font_funcs_t   *klass,
            void              *font_data,
            hb_destroy_func_t  destroy)
            hb_font_set_funcs;


    void function (hb_font_t         *font,
                    void              *font_data,
                    hb_destroy_func_t  destroy)
            hb_font_set_funcs_data;


    void function (hb_font_t *font,
            int x_scale,
            int y_scale)
            hb_font_set_scale;

    void function (hb_font_t *font,
            int *x_scale,
            int *y_scale)
            hb_font_get_scale;


    void function (hb_font_t *font,
            uint x_ppem,
            uint y_ppem)
            hb_font_set_ppem;

    void function (hb_font_t *font,
            uint *x_ppem,
            uint *y_ppem)
            hb_font_get_ppem;


    void function (hb_font_t *font,
                    int *coords,
                    uint coords_length)
            hb_font_set_var_coords_normalized;

    // hb-set.h


    hb_set_t * function ()
            hb_set_create;

    hb_set_t * function ()
            hb_set_get_empty;

    hb_set_t * function (hb_set_t *set)
            hb_set_reference;

    void function (hb_set_t *set)
            hb_set_destroy;

    hb_bool_t function (hb_set_t           *set,
                hb_user_data_key_t *key,
                void *              data,
                hb_destroy_func_t   destroy,
                hb_bool_t           replace)
            hb_set_set_user_data;

    void * function (hb_set_t           *set,
                hb_user_data_key_t *key)
            hb_set_get_user_data;



    hb_bool_t function (const(hb_set_t)* set)
            hb_set_allocation_successful;

    void function (hb_set_t *set)
            hb_set_clear;

    hb_bool_t function (const(hb_set_t)* set)
            hb_set_is_empty;

    hb_bool_t function (const(hb_set_t)* set,
            hb_codepoint_t  codepoint)
            hb_set_has;


    void function (hb_set_t       *set,
            hb_codepoint_t  codepoint)
            hb_set_add;

    void function (hb_set_t       *set,
            hb_codepoint_t  first,
            hb_codepoint_t  last)
            hb_set_add_range;

    void function (hb_set_t       *set,
            hb_codepoint_t  codepoint)
            hb_set_del;

    void function (hb_set_t       *set,
            hb_codepoint_t  first,
            hb_codepoint_t  last)
            hb_set_del_range;

    hb_bool_t function (const(hb_set_t)* set,
            const(hb_set_t)* other)
            hb_set_is_equal;

    void function (hb_set_t       *set,
            const(hb_set_t)* other)
            hb_set_set;

    void function (hb_set_t       *set,
            const(hb_set_t)* other)
            hb_set_union;

    void function (hb_set_t       *set,
            const(hb_set_t)* other)
            hb_set_intersect;

    void function (hb_set_t       *set,
            const(hb_set_t)* other)
            hb_set_subtract;

    void function (hb_set_t       *set,
                    const(hb_set_t)* other)
            hb_set_symmetric_difference;

    void function (hb_set_t *set)
            hb_set_invert;

    uint function (const(hb_set_t)* set)
            hb_set_get_population;


    hb_codepoint_t function (const(hb_set_t)* set)
            hb_set_get_min;


    hb_codepoint_t function (const(hb_set_t)* set)
            hb_set_get_max;


    hb_bool_t function (const(hb_set_t)* set,
            hb_codepoint_t *codepoint)
            hb_set_next;


    hb_bool_t function (const(hb_set_t)* set,
            hb_codepoint_t *first,
            hb_codepoint_t *last)
            hb_set_next_range;

    // hb-shape.h


    hb_bool_t function (const(char)* str, int len,
                hb_feature_t *feature)
            hb_feature_from_string;

    void function (hb_feature_t *feature,
                char *buf, uint size)
            hb_feature_to_string;


    void function (hb_font_t           *font,
        hb_buffer_t         *buffer,
        const(hb_feature_t)* features,
        uint         num_features)
            hb_shape;

    hb_bool_t function (hb_font_t          *font,
            hb_buffer_t        *buffer,
            const(hb_feature_t)* features,
            uint        num_features,
            const(char*)* shaper_list)
            hb_shape_full;

    const(char)* * function ()
            hb_shape_list_shapers;

    // hb-shape-plan.h


    hb_shape_plan_t * function (hb_face_t                     *face,
                const(hb_segment_properties_t)* props,
                const(hb_feature_t)* user_features,
                uint                   num_user_features,
                const(char*)* shaper_list)
            hb_shape_plan_create;

    hb_shape_plan_t * function (hb_face_t                     *face,
                    const(hb_segment_properties_t)* props,
                    const(hb_feature_t)* user_features,
                    uint                   num_user_features,
                    const(char*)* shaper_list)
            hb_shape_plan_create_cached;

    hb_shape_plan_t * function (hb_face_t                     *face,
                const(hb_segment_properties_t)* props,
                const(hb_feature_t)* user_features,
                uint                   num_user_features,
                const(int)* coords,
                uint                   num_coords,
                const(char*)* shaper_list)
            hb_shape_plan_create2;

    hb_shape_plan_t * function (hb_face_t                     *face,
                    const(hb_segment_properties_t)* props,
                    const(hb_feature_t)* user_features,
                    uint                   num_user_features,
                    const(int)* coords,
                    uint                   num_coords,
                    const(char*)* shaper_list)
            hb_shape_plan_create_cached2;


    hb_shape_plan_t * function ()
            hb_shape_plan_get_empty;

    hb_shape_plan_t * function (hb_shape_plan_t *shape_plan)
            hb_shape_plan_reference;

    void function (hb_shape_plan_t *shape_plan)
            hb_shape_plan_destroy;

    hb_bool_t function (hb_shape_plan_t    *shape_plan,
                    hb_user_data_key_t *key,
                    void *              data,
                    hb_destroy_func_t   destroy,
                    hb_bool_t           replace)
            hb_shape_plan_set_user_data;

    void * function (hb_shape_plan_t    *shape_plan,
                    hb_user_data_key_t *key)
            hb_shape_plan_get_user_data;


    hb_bool_t function (hb_shape_plan_t    *shape_plan,
                hb_font_t          *font,
                hb_buffer_t        *buffer,
                const(hb_feature_t)* features,
                uint        num_features)
            hb_shape_plan_execute;

    const(char)* function (hb_shape_plan_t *shape_plan)
            hb_shape_plan_get_shaper;

    // hb-unicode.h

    hb_unicode_funcs_t * function ()
            hb_unicode_funcs_get_default;


    hb_unicode_funcs_t * function (hb_unicode_funcs_t *parent)
            hb_unicode_funcs_create;

    hb_unicode_funcs_t * function ()
            hb_unicode_funcs_get_empty;

    hb_unicode_funcs_t * function (hb_unicode_funcs_t *ufuncs)
            hb_unicode_funcs_reference;

    void function (hb_unicode_funcs_t *ufuncs)
            hb_unicode_funcs_destroy;

    hb_bool_t function (hb_unicode_funcs_t *ufuncs,
                        hb_user_data_key_t *key,
                        void *              data,
                        hb_destroy_func_t   destroy,
                    hb_bool_t           replace)
            hb_unicode_funcs_set_user_data;


    void * function (hb_unicode_funcs_t *ufuncs,
                        hb_user_data_key_t *key)
            hb_unicode_funcs_get_user_data;


    void function (hb_unicode_funcs_t *ufuncs)
            hb_unicode_funcs_make_immutable;

    hb_bool_t function (hb_unicode_funcs_t *ufuncs)
            hb_unicode_funcs_is_immutable;

    hb_unicode_funcs_t * function (hb_unicode_funcs_t *ufuncs)
            hb_unicode_funcs_get_parent;





    void function (hb_unicode_funcs_t *ufuncs,
                        hb_unicode_combining_class_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_unicode_funcs_set_combining_class_func;


    void function (hb_unicode_funcs_t *ufuncs,
                        hb_unicode_eastasian_width_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_unicode_funcs_set_eastasian_width_func;


    void function (hb_unicode_funcs_t *ufuncs,
                            hb_unicode_general_category_func_t func,
                            void *user_data, hb_destroy_func_t destroy)
            hb_unicode_funcs_set_general_category_func;


    void function (hb_unicode_funcs_t *ufuncs,
                        hb_unicode_mirroring_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_unicode_funcs_set_mirroring_func;


    void function (hb_unicode_funcs_t *ufuncs,
                    hb_unicode_script_func_t func,
                    void *user_data, hb_destroy_func_t destroy)
            hb_unicode_funcs_set_script_func;


    void function (hb_unicode_funcs_t *ufuncs,
                    hb_unicode_compose_func_t func,
                    void *user_data, hb_destroy_func_t destroy)
            hb_unicode_funcs_set_compose_func;


    void function (hb_unicode_funcs_t *ufuncs,
                        hb_unicode_decompose_func_t func,
                        void *user_data, hb_destroy_func_t destroy)
            hb_unicode_funcs_set_decompose_func;


    void function (hb_unicode_funcs_t *ufuncs,
                            hb_unicode_decompose_compatibility_func_t func,
                            void *user_data, hb_destroy_func_t destroy)
            hb_unicode_funcs_set_decompose_compatibility_func;




    hb_unicode_combining_class_t function (hb_unicode_funcs_t *ufuncs,
                    hb_codepoint_t unicode)
            hb_unicode_combining_class;


    uint function (hb_unicode_funcs_t *ufuncs,
                    hb_codepoint_t unicode)
            hb_unicode_eastasian_width;


    hb_unicode_general_category_t function (hb_unicode_funcs_t *ufuncs,
                    hb_codepoint_t unicode)
            hb_unicode_general_category;


    hb_codepoint_t function (hb_unicode_funcs_t *ufuncs,
                hb_codepoint_t unicode)
            hb_unicode_mirroring;


    hb_script_t function (hb_unicode_funcs_t *ufuncs,
            hb_codepoint_t unicode)
            hb_unicode_script;

    hb_bool_t function (hb_unicode_funcs_t *ufuncs,
                hb_codepoint_t      a,
                hb_codepoint_t      b,
                hb_codepoint_t     *ab)
            hb_unicode_compose;

    hb_bool_t function (hb_unicode_funcs_t *ufuncs,
                hb_codepoint_t      ab,
                hb_codepoint_t     *a,
                hb_codepoint_t     *b)
            hb_unicode_decompose;

    uint function (hb_unicode_funcs_t *ufuncs,
                        hb_codepoint_t      u,
                        hb_codepoint_t     *decomposed)
            hb_unicode_decompose_compatibility;

    // hb-version.h


    void function (uint *major,
            uint *minor,
            uint *micro)
            hb_version;

    const(char)* function ()
            hb_version_string;

    hb_bool_t function (uint major,
                uint minor,
                uint micro)
            hb_version_atleast;

    // hb-ft.h

    hb_face_t * function (FT_Face           ft_face,
                    hb_destroy_func_t destroy)
            hb_ft_face_create;

    hb_face_t * function (FT_Face ft_face)
            hb_ft_face_create_cached;

    hb_face_t * function (FT_Face ft_face)
            hb_ft_face_create_referenced;

    hb_font_t * function (FT_Face           ft_face,
                    hb_destroy_func_t destroy)
            hb_ft_font_create;

    hb_font_t * function (FT_Face ft_face)
            hb_ft_font_create_referenced;

    FT_Face function (hb_font_t *font)
            hb_ft_font_get_face;

    void function (hb_font_t *font, int load_flags)
            hb_ft_font_set_load_flags;

    int function (hb_font_t *font)
            hb_ft_font_get_load_flags;

    void function (hb_font_t *font)
            hb_ft_font_set_funcs;


}
