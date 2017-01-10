module dgt.bindings.cairo.symbols;

import dgt.bindings.cairo.enums;
import dgt.bindings.cairo.types;

import core.stdc.config : c_ulong;


extern(C) nothrow @nogc __gshared
{
    int function ()
            cairo_version;

    const(char)* function ()
            cairo_version_string;

    cairo_t* function (cairo_surface_t* target)
            cairo_create;

    cairo_t* function (cairo_t* cr)
            cairo_reference;

    void function (cairo_t* cr)
            cairo_destroy;

    uint function (cairo_t* cr)
            cairo_get_reference_count;

    void* function (cairo_t* cr,
                 const(cairo_user_data_key_t)* key)
            cairo_get_user_data;

    cairo_status_t function (cairo_t* cr,
                 const(cairo_user_data_key_t)* key,
                 void* user_data,
                 cairo_destroy_func_t	  destroy)
            cairo_set_user_data;

    void function (cairo_t* cr)
            cairo_save;

    void function (cairo_t* cr)
            cairo_restore;

    void function (cairo_t* cr)
            cairo_push_group;

    void function (cairo_t* cr, cairo_content_t content)
            cairo_push_group_with_content;

    cairo_pattern_t* function (cairo_t* cr)
            cairo_pop_group;

    void function (cairo_t* cr)
            cairo_pop_group_to_source;


    void function (cairo_t* cr, cairo_operator_t op)
            cairo_set_operator;

    void function (cairo_t* cr, cairo_pattern_t* source)
            cairo_set_source;

    void function (cairo_t* cr, double red, double green, double blue)
            cairo_set_source_rgb;

    void function (cairo_t* cr,
                   double red, double green, double blue,
                   double alpha)
            cairo_set_source_rgba;

    void function (cairo_t* cr,
                  cairo_surface_t* surface,
                  double	   x,
                  double	   y)
            cairo_set_source_surface;

    void function (cairo_t* cr, double tolerance)
            cairo_set_tolerance;


    void function (cairo_t *cr, cairo_antialias_t antialias)
            cairo_set_antialias;

    void function (cairo_t* cr, cairo_fill_rule_t fill_rule)
            cairo_set_fill_rule;

    void function (cairo_t* cr, double width)
            cairo_set_line_width;

    void function (cairo_t* cr, cairo_line_cap_t line_cap)
            cairo_set_line_cap;

    void function (cairo_t* cr, cairo_line_join_t line_join)
            cairo_set_line_join;

    void function (cairo_t* cr,
            const(double)* dashes,
            int	      num_dashes,
            double	      offset)
            cairo_set_dash;

    void function (cairo_t* cr, double limit)
            cairo_set_miter_limit;

    void function (cairo_t* cr, double tx, double ty)
            cairo_translate;

    void function (cairo_t* cr, double sx, double sy)
            cairo_scale;

    void function (cairo_t* cr, double angle)
            cairo_rotate;

    void function (cairo_t* cr,
             const(cairo_matrix_t)* matrix)
            cairo_transform;

    void function (cairo_t* cr,
              const(cairo_matrix_t)* matrix)
            cairo_set_matrix;

    void function (cairo_t* cr)
            cairo_identity_matrix;

    void function (cairo_t* cr, double* x, double* y)
            cairo_user_to_device;

    void function (cairo_t* cr, double* dx, double* dy)
            cairo_user_to_device_distance;

    void function (cairo_t* cr, double* x, double* y)
            cairo_device_to_user;

    void function (cairo_t* cr, double* dx, double* dy)
            cairo_device_to_user_distance;

    void function (cairo_t* cr)
            cairo_new_path;

    void function (cairo_t* cr, double x, double y)
            cairo_move_to;

    void function (cairo_t* cr)
            cairo_new_sub_path;

    void function (cairo_t* cr, double x, double y)
            cairo_line_to;

    void function (cairo_t* cr,
            double x1, double y1,
            double x2, double y2,
            double x3, double y3)
            cairo_curve_to;

    void function (cairo_t* cr,
           double xc, double yc,
           double radius,
           double angle1, double angle2)
            cairo_arc;

    void function (cairo_t* cr,
                double xc, double yc,
                double radius,
                double angle1, double angle2)
            cairo_arc_negative;


    void function (cairo_t* cr, double dx, double dy)
            cairo_rel_move_to;

    void function (cairo_t* cr, double dx, double dy)
            cairo_rel_line_to;

    void function (cairo_t* cr,
                double dx1, double dy1,
                double dx2, double dy2,
                double dx3, double dy3)
            cairo_rel_curve_to;

    void function (cairo_t* cr,
             double x, double y,
             double width, double height)
            cairo_rectangle;


    void function (cairo_t* cr)
            cairo_close_path;

    void function (cairo_t* cr,
                double* x1, double* y1,
                double* x2, double* y2)
            cairo_path_extents;

    void function (cairo_t* cr)
            cairo_paint;

    void function (cairo_t* cr,
                double   alpha)
            cairo_paint_with_alpha;

    void function (cairo_t* cr,
            cairo_pattern_t* pattern)
            cairo_mask;

    void function (cairo_t* cr,
                cairo_surface_t* surface,
                double           surface_x,
                double           surface_y)
            cairo_mask_surface;

    void function (cairo_t* cr)
            cairo_stroke;

    void function (cairo_t* cr)
            cairo_stroke_preserve;

    void function (cairo_t* cr)
            cairo_fill;

    void function (cairo_t* cr)
            cairo_fill_preserve;

    void function (cairo_t* cr)
            cairo_copy_page;

    void function (cairo_t* cr)
            cairo_show_page;

    cairo_bool_t function (cairo_t* cr, double x, double y)
            cairo_in_stroke;

    cairo_bool_t function (cairo_t* cr, double x, double y)
            cairo_in_fill;

    cairo_bool_t function (cairo_t* cr, double x, double y)
            cairo_in_clip;

    void function (cairo_t* cr,
                  double* x1, double* y1,
                  double* x2, double* y2)
            cairo_stroke_extents;

    void function (cairo_t* cr,
                double* x1, double* y1,
                double* x2, double* y2)
            cairo_fill_extents;

    void function (cairo_t* cr)
            cairo_reset_clip;

    void function (cairo_t* cr)
            cairo_clip;

    void function (cairo_t* cr)
            cairo_clip_preserve;

    void function (cairo_t* cr,
                double* x1, double* y1,
                double* x2, double* y2)
            cairo_clip_extents;


    cairo_rectangle_list_t* function (cairo_t* cr)
            cairo_copy_clip_rectangle_list;

    void function (cairo_rectangle_list_t* rectangle_list)
            cairo_rectangle_list_destroy;


    cairo_glyph_t* function (int num_glyphs)
            cairo_glyph_allocate;

    void function (cairo_glyph_t* glyphs)
            cairo_glyph_free;

    cairo_text_cluster_t* function (int num_clusters)
            cairo_text_cluster_allocate;

    void function (cairo_text_cluster_t* clusters)
            cairo_text_cluster_free;


    cairo_font_options_t* function ()
            cairo_font_options_create;

    cairo_font_options_t* function (const(cairo_font_options_t)* original)
            cairo_font_options_copy;

    void function (cairo_font_options_t* options)
            cairo_font_options_destroy;

    cairo_status_t function (cairo_font_options_t* options)
            cairo_font_options_status;

    void function (cairo_font_options_t* options,
                  const(cairo_font_options_t)* other)
            cairo_font_options_merge;
    cairo_bool_t function (const(cairo_font_options_t)* options,
                  const(cairo_font_options_t)* other)
            cairo_font_options_equal;

    c_ulong function (const(cairo_font_options_t)* options)
            cairo_font_options_hash;

    void function (cairo_font_options_t* options,
                      cairo_antialias_t     antialias)
            cairo_font_options_set_antialias;
    cairo_antialias_t function (const(cairo_font_options_t)* options)
            cairo_font_options_get_antialias;

    void function (cairo_font_options_t* options,
                           cairo_subpixel_order_t  subpixel_order)
            cairo_font_options_set_subpixel_order;
    cairo_subpixel_order_t function (const(cairo_font_options_t)* options)
            cairo_font_options_get_subpixel_order;

    void function (cairo_font_options_t* options,
                       cairo_hint_style_t     hint_style)
            cairo_font_options_set_hint_style;
    cairo_hint_style_t function (const(cairo_font_options_t)* options)
            cairo_font_options_get_hint_style;

    void function (cairo_font_options_t* options,
                         cairo_hint_metrics_t  hint_metrics)
            cairo_font_options_set_hint_metrics;
    cairo_hint_metrics_t function (const(cairo_font_options_t)* options)
            cairo_font_options_get_hint_metrics;

    void function (cairo_t* cr,
                const(char)* family,
                cairo_font_slant_t   slant,
                cairo_font_weight_t  weight)
            cairo_select_font_face;

    void function (cairo_t* cr, double size)
            cairo_set_font_size;

    void function (cairo_t* cr,
                   const(cairo_matrix_t)* matrix)
            cairo_set_font_matrix;

    void function (cairo_t* cr,
                   cairo_matrix_t* matrix)
            cairo_get_font_matrix;

    void function (cairo_t* cr,
                const(cairo_font_options_t)* options)
            cairo_set_font_options;

    void function (cairo_t* cr,
                cairo_font_options_t* options)
            cairo_get_font_options;

    void function (cairo_t* cr, cairo_font_face_t* font_face)
            cairo_set_font_face;

    cairo_font_face_t* function (cairo_t* cr)
            cairo_get_font_face;

    void function (cairo_t* cr,
                   const(cairo_scaled_font_t)* scaled_font)
            cairo_set_scaled_font;

    cairo_scaled_font_t* function (cairo_t* cr)
            cairo_get_scaled_font;

    void function (cairo_t* cr, const(char)* utf8)
            cairo_show_text;

    void function (cairo_t* cr, const(cairo_glyph_t)* glyphs, int num_glyphs)
            cairo_show_glyphs;

    void function (cairo_t* cr,
                const(char)* utf8,
                int			    utf8_len,
                const cairo_glyph_t* glyphs,
                int			    num_glyphs,
                const(cairo_text_cluster_t)* clusters,
                int			    num_clusters,
                cairo_text_cluster_flags_t  cluster_flags)
            cairo_show_text_glyphs;

    void function (cairo_t* cr, const(char)* utf8)
            cairo_text_path ;

    void function (cairo_t* cr, const(cairo_glyph_t)* glyphs, int num_glyphs)
            cairo_glyph_path;

    void function (cairo_t* cr,
                const(char)* utf8,
                cairo_text_extents_t* extents)
            cairo_text_extents;

    void function (cairo_t* cr,
                 const cairo_glyph_t* glyphs,
                 int                   num_glyphs,
                 cairo_text_extents_t* extents)
            cairo_glyph_extents;

    void function (cairo_t* cr,
                cairo_font_extents_t* extents)
            cairo_font_extents;


    cairo_font_face_t* function (cairo_font_face_t* font_face)
            cairo_font_face_reference;

    void function (cairo_font_face_t* font_face)
            cairo_font_face_destroy;

    uint function (cairo_font_face_t* font_face)
            cairo_font_face_get_reference_count;

    cairo_status_t function (cairo_font_face_t* font_face)
            cairo_font_face_status;



    cairo_font_type_t function (cairo_font_face_t* font_face)
            cairo_font_face_get_type;

    void* function (cairo_font_face_t* font_face,
                       const(cairo_user_data_key_t)* key)
            cairo_font_face_get_user_data;

    cairo_status_t function (cairo_font_face_t* font_face,
                       const(cairo_user_data_key_t)* key,
                       void* user_data,
                       cairo_destroy_func_t	    destroy)
            cairo_font_face_set_user_data;


    cairo_scaled_font_t* function (cairo_font_face_t* font_face,
                  const cairo_matrix_t* font_matrix,
                  const cairo_matrix_t* ctm,
                  const(cairo_font_options_t)* options)
            cairo_scaled_font_create;

    cairo_scaled_font_t* function (cairo_scaled_font_t* scaled_font)
            cairo_scaled_font_reference;

    void function (cairo_scaled_font_t* scaled_font)
            cairo_scaled_font_destroy;

    uint function (cairo_scaled_font_t* scaled_font)
            cairo_scaled_font_get_reference_count;

    cairo_status_t function (cairo_scaled_font_t* scaled_font)
            cairo_scaled_font_status;

    cairo_font_type_t function (cairo_scaled_font_t* scaled_font)
            cairo_scaled_font_get_type;

    void* function (cairo_scaled_font_t* scaled_font,
                     const(cairo_user_data_key_t)* key)
            cairo_scaled_font_get_user_data;

    cairo_status_t function (cairo_scaled_font_t* scaled_font,
                     const(cairo_user_data_key_t)* key,
                     void* user_data,
                     cairo_destroy_func_t	      destroy)
            cairo_scaled_font_set_user_data;

    void function (cairo_scaled_font_t* scaled_font,
                   cairo_font_extents_t* extents)
            cairo_scaled_font_extents;

    void function (cairo_scaled_font_t* scaled_font,
                    const(char)* utf8,
                    cairo_text_extents_t* extents)
            cairo_scaled_font_text_extents;

    void function (cairo_scaled_font_t* scaled_font,
                     const cairo_glyph_t* glyphs,
                     int                   num_glyphs,
                     cairo_text_extents_t* extents)
            cairo_scaled_font_glyph_extents;

    cairo_status_t function (cairo_scaled_font_t* scaled_font,
                      double		      x,
                      double		      y,
                      const(char)* utf8,
                      int		              utf8_len,
                      cairo_glyph_t* *glyphs,
                      int* num_glyphs,
                      cairo_text_cluster_t* *clusters,
                      int* num_clusters,
                      cairo_text_cluster_flags_t* cluster_flags)
            cairo_scaled_font_text_to_glyphs;

    cairo_font_face_t* function (cairo_scaled_font_t* scaled_font)
            cairo_scaled_font_get_font_face;

    void function (cairo_scaled_font_t* scaled_font,
                       cairo_matrix_t* font_matrix)
            cairo_scaled_font_get_font_matrix;

    void function (cairo_scaled_font_t* scaled_font,
                   cairo_matrix_t* ctm)
            cairo_scaled_font_get_ctm;

    void function (cairo_scaled_font_t* scaled_font,
                        cairo_matrix_t* scale_matrix)
            cairo_scaled_font_get_scale_matrix;

    void function (cairo_scaled_font_t* scaled_font,
                        cairo_font_options_t* options)
            cairo_scaled_font_get_font_options;


    cairo_font_face_t* function (const(char)* family,
                    cairo_font_slant_t    slant,
                    cairo_font_weight_t   weight)
            cairo_toy_font_face_create;

    const(char)* function (cairo_font_face_t* font_face)
            cairo_toy_font_face_get_family;

    cairo_font_slant_t function (cairo_font_face_t* font_face)
            cairo_toy_font_face_get_slant;

    cairo_font_weight_t function (cairo_font_face_t* font_face)
            cairo_toy_font_face_get_weight;



    cairo_font_face_t* function ()
            cairo_user_font_face_create;

    void function (cairo_font_face_t* font_face,
                        cairo_user_scaled_font_init_func_t  init_func)
            cairo_user_font_face_set_init_func;

    void function (cairo_font_face_t* font_face,
                            cairo_user_scaled_font_render_glyph_func_t  render_glyph_func)
            cairo_user_font_face_set_render_glyph_func;

    void function (cairo_font_face_t* font_face,
                              cairo_user_scaled_font_text_to_glyphs_func_t  text_to_glyphs_func)
            cairo_user_font_face_set_text_to_glyphs_func;

    void function (cairo_font_face_t* font_face,
                                cairo_user_scaled_font_unicode_to_glyph_func_t  unicode_to_glyph_func)
            cairo_user_font_face_set_unicode_to_glyph_func;


    cairo_user_scaled_font_init_func_t function (cairo_font_face_t* font_face)
            cairo_user_font_face_get_init_func;

    cairo_user_scaled_font_render_glyph_func_t function (cairo_font_face_t* font_face)
            cairo_user_font_face_get_render_glyph_func;

    cairo_user_scaled_font_text_to_glyphs_func_t function (cairo_font_face_t* font_face)
            cairo_user_font_face_get_text_to_glyphs_func;

    cairo_user_scaled_font_unicode_to_glyph_func_t function (cairo_font_face_t* font_face)
            cairo_user_font_face_get_unicode_to_glyph_func;


    cairo_operator_t function (cairo_t* cr)
            cairo_get_operator;

    cairo_pattern_t* function (cairo_t* cr)
            cairo_get_source;

    double function (cairo_t* cr)
            cairo_get_tolerance;

    cairo_antialias_t function (cairo_t* cr)
            cairo_get_antialias;

    cairo_bool_t function (cairo_t* cr)
            cairo_has_current_point;

    void function (cairo_t* cr, double* x, double* y)
            cairo_get_current_point;

    cairo_fill_rule_t function (cairo_t* cr)
            cairo_get_fill_rule;

    double function (cairo_t* cr)
            cairo_get_line_width;

    cairo_line_cap_t function (cairo_t* cr)
            cairo_get_line_cap;

    cairo_line_join_t function (cairo_t* cr)
            cairo_get_line_join;

    double function (cairo_t* cr)
            cairo_get_miter_limit;

    int function (cairo_t* cr)
            cairo_get_dash_count;

    void function (cairo_t* cr, double* dashes, double* offset)
            cairo_get_dash;

    void function (cairo_t* cr, cairo_matrix_t* matrix)
            cairo_get_matrix;

    cairo_surface_t* function (cairo_t* cr)
            cairo_get_target;

    cairo_surface_t* function (cairo_t* cr)
            cairo_get_group_target;

    cairo_path_t* function (cairo_t* cr)
            cairo_copy_path;

    cairo_path_t* function (cairo_t* cr)
            cairo_copy_path_flat;

    void function (cairo_t* cr,
               const(cairo_path_t)* path)
            cairo_append_path;

    void function (cairo_path_t* path)
            cairo_path_destroy;


    cairo_status_t function (cairo_t* cr)
            cairo_status;

    const(char)* function (cairo_status_t status)
            cairo_status_to_string;


    cairo_device_t* function (cairo_device_t* device)
            cairo_device_reference;


    cairo_device_type_t function (cairo_device_t* device)
            cairo_device_get_type;

    cairo_status_t function (cairo_device_t* device)
            cairo_device_status;

    cairo_status_t function (cairo_device_t* device)
            cairo_device_acquire;

    void function (cairo_device_t* device)
            cairo_device_release;

    void function (cairo_device_t* device)
            cairo_device_flush;

    void function (cairo_device_t* device)
            cairo_device_finish;

    void function (cairo_device_t* device)
            cairo_device_destroy;

    uint function (cairo_device_t* device)
            cairo_device_get_reference_count;

    void* function (cairo_device_t* device,
                    const(cairo_user_data_key_t)* key)
            cairo_device_get_user_data;

    cairo_status_t function (cairo_device_t* device,
                    const(cairo_user_data_key_t)* key,
                    void* user_data,
                    cairo_destroy_func_t	  destroy)
            cairo_device_set_user_data;


    cairo_surface_t* function (cairo_surface_t* other,
                      cairo_content_t	content,
                      int		width,
                      int		height)
            cairo_surface_create_similar;

    cairo_surface_t* function (cairo_surface_t* other,
                        cairo_format_t    format,
                        int		width,
                        int		height)
            cairo_surface_create_similar_image;

    cairo_surface_t* function (cairo_surface_t* surface,
                    const(cairo_rectangle_int_t)* extents)
            cairo_surface_map_to_image;

    void function (cairo_surface_t* surface,
                   cairo_surface_t* image)
            cairo_surface_unmap_image;

    cairo_surface_t* function (cairo_surface_t* target,
                                        double		 x,
                                        double		 y,
                                        double		 width,
                                        double		 height)
            cairo_surface_create_for_rectangle;


    cairo_surface_t* function (cairo_surface_t* target,
                       cairo_surface_observer_mode_t mode)
            cairo_surface_create_observer;

    cairo_status_t function (cairo_surface_t* abstract_surface,
                           cairo_surface_observer_callback_t func,
                           void* data)
            cairo_surface_observer_add_paint_callback;

    cairo_status_t function (cairo_surface_t* abstract_surface,
                          cairo_surface_observer_callback_t func,
                          void* data)
            cairo_surface_observer_add_mask_callback;

    cairo_status_t function (cairo_surface_t* abstract_surface,
                          cairo_surface_observer_callback_t func,
                          void* data)
            cairo_surface_observer_add_fill_callback;

    cairo_status_t function (cairo_surface_t* abstract_surface,
                            cairo_surface_observer_callback_t func,
                            void* data)
            cairo_surface_observer_add_stroke_callback;

    cairo_status_t function (cairo_surface_t* abstract_surface,
                            cairo_surface_observer_callback_t func,
                            void* data)
            cairo_surface_observer_add_glyphs_callback;

    cairo_status_t function (cairo_surface_t* abstract_surface,
                           cairo_surface_observer_callback_t func,
                           void* data)
            cairo_surface_observer_add_flush_callback;

    cairo_status_t function (cairo_surface_t* abstract_surface,
                            cairo_surface_observer_callback_t func,
                            void* data)
            cairo_surface_observer_add_finish_callback;

    cairo_status_t function (cairo_surface_t* surface,
                      cairo_write_func_t write_func,
                      void* closure)
            cairo_surface_observer_print;
    double function (cairo_surface_t* surface)
            cairo_surface_observer_elapsed;

    cairo_status_t function (cairo_device_t* device,
                     cairo_write_func_t write_func,
                     void* closure)
            cairo_device_observer_print;

    double function (cairo_device_t* device)
            cairo_device_observer_elapsed;

    double function (cairo_device_t* device)
            cairo_device_observer_paint_elapsed;

    double function (cairo_device_t* device)
            cairo_device_observer_mask_elapsed;

    double function (cairo_device_t* device)
            cairo_device_observer_fill_elapsed;

    double function (cairo_device_t* device)
            cairo_device_observer_stroke_elapsed;

    double function (cairo_device_t* device)
            cairo_device_observer_glyphs_elapsed;

    cairo_surface_t* function (cairo_surface_t* surface)
            cairo_surface_reference;

    void function (cairo_surface_t* surface)
            cairo_surface_finish;

    void function (cairo_surface_t* surface)
            cairo_surface_destroy;

    cairo_device_t* function (cairo_surface_t* surface)
            cairo_surface_get_device;

    uint function (cairo_surface_t* surface)
            cairo_surface_get_reference_count;

    cairo_status_t function (cairo_surface_t* surface)
            cairo_surface_status;


    cairo_surface_type_t function (cairo_surface_t* surface)
            cairo_surface_get_type;

    cairo_content_t function (cairo_surface_t* surface)
            cairo_surface_get_content;


    void* function (cairo_surface_t* surface,
                     const(cairo_user_data_key_t)* key)
            cairo_surface_get_user_data;

    cairo_status_t function (cairo_surface_t* surface,
                     const(cairo_user_data_key_t)* key,
                     void* user_data,
                     cairo_destroy_func_t	 destroy)
            cairo_surface_set_user_data;


    void function (cairo_surface_t* surface,
                                 const(char)* mime_type,
                                 const(ubyte)* *data,
                                 c_ulong* length)
            cairo_surface_get_mime_data;

    cairo_status_t function (cairo_surface_t* surface,
                                 const(char)* mime_type,
                                 const(ubyte)* data,
                                 c_ulong		 length,
                     cairo_destroy_func_t	 destroy,
                     void* closure)
            cairo_surface_set_mime_data;

    cairo_bool_t function (cairo_surface_t* surface,
                      const(char)* mime_type)
            cairo_surface_supports_mime_type;

    void function (cairo_surface_t* surface,
                    cairo_font_options_t* options)
            cairo_surface_get_font_options;

    void function (cairo_surface_t* surface)
            cairo_surface_flush;

    void function (cairo_surface_t* surface)
            cairo_surface_mark_dirty;

    void function (cairo_surface_t* surface,
                        int              x,
                        int              y,
                        int              width,
                        int              height)
            cairo_surface_mark_dirty_rectangle;

    void function (cairo_surface_t* surface,
                    double           x_scale,
                    double           y_scale)
            cairo_surface_set_device_scale;

    void function (cairo_surface_t* surface,
                    double* x_scale,
                    double* y_scale)
            cairo_surface_get_device_scale;

    void function (cairo_surface_t* surface,
                     double           x_offset,
                     double           y_offset)
            cairo_surface_set_device_offset;

    void function (cairo_surface_t* surface,
                     double* x_offset,
                     double* y_offset)
            cairo_surface_get_device_offset;

    void function (cairo_surface_t* surface,
                           double		 x_pixels_per_inch,
                           double		 y_pixels_per_inch)
            cairo_surface_set_fallback_resolution;

    void function (cairo_surface_t* surface,
                           double* x_pixels_per_inch,
                           double* y_pixels_per_inch)
            cairo_surface_get_fallback_resolution;

    void function (cairo_surface_t* surface)
            cairo_surface_copy_page;

    void function (cairo_surface_t* surface)
            cairo_surface_show_page;

    cairo_bool_t function (cairo_surface_t* surface)
            cairo_surface_has_show_text_glyphs;

    cairo_surface_t* function (cairo_format_t	format,
                    int			width,
                    int			height)
            cairo_image_surface_create;

    int function (cairo_format_t	format,
                       int		width)
            cairo_format_stride_for_width;

    cairo_surface_t* function (ubyte* data,
                         cairo_format_t		format,
                         int			width,
                         int			height,
                         int			stride)
            cairo_image_surface_create_for_data;

    ubyte* function (cairo_surface_t* surface)
            cairo_image_surface_get_data;

    cairo_format_t function (cairo_surface_t* surface)
            cairo_image_surface_get_format;

    int function (cairo_surface_t* surface)
            cairo_image_surface_get_width;

    int function (cairo_surface_t* surface)
            cairo_image_surface_get_height;

    int function (cairo_surface_t* surface)
            cairo_image_surface_get_stride;


    cairo_surface_t* function (cairo_content_t		 content,
                                    const(cairo_rectangle_t)* extents)
                    cairo_recording_surface_create;

    void function (cairo_surface_t* surface,
                                         double* x0,
                                         double* y0,
                                         double* width,
                                         double* height)
            cairo_recording_surface_ink_extents;

    cairo_bool_t function (cairo_surface_t* surface,
                         cairo_rectangle_t* extents)
                cairo_recording_surface_get_extents;


    cairo_pattern_t* function (void* user_data,
                        cairo_content_t content,
                        int width, int height)
                cairo_pattern_create_raster_source;

    void function (cairo_pattern_t* pattern,
                               void* data)
                cairo_raster_source_pattern_set_callback_data;

    void* function (cairo_pattern_t* pattern)
                cairo_raster_source_pattern_get_callback_data;

    void function (cairo_pattern_t* pattern,
                         cairo_raster_source_acquire_func_t acquire,
                         cairo_raster_source_release_func_t release)
                cairo_raster_source_pattern_set_acquire;

    void function (cairo_pattern_t* pattern,
                         cairo_raster_source_acquire_func_t* acquire,
                         cairo_raster_source_release_func_t* release)
                cairo_raster_source_pattern_get_acquire;
    void function (cairo_pattern_t* pattern,
                          cairo_raster_source_snapshot_func_t snapshot)
                cairo_raster_source_pattern_set_snapshot;

    cairo_raster_source_snapshot_func_t function (cairo_pattern_t* pattern)
                cairo_raster_source_pattern_get_snapshot;

    void function (cairo_pattern_t* pattern,
                          cairo_raster_source_copy_func_t copy)
                cairo_raster_source_pattern_set_copy;

    cairo_raster_source_copy_func_t function (cairo_pattern_t* pattern)
                cairo_raster_source_pattern_get_copy;

    void function (cairo_pattern_t* pattern,
                        cairo_raster_source_finish_func_t finish)
                cairo_raster_source_pattern_set_finish;

    cairo_raster_source_finish_func_t function (cairo_pattern_t* pattern)
                cairo_raster_source_pattern_get_finish;


    cairo_pattern_t* function (double red, double green, double blue)
                cairo_pattern_create_rgb;

    cairo_pattern_t* function (double red, double green, double blue,
                   double alpha)
                cairo_pattern_create_rgba;

    cairo_pattern_t* function (cairo_surface_t* surface)
                cairo_pattern_create_for_surface;

    cairo_pattern_t* function (double x0, double y0,
                     double x1, double y1)
                cairo_pattern_create_linear;

    cairo_pattern_t* function (double cx0, double cy0, double radius0,
                     double cx1, double cy1, double radius1)
                cairo_pattern_create_radial;

    cairo_pattern_t* function ()
                cairo_pattern_create_mesh;

    cairo_pattern_t* function (cairo_pattern_t* pattern)
                cairo_pattern_reference;

    void function (cairo_pattern_t* pattern)
                cairo_pattern_destroy;

    uint function (cairo_pattern_t* pattern)
                cairo_pattern_get_reference_count;

    cairo_status_t function (cairo_pattern_t* pattern)
                cairo_pattern_status;

    void* function (cairo_pattern_t* pattern,
                     const(cairo_user_data_key_t)* key)
                cairo_pattern_get_user_data;

    cairo_status_t function (cairo_pattern_t* pattern,
                     const(cairo_user_data_key_t)* key,
                     void* user_data,
                     cairo_destroy_func_t	  destroy)
                cairo_pattern_set_user_data;

    cairo_pattern_type_t function (cairo_pattern_t* pattern)
                cairo_pattern_get_type;

    void function (cairo_pattern_t* pattern,
                      double offset,
                      double red, double green, double blue)
                cairo_pattern_add_color_stop_rgb;

    void function (cairo_pattern_t* pattern,
                       double offset,
                       double red, double green, double blue,
                       double alpha)
                cairo_pattern_add_color_stop_rgba;

    void function (cairo_pattern_t* pattern)
                cairo_mesh_pattern_begin_patch;

    void function (cairo_pattern_t* pattern)
                cairo_mesh_pattern_end_patch;

    void function (cairo_pattern_t* pattern,
                     double x1, double y1,
                     double x2, double y2,
                     double x3, double y3)
                cairo_mesh_pattern_curve_to;

    void function (cairo_pattern_t* pattern,
                    double x, double y)
                cairo_mesh_pattern_line_to;

    void function (cairo_pattern_t* pattern,
                    double x, double y)
                cairo_mesh_pattern_move_to;

    void function (cairo_pattern_t* pattern,
                          uint point_num,
                          double x, double y)
                cairo_mesh_pattern_set_control_point;

    void function (cairo_pattern_t* pattern,
                         uint corner_num,
                         double red, double green, double blue)
                cairo_mesh_pattern_set_corner_color_rgb;

    void function (cairo_pattern_t* pattern,
                          uint corner_num,
                          double red, double green, double blue,
                          double alpha)
                cairo_mesh_pattern_set_corner_color_rgba;

    void function (cairo_pattern_t* pattern,
                  const(cairo_matrix_t)* matrix)
                cairo_pattern_set_matrix;

    void function (cairo_pattern_t* pattern,
                  cairo_matrix_t* matrix)
                cairo_pattern_get_matrix;


    void function (cairo_pattern_t* pattern, cairo_extend_t extend)
                cairo_pattern_set_extend;

    cairo_extend_t function (cairo_pattern_t* pattern)
                cairo_pattern_get_extend;


    void function (cairo_pattern_t* pattern, cairo_filter_t filter)
                cairo_pattern_set_filter;

    cairo_filter_t function (cairo_pattern_t* pattern)
                cairo_pattern_get_filter;

    cairo_status_t function (cairo_pattern_t* pattern,
                double* red, double* green,
                double* blue, double* alpha)
                cairo_pattern_get_rgba;

    cairo_status_t function (cairo_pattern_t* pattern,
                   cairo_surface_t* *surface)
                cairo_pattern_get_surface;


    cairo_status_t function (cairo_pattern_t* pattern,
                       int index, double* offset,
                       double* red, double* green,
                       double* blue, double* alpha)
                cairo_pattern_get_color_stop_rgba;

    cairo_status_t function (cairo_pattern_t* pattern,
                        int* count)
                cairo_pattern_get_color_stop_count;

    cairo_status_t function (cairo_pattern_t* pattern,
                     double* x0, double* y0,
                     double* x1, double* y1)
                cairo_pattern_get_linear_points;

    cairo_status_t function (cairo_pattern_t* pattern,
                      double* x0, double* y0, double* r0,
                      double* x1, double* y1, double* r1)
                cairo_pattern_get_radial_circles;

    cairo_status_t function (cairo_pattern_t* pattern,
                        uint* count)
                cairo_mesh_pattern_get_patch_count;

    cairo_path_t* function (cairo_pattern_t* pattern,
                     uint patch_num)
                cairo_mesh_pattern_get_path;

    cairo_status_t function (cairo_pattern_t* pattern,
                          uint patch_num,
                          uint corner_num,
                          double* red, double* green,
                          double* blue, double* alpha)
                cairo_mesh_pattern_get_corner_color_rgba;

    cairo_status_t function (cairo_pattern_t* pattern,
                          uint patch_num,
                          uint point_num,
                          double* x, double* y)
                cairo_mesh_pattern_get_control_point;

    void function (cairo_matrix_t* matrix,
               double  xx, double  yx,
               double  xy, double  yy,
               double  x0, double  y0)
                cairo_matrix_init;

    void function (cairo_matrix_t* matrix)
                cairo_matrix_init_identity;

    void function (cairo_matrix_t* matrix,
                     double tx, double ty)
                cairo_matrix_init_translate;

    void function (cairo_matrix_t* matrix,
                 double sx, double sy)
                cairo_matrix_init_scale;

    void function (cairo_matrix_t* matrix,
                  double radians)
                cairo_matrix_init_rotate;

    void function (cairo_matrix_t* matrix, double tx, double ty)
                cairo_matrix_translate;

    void function (cairo_matrix_t* matrix, double sx, double sy)
                cairo_matrix_scale;

    void function (cairo_matrix_t* matrix, double radians)
                cairo_matrix_rotate;

    cairo_status_t function (cairo_matrix_t* matrix)
                cairo_matrix_invert;

    void function (cairo_matrix_t* result,
                   const(cairo_matrix_t)* a,
                   const(cairo_matrix_t)* b)
                cairo_matrix_multiply;

    void function (const(cairo_matrix_t)* matrix,
                     double* dx, double* dy)
                cairo_matrix_transform_distance;

    void function (const(cairo_matrix_t)* matrix,
                      double* x, double* y)
                cairo_matrix_transform_point;


    cairo_region_t* function ()
                cairo_region_create;

    cairo_region_t* function (const(cairo_rectangle_int_t)* rectangle)
                cairo_region_create_rectangle;

    cairo_region_t* function (const(cairo_rectangle_int_t)* rects,
                    int count)
                cairo_region_create_rectangles;

    cairo_region_t* function (const(cairo_region_t)* original)
                cairo_region_copy;

    cairo_region_t* function (cairo_region_t* region)
                cairo_region_reference;

    void function (cairo_region_t* region)
                cairo_region_destroy;

    cairo_bool_t function (const(cairo_region_t)* a, const(cairo_region_t)* b)
                cairo_region_equal;

    cairo_status_t function (const(cairo_region_t)* region)
                cairo_region_status;

    void function (const cairo_region_t* region,
                  cairo_rectangle_int_t* extents)
                cairo_region_get_extents;

    int function (const(cairo_region_t)* region)
                cairo_region_num_rectangles;

    void function (const cairo_region_t* region,
                    int                    nth,
                    cairo_rectangle_int_t* rectangle)
                cairo_region_get_rectangle;

    cairo_bool_t function (const(cairo_region_t)* region)
                cairo_region_is_empty;

    cairo_region_overlap_t function (const(cairo_region_t)* region,
                     const(cairo_rectangle_int_t)* rectangle)
                cairo_region_contains_rectangle;

    cairo_bool_t function (const(cairo_region_t)* region, int x, int y)
                cairo_region_contains_point;

    void function (cairo_region_t* region, int dx, int dy)
                cairo_region_translate;

    cairo_status_t function (cairo_region_t* dst, const(cairo_region_t)* other)
                cairo_region_subtract;

    cairo_status_t function (cairo_region_t* dst,
                     const(cairo_rectangle_int_t)* rectangle)
                cairo_region_subtract_rectangle;

    cairo_status_t function (cairo_region_t* dst, const(cairo_region_t)* other)
                cairo_region_intersect;

    cairo_status_t function (cairo_region_t* dst,
                      const(cairo_rectangle_int_t)* rectangle)
                cairo_region_intersect_rectangle;

    cairo_status_t function (cairo_region_t* dst, const(cairo_region_t)* other)
                cairo_region_union;

    cairo_status_t function (cairo_region_t* dst,
                      const(cairo_rectangle_int_t)* rectangle)
                cairo_region_union_rectangle;

    cairo_status_t function (cairo_region_t* dst, const(cairo_region_t)* other)
                cairo_region_xor;

    cairo_status_t function (cairo_region_t* dst,
                    const(cairo_rectangle_int_t)* rectangle)
                cairo_region_xor_rectangle;

    void function ()
                cairo_debug_reset_static_data;
}

