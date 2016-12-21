module dgt.bindings.cairo.types;

import dgt.bindings.cairo.enums;

import core.stdc.config : c_long, c_ulong;

extern (C) nothrow @nogc:


alias cairo_bool_t = int;

struct cairo_t;

struct cairo_surface_t;

struct cairo_device_t;

struct cairo_matrix_t
{
    double xx;
    double yx;
    double xy;
    double yy;
    double x0;
    double y0;
}

struct cairo_pattern_t;

alias cairo_destroy_func_t = void function(void* data);

struct cairo_user_data_key_t
{
    int unused;
}

alias cairo_write_func_t = cairo_status_t function(void* closure, const(ubyte)* data, uint length);

alias cairo_read_func_t = cairo_status_t function(void* closure, ubyte* data, uint length);


struct cairo_rectangle_int_t
{
    int x, y;
    int width, height;
}

struct cairo_rectangle_t
{
    double x, y, width, height;
}

struct cairo_rectangle_list_t
{
    cairo_status_t status;
    cairo_rectangle_t* rectangles;
    int num_rectangles;
}

struct cairo_scaled_font_t;

struct cairo_font_face_t;

struct cairo_glyph_t
{
    c_ulong index;
    double x;
    double y;
}

struct cairo_text_cluster_t
{
    int num_bytes;
    int num_glyphs;
}

struct cairo_text_extents_t
{
    double x_bearing;
    double y_bearing;
    double width;
    double height;
    double x_advance;
    double y_advance;
}

struct cairo_font_extents_t
{
    double ascent;
    double descent;
    double height;
    double max_x_advance;
    double max_y_advance;
}

struct cairo_font_options_t;

alias cairo_user_scaled_font_init_func_t = cairo_status_t function(
        cairo_scaled_font_t* scaled_font, cairo_t* cr, cairo_font_extents_t* extents);

alias cairo_user_scaled_font_render_glyph_func_t = cairo_status_t function(
        cairo_scaled_font_t* scaled_font, c_ulong glyph, cairo_t* cr,
        cairo_text_extents_t* extents);

alias cairo_user_scaled_font_text_to_glyphs_func_t = cairo_status_t function(
        cairo_scaled_font_t* scaled_font, const char* utf8, int utf8_len,
        cairo_glyph_t** glyphs, int* num_glyphs, cairo_text_cluster_t** clusters,
        int* num_clusters, cairo_text_cluster_flags_t* cluster_flags);

alias cairo_user_scaled_font_unicode_to_glyph_func_t = cairo_status_t function(
        cairo_scaled_font_t* scaled_font, c_ulong unicode, c_ulong* glyph_index);

union cairo_path_data_t
{
    struct header_t
    {
        cairo_path_data_type_t type;
        int length;
    }

    struct point_t
    {
        double x, y;
    }

    header_t header;
    point_t point;
}

struct cairo_path_t
{
    cairo_status_t status;
    cairo_path_data_t* data;
    int num_data;
}

alias cairo_surface_observer_callback_t = void function(cairo_surface_t* observer,
        cairo_surface_t* target, void* data);

alias cairo_raster_source_acquire_func_t = cairo_surface_t* function(cairo_pattern_t* pattern,
        void* callback_data, cairo_surface_t* target, const cairo_rectangle_int_t* extents);

alias cairo_raster_source_release_func_t = void function(cairo_pattern_t* pattern,
        void* callback_data, cairo_surface_t* surface);

alias cairo_raster_source_snapshot_func_t = cairo_status_t function(
        cairo_pattern_t* pattern, void* callback_data);

alias cairo_raster_source_copy_func_t = cairo_status_t function(
        cairo_pattern_t* pattern, void* callback_data, const cairo_pattern_t* other);

alias cairo_raster_source_finish_func_t = void function(cairo_pattern_t* pattern,
        void* callback_data);

struct cairo_region_t;
