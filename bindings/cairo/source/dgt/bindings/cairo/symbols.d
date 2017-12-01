module dgt.bindings.cairo.symbols;

import dgt.bindings.cairo.enums;
import dgt.bindings.cairo.types;

import core.stdc.config : c_ulong;


extern(C) nothrow @nogc
{
    alias da_cairo_version = int function ();

    alias da_cairo_version_string = const(char)* function ();

    alias da_cairo_create = cairo_t* function (cairo_surface_t* target);

    alias da_cairo_reference = cairo_t* function (cairo_t* cr);

    alias da_cairo_destroy = void function (cairo_t* cr);

    alias da_cairo_get_reference_count = uint function (cairo_t* cr);

    alias da_cairo_get_user_data = void* function (cairo_t* cr,
                 const(cairo_user_data_key_t)* key);

    alias da_cairo_set_user_data = cairo_status_t function (cairo_t* cr,
                 const(cairo_user_data_key_t)* key,
                 void* user_data,
                 cairo_destroy_func_t	  destroy);

    alias da_cairo_save = void function (cairo_t* cr);

    alias da_cairo_restore = void function (cairo_t* cr);

    alias da_cairo_push_group = void function (cairo_t* cr);

    alias da_cairo_push_group_with_content = void function (cairo_t* cr, cairo_content_t content);

    alias da_cairo_pop_group = cairo_pattern_t* function (cairo_t* cr);

    alias da_cairo_pop_group_to_source = void function (cairo_t* cr);


    alias da_cairo_set_operator = void function (cairo_t* cr, cairo_operator_t op);

    alias da_cairo_set_source = void function (cairo_t* cr, cairo_pattern_t* source);

    alias da_cairo_set_source_rgb = void function (cairo_t* cr, double red, double green, double blue);

    alias da_cairo_set_source_rgba = void function (cairo_t* cr,
                   double red, double green, double blue,
                   double alpha);

    alias da_cairo_set_source_surface = void function (cairo_t* cr,
                  cairo_surface_t* surface,
                  double	   x,
                  double	   y);

    alias da_cairo_set_tolerance = void function (cairo_t* cr, double tolerance);


    alias da_cairo_set_antialias = void function (cairo_t *cr, cairo_antialias_t antialias);

    alias da_cairo_set_fill_rule = void function (cairo_t* cr, cairo_fill_rule_t fill_rule);

    alias da_cairo_set_line_width = void function (cairo_t* cr, double width);

    alias da_cairo_set_line_cap = void function (cairo_t* cr, cairo_line_cap_t line_cap);

    alias da_cairo_set_line_join = void function (cairo_t* cr, cairo_line_join_t line_join);

    alias da_cairo_set_dash = void function (cairo_t* cr,
            const(double)* dashes,
            int	      num_dashes,
            double	      offset);

    alias da_cairo_set_miter_limit = void function (cairo_t* cr, double limit);

    alias da_cairo_translate = void function (cairo_t* cr, double tx, double ty);

    alias da_cairo_scale = void function (cairo_t* cr, double sx, double sy);

    alias da_cairo_rotate = void function (cairo_t* cr, double angle);

    alias da_cairo_transform = void function (cairo_t* cr,
             const(cairo_matrix_t)* matrix);

    alias da_cairo_set_matrix = void function (cairo_t* cr,
              const(cairo_matrix_t)* matrix);

    alias da_cairo_identity_matrix = void function (cairo_t* cr);

    alias da_cairo_user_to_device = void function (cairo_t* cr, double* x, double* y);

    alias da_cairo_user_to_device_distance = void function (cairo_t* cr, double* dx, double* dy);

    alias da_cairo_device_to_user = void function (cairo_t* cr, double* x, double* y);

    alias da_cairo_device_to_user_distance = void function (cairo_t* cr, double* dx, double* dy);

    alias da_cairo_new_path = void function (cairo_t* cr);

    alias da_cairo_move_to = void function (cairo_t* cr, double x, double y);

    alias da_cairo_new_sub_path = void function (cairo_t* cr);

    alias da_cairo_line_to = void function (cairo_t* cr, double x, double y);

    alias da_cairo_curve_to = void function (cairo_t* cr,
            double x1, double y1,
            double x2, double y2,
            double x3, double y3);

    alias da_cairo_arc = void function (cairo_t* cr,
           double xc, double yc,
           double radius,
           double angle1, double angle2);

    alias da_cairo_arc_negative = void function (cairo_t* cr,
                double xc, double yc,
                double radius,
                double angle1, double angle2);


    alias da_cairo_rel_move_to = void function (cairo_t* cr, double dx, double dy);

    alias da_cairo_rel_line_to = void function (cairo_t* cr, double dx, double dy);

    alias da_cairo_rel_curve_to = void function (cairo_t* cr,
                double dx1, double dy1,
                double dx2, double dy2,
                double dx3, double dy3);

    alias da_cairo_rectangle = void function (cairo_t* cr,
             double x, double y,
             double width, double height);


    alias da_cairo_close_path = void function (cairo_t* cr);

    alias da_cairo_path_extents = void function (cairo_t* cr,
                double* x1, double* y1,
                double* x2, double* y2);

    alias da_cairo_paint = void function (cairo_t* cr);

    alias da_cairo_paint_with_alpha = void function (cairo_t* cr,
                double   alpha);

    alias da_cairo_mask = void function (cairo_t* cr,
            cairo_pattern_t* pattern);

    alias da_cairo_mask_surface = void function (cairo_t* cr,
                cairo_surface_t* surface,
                double           surface_x,
                double           surface_y);

    alias da_cairo_stroke = void function (cairo_t* cr);

    alias da_cairo_stroke_preserve = void function (cairo_t* cr);

    alias da_cairo_fill = void function (cairo_t* cr);

    alias da_cairo_fill_preserve = void function (cairo_t* cr);

    alias da_cairo_copy_page = void function (cairo_t* cr);

    alias da_cairo_show_page = void function (cairo_t* cr);

    alias da_cairo_in_stroke = cairo_bool_t function (cairo_t* cr, double x, double y);

    alias da_cairo_in_fill = cairo_bool_t function (cairo_t* cr, double x, double y);

    alias da_cairo_in_clip = cairo_bool_t function (cairo_t* cr, double x, double y);

    alias da_cairo_stroke_extents = void function (cairo_t* cr,
                  double* x1, double* y1,
                  double* x2, double* y2);

    alias da_cairo_fill_extents = void function (cairo_t* cr,
                double* x1, double* y1,
                double* x2, double* y2);

    alias da_cairo_reset_clip = void function (cairo_t* cr);

    alias da_cairo_clip = void function (cairo_t* cr);

    alias da_cairo_clip_preserve = void function (cairo_t* cr);

    alias da_cairo_clip_extents = void function (cairo_t* cr,
                double* x1, double* y1,
                double* x2, double* y2);


    alias da_cairo_copy_clip_rectangle_list = cairo_rectangle_list_t* function (cairo_t* cr);

    alias da_cairo_rectangle_list_destroy = void function (cairo_rectangle_list_t* rectangle_list);


    alias da_cairo_glyph_allocate = cairo_glyph_t* function (int num_glyphs);

    alias da_cairo_glyph_free = void function (cairo_glyph_t* glyphs);

    alias da_cairo_text_cluster_allocate = cairo_text_cluster_t* function (int num_clusters);

    alias da_cairo_text_cluster_free = void function (cairo_text_cluster_t* clusters);


    alias da_cairo_font_options_create = cairo_font_options_t* function ();

    alias da_cairo_font_options_copy = cairo_font_options_t* function (const(cairo_font_options_t)* original);

    alias da_cairo_font_options_destroy = void function (cairo_font_options_t* options);

    alias da_cairo_font_options_status = cairo_status_t function (cairo_font_options_t* options);

    alias da_cairo_font_options_merge = void function (cairo_font_options_t* options,
                  const(cairo_font_options_t)* other);
    alias da_cairo_font_options_equal = cairo_bool_t function (const(cairo_font_options_t)* options,
                  const(cairo_font_options_t)* other);

    alias da_cairo_font_options_hash = c_ulong function (const(cairo_font_options_t)* options);

    alias da_cairo_font_options_set_antialias = void function (cairo_font_options_t* options,
                      cairo_antialias_t     antialias);
    alias da_cairo_font_options_get_antialias = cairo_antialias_t function (const(cairo_font_options_t)* options);

    alias da_cairo_font_options_set_subpixel_order = void function (cairo_font_options_t* options,
                           cairo_subpixel_order_t  subpixel_order);
    alias da_cairo_font_options_get_subpixel_order = cairo_subpixel_order_t function (const(cairo_font_options_t)* options);

    alias da_cairo_font_options_set_hint_style = void function (cairo_font_options_t* options,
                       cairo_hint_style_t     hint_style);
    alias da_cairo_font_options_get_hint_style = cairo_hint_style_t function (const(cairo_font_options_t)* options);

    alias da_cairo_font_options_set_hint_metrics = void function (cairo_font_options_t* options,
                         cairo_hint_metrics_t  hint_metrics);
    alias da_cairo_font_options_get_hint_metrics = cairo_hint_metrics_t function (const(cairo_font_options_t)* options);

    alias da_cairo_select_font_face = void function (cairo_t* cr,
                const(char)* family,
                cairo_font_slant_t   slant,
                cairo_font_weight_t  weight);

    alias da_cairo_set_font_size = void function (cairo_t* cr, double size);

    alias da_cairo_set_font_matrix = void function (cairo_t* cr,
                   const(cairo_matrix_t)* matrix);

    alias da_cairo_get_font_matrix = void function (cairo_t* cr,
                   cairo_matrix_t* matrix);

    alias da_cairo_set_font_options = void function (cairo_t* cr,
                const(cairo_font_options_t)* options);

    alias da_cairo_get_font_options = void function (cairo_t* cr,
                cairo_font_options_t* options);

    alias da_cairo_set_font_face = void function (cairo_t* cr, cairo_font_face_t* font_face);

    alias da_cairo_get_font_face = cairo_font_face_t* function (cairo_t* cr);

    alias da_cairo_set_scaled_font = void function (cairo_t* cr,
                   const(cairo_scaled_font_t)* scaled_font);

    alias da_cairo_get_scaled_font = cairo_scaled_font_t* function (cairo_t* cr);

    alias da_cairo_show_text = void function (cairo_t* cr, const(char)* utf8);

    alias da_cairo_show_glyphs = void function (cairo_t* cr, const(cairo_glyph_t)* glyphs, int num_glyphs);

    alias da_cairo_show_text_glyphs = void function (cairo_t* cr,
                const(char)* utf8,
                int			    utf8_len,
                const cairo_glyph_t* glyphs,
                int			    num_glyphs,
                const(cairo_text_cluster_t)* clusters,
                int			    num_clusters,
                cairo_text_cluster_flags_t  cluster_flags);

    alias da_cairo_text_path = void function (cairo_t* cr, const(char)* utf8);

    alias da_cairo_glyph_path = void function (cairo_t* cr, const(cairo_glyph_t)* glyphs, int num_glyphs);

    alias da_cairo_text_extents = void function (cairo_t* cr,
                const(char)* utf8,
                cairo_text_extents_t* extents);

    alias da_cairo_glyph_extents = void function (cairo_t* cr,
                 const cairo_glyph_t* glyphs,
                 int                   num_glyphs,
                 cairo_text_extents_t* extents);

    alias da_cairo_font_extents = void function (cairo_t* cr,
                cairo_font_extents_t* extents);


    alias da_cairo_font_face_reference = cairo_font_face_t* function (cairo_font_face_t* font_face);

    alias da_cairo_font_face_destroy = void function (cairo_font_face_t* font_face);

    alias da_cairo_font_face_get_reference_count = uint function (cairo_font_face_t* font_face);

    alias da_cairo_font_face_status = cairo_status_t function (cairo_font_face_t* font_face);



    alias da_cairo_font_face_get_type = cairo_font_type_t function (cairo_font_face_t* font_face);

    alias da_cairo_font_face_get_user_data = void* function (cairo_font_face_t* font_face,
                       const(cairo_user_data_key_t)* key);

    alias da_cairo_font_face_set_user_data = cairo_status_t function (cairo_font_face_t* font_face,
                       const(cairo_user_data_key_t)* key,
                       void* user_data,
                       cairo_destroy_func_t	    destroy);


    alias da_cairo_scaled_font_create = cairo_scaled_font_t* function (cairo_font_face_t* font_face,
                  const cairo_matrix_t* font_matrix,
                  const cairo_matrix_t* ctm,
                  const(cairo_font_options_t)* options);

    alias da_cairo_scaled_font_reference = cairo_scaled_font_t* function (cairo_scaled_font_t* scaled_font);

    alias da_cairo_scaled_font_destroy = void function (cairo_scaled_font_t* scaled_font);

    alias da_cairo_scaled_font_get_reference_count = uint function (cairo_scaled_font_t* scaled_font);

    alias da_cairo_scaled_font_status = cairo_status_t function (cairo_scaled_font_t* scaled_font);

    alias da_cairo_scaled_font_get_type = cairo_font_type_t function (cairo_scaled_font_t* scaled_font);

    alias da_cairo_scaled_font_get_user_data = void* function (cairo_scaled_font_t* scaled_font,
                     const(cairo_user_data_key_t)* key);

    alias da_cairo_scaled_font_set_user_data = cairo_status_t function (cairo_scaled_font_t* scaled_font,
                     const(cairo_user_data_key_t)* key,
                     void* user_data,
                     cairo_destroy_func_t	      destroy);

    alias da_cairo_scaled_font_extents = void function (cairo_scaled_font_t* scaled_font,
                   cairo_font_extents_t* extents);

    alias da_cairo_scaled_font_text_extents = void function (cairo_scaled_font_t* scaled_font,
                    const(char)* utf8,
                    cairo_text_extents_t* extents);

    alias da_cairo_scaled_font_glyph_extents = void function (cairo_scaled_font_t* scaled_font,
                     const cairo_glyph_t* glyphs,
                     int                   num_glyphs,
                     cairo_text_extents_t* extents);

    alias da_cairo_scaled_font_text_to_glyphs = cairo_status_t function (cairo_scaled_font_t* scaled_font,
                      double		      x,
                      double		      y,
                      const(char)* utf8,
                      int		              utf8_len,
                      cairo_glyph_t* *glyphs,
                      int* num_glyphs,
                      cairo_text_cluster_t* *clusters,
                      int* num_clusters,
                      cairo_text_cluster_flags_t* cluster_flags);

    alias da_cairo_scaled_font_get_font_face = cairo_font_face_t* function (cairo_scaled_font_t* scaled_font);

    alias da_cairo_scaled_font_get_font_matrix = void function (cairo_scaled_font_t* scaled_font,
                       cairo_matrix_t* font_matrix);

    alias da_cairo_scaled_font_get_ctm = void function (cairo_scaled_font_t* scaled_font,
                   cairo_matrix_t* ctm);

    alias da_cairo_scaled_font_get_scale_matrix = void function (cairo_scaled_font_t* scaled_font,
                        cairo_matrix_t* scale_matrix);

    alias da_cairo_scaled_font_get_font_options = void function (cairo_scaled_font_t* scaled_font,
                        cairo_font_options_t* options);


    alias da_cairo_toy_font_face_create = cairo_font_face_t* function (const(char)* family,
                    cairo_font_slant_t    slant,
                    cairo_font_weight_t   weight);

    alias da_cairo_toy_font_face_get_family = const(char)* function (cairo_font_face_t* font_face);

    alias da_cairo_toy_font_face_get_slant = cairo_font_slant_t function (cairo_font_face_t* font_face);

    alias da_cairo_toy_font_face_get_weight = cairo_font_weight_t function (cairo_font_face_t* font_face);



    alias da_cairo_user_font_face_create = cairo_font_face_t* function ();

    alias da_cairo_user_font_face_set_init_func = void function (cairo_font_face_t* font_face,
                        cairo_user_scaled_font_init_func_t  init_func);

    alias da_cairo_user_font_face_set_render_glyph_func = void function (cairo_font_face_t* font_face,
                            cairo_user_scaled_font_render_glyph_func_t  render_glyph_func);

    alias da_cairo_user_font_face_set_text_to_glyphs_func = void function (cairo_font_face_t* font_face,
                              cairo_user_scaled_font_text_to_glyphs_func_t  text_to_glyphs_func);

    alias da_cairo_user_font_face_set_unicode_to_glyph_func = void function (cairo_font_face_t* font_face,
                                cairo_user_scaled_font_unicode_to_glyph_func_t  unicode_to_glyph_func);


    alias da_cairo_user_font_face_get_init_func = cairo_user_scaled_font_init_func_t function (cairo_font_face_t* font_face);

    alias da_cairo_user_font_face_get_render_glyph_func = cairo_user_scaled_font_render_glyph_func_t function (cairo_font_face_t* font_face);

    alias da_cairo_user_font_face_get_text_to_glyphs_func = cairo_user_scaled_font_text_to_glyphs_func_t function (cairo_font_face_t* font_face);

    alias da_cairo_user_font_face_get_unicode_to_glyph_func = cairo_user_scaled_font_unicode_to_glyph_func_t function (cairo_font_face_t* font_face);


    alias da_cairo_get_operator = cairo_operator_t function (cairo_t* cr);

    alias da_cairo_get_source = cairo_pattern_t* function (cairo_t* cr);

    alias da_cairo_get_tolerance = double function (cairo_t* cr);

    alias da_cairo_get_antialias = cairo_antialias_t function (cairo_t* cr);

    alias da_cairo_has_current_point = cairo_bool_t function (cairo_t* cr);

    alias da_cairo_get_current_point = void function (cairo_t* cr, double* x, double* y);

    alias da_cairo_get_fill_rule = cairo_fill_rule_t function (cairo_t* cr);

    alias da_cairo_get_line_width = double function (cairo_t* cr);

    alias da_cairo_get_line_cap = cairo_line_cap_t function (cairo_t* cr);

    alias da_cairo_get_line_join = cairo_line_join_t function (cairo_t* cr);

    alias da_cairo_get_miter_limit = double function (cairo_t* cr);

    alias da_cairo_get_dash_count = int function (cairo_t* cr);

    alias da_cairo_get_dash = void function (cairo_t* cr, double* dashes, double* offset);

    alias da_cairo_get_matrix = void function (cairo_t* cr, cairo_matrix_t* matrix);

    alias da_cairo_get_target = cairo_surface_t* function (cairo_t* cr);

    alias da_cairo_get_group_target = cairo_surface_t* function (cairo_t* cr);

    alias da_cairo_copy_path = cairo_path_t* function (cairo_t* cr);

    alias da_cairo_copy_path_flat = cairo_path_t* function (cairo_t* cr);

    alias da_cairo_append_path = void function (cairo_t* cr,
               const(cairo_path_t)* path);

    alias da_cairo_path_destroy = void function (cairo_path_t* path);


    alias da_cairo_status = cairo_status_t function (cairo_t* cr);

    alias da_cairo_status_to_string = const(char)* function (cairo_status_t status);


    alias da_cairo_device_reference = cairo_device_t* function (cairo_device_t* device);


    alias da_cairo_device_get_type = cairo_device_type_t function (cairo_device_t* device);

    alias da_cairo_device_status = cairo_status_t function (cairo_device_t* device);

    alias da_cairo_device_acquire = cairo_status_t function (cairo_device_t* device);

    alias da_cairo_device_release = void function (cairo_device_t* device);

    alias da_cairo_device_flush = void function (cairo_device_t* device);

    alias da_cairo_device_finish = void function (cairo_device_t* device);

    alias da_cairo_device_destroy = void function (cairo_device_t* device);

    alias da_cairo_device_get_reference_count = uint function (cairo_device_t* device);

    alias da_cairo_device_get_user_data = void* function (cairo_device_t* device,
                    const(cairo_user_data_key_t)* key);

    alias da_cairo_device_set_user_data = cairo_status_t function (cairo_device_t* device,
                    const(cairo_user_data_key_t)* key,
                    void* user_data,
                    cairo_destroy_func_t	  destroy);


    alias da_cairo_surface_create_similar = cairo_surface_t* function (cairo_surface_t* other,
                      cairo_content_t	content,
                      int		width,
                      int		height);

    alias da_cairo_surface_create_similar_image = cairo_surface_t* function (cairo_surface_t* other,
                        cairo_format_t    format,
                        int		width,
                        int		height);

    alias da_cairo_surface_map_to_image = cairo_surface_t* function (cairo_surface_t* surface,
                    const(cairo_rectangle_int_t)* extents);

    alias da_cairo_surface_unmap_image = void function (cairo_surface_t* surface,
                   cairo_surface_t* image);

    alias da_cairo_surface_create_for_rectangle = cairo_surface_t* function (cairo_surface_t* target,
                                        double		 x,
                                        double		 y,
                                        double		 width,
                                        double		 height);


    alias da_cairo_surface_create_observer = cairo_surface_t* function (cairo_surface_t* target,
                       cairo_surface_observer_mode_t mode);

    alias da_cairo_surface_observer_add_paint_callback = cairo_status_t function (cairo_surface_t* abstract_surface,
                           cairo_surface_observer_callback_t func,
                           void* data);

    alias da_cairo_surface_observer_add_mask_callback = cairo_status_t function (cairo_surface_t* abstract_surface,
                          cairo_surface_observer_callback_t func,
                          void* data);

    alias da_cairo_surface_observer_add_fill_callback = cairo_status_t function (cairo_surface_t* abstract_surface,
                          cairo_surface_observer_callback_t func,
                          void* data);

    alias da_cairo_surface_observer_add_stroke_callback = cairo_status_t function (cairo_surface_t* abstract_surface,
                            cairo_surface_observer_callback_t func,
                            void* data);

    alias da_cairo_surface_observer_add_glyphs_callback = cairo_status_t function (cairo_surface_t* abstract_surface,
                            cairo_surface_observer_callback_t func,
                            void* data);

    alias da_cairo_surface_observer_add_flush_callback = cairo_status_t function (cairo_surface_t* abstract_surface,
                           cairo_surface_observer_callback_t func,
                           void* data);

    alias da_cairo_surface_observer_add_finish_callback = cairo_status_t function (cairo_surface_t* abstract_surface,
                            cairo_surface_observer_callback_t func,
                            void* data);

    alias da_cairo_surface_observer_print = cairo_status_t function (cairo_surface_t* surface,
                      cairo_write_func_t write_func,
                      void* closure);
    alias da_cairo_surface_observer_elapsed = double function (cairo_surface_t* surface);

    alias da_cairo_device_observer_print = cairo_status_t function (cairo_device_t* device,
                     cairo_write_func_t write_func,
                     void* closure);

    alias da_cairo_device_observer_elapsed = double function (cairo_device_t* device);

    alias da_cairo_device_observer_paint_elapsed = double function (cairo_device_t* device);

    alias da_cairo_device_observer_mask_elapsed = double function (cairo_device_t* device);

    alias da_cairo_device_observer_fill_elapsed = double function (cairo_device_t* device);

    alias da_cairo_device_observer_stroke_elapsed = double function (cairo_device_t* device);

    alias da_cairo_device_observer_glyphs_elapsed = double function (cairo_device_t* device);

    alias da_cairo_surface_reference = cairo_surface_t* function (cairo_surface_t* surface);

    alias da_cairo_surface_finish = void function (cairo_surface_t* surface);

    alias da_cairo_surface_destroy = void function (cairo_surface_t* surface);

    alias da_cairo_surface_get_device = cairo_device_t* function (cairo_surface_t* surface);

    alias da_cairo_surface_get_reference_count = uint function (cairo_surface_t* surface);

    alias da_cairo_surface_status = cairo_status_t function (cairo_surface_t* surface);


    alias da_cairo_surface_get_type = cairo_surface_type_t function (cairo_surface_t* surface);

    alias da_cairo_surface_get_content = cairo_content_t function (cairo_surface_t* surface);


    alias da_cairo_surface_get_user_data = void* function (cairo_surface_t* surface,
                     const(cairo_user_data_key_t)* key);

    alias da_cairo_surface_set_user_data = cairo_status_t function (cairo_surface_t* surface,
                     const(cairo_user_data_key_t)* key,
                     void* user_data,
                     cairo_destroy_func_t	 destroy);


    alias da_cairo_surface_get_mime_data = void function (cairo_surface_t* surface,
                                 const(char)* mime_type,
                                 const(ubyte)* *data,
                                 c_ulong* length);

    alias da_cairo_surface_set_mime_data = cairo_status_t function (cairo_surface_t* surface,
                                 const(char)* mime_type,
                                 const(ubyte)* data,
                                 c_ulong		 length,
                     cairo_destroy_func_t	 destroy,
                     void* closure);

    alias da_cairo_surface_supports_mime_type = cairo_bool_t function (cairo_surface_t* surface,
                      const(char)* mime_type);

    alias da_cairo_surface_get_font_options = void function (cairo_surface_t* surface,
                    cairo_font_options_t* options);

    alias da_cairo_surface_flush = void function (cairo_surface_t* surface);

    alias da_cairo_surface_mark_dirty = void function (cairo_surface_t* surface);

    alias da_cairo_surface_mark_dirty_rectangle = void function (cairo_surface_t* surface,
                        int              x,
                        int              y,
                        int              width,
                        int              height);

    alias da_cairo_surface_set_device_scale = void function (cairo_surface_t* surface,
                    double           x_scale,
                    double           y_scale);

    alias da_cairo_surface_get_device_scale = void function (cairo_surface_t* surface,
                    double* x_scale,
                    double* y_scale);

    alias da_cairo_surface_set_device_offset = void function (cairo_surface_t* surface,
                     double           x_offset,
                     double           y_offset);

    alias da_cairo_surface_get_device_offset = void function (cairo_surface_t* surface,
                     double* x_offset,
                     double* y_offset);

    alias da_cairo_surface_set_fallback_resolution = void function (cairo_surface_t* surface,
                           double		 x_pixels_per_inch,
                           double		 y_pixels_per_inch);

    alias da_cairo_surface_get_fallback_resolution = void function (cairo_surface_t* surface,
                           double* x_pixels_per_inch,
                           double* y_pixels_per_inch);

    alias da_cairo_surface_copy_page = void function (cairo_surface_t* surface);

    alias da_cairo_surface_show_page = void function (cairo_surface_t* surface);

    alias da_cairo_surface_has_show_text_glyphs = cairo_bool_t function (cairo_surface_t* surface);

    alias da_cairo_image_surface_create = cairo_surface_t* function (cairo_format_t	format,
                    int			width,
                    int			height);

    alias da_cairo_format_stride_for_width = int function (cairo_format_t	format,
                       int		width);

    alias da_cairo_image_surface_create_for_data = cairo_surface_t* function (ubyte* data,
                         cairo_format_t		format,
                         int			width,
                         int			height,
                         int			stride);

    alias da_cairo_image_surface_get_data = ubyte* function (cairo_surface_t* surface);

    alias da_cairo_image_surface_get_format = cairo_format_t function (cairo_surface_t* surface);

    alias da_cairo_image_surface_get_width = int function (cairo_surface_t* surface);

    alias da_cairo_image_surface_get_height = int function (cairo_surface_t* surface);

    alias da_cairo_image_surface_get_stride = int function (cairo_surface_t* surface);


    alias da_cairo_recording_surface_create = cairo_surface_t* function (cairo_content_t		 content,
                                    const(cairo_rectangle_t)* extents);

    alias da_cairo_recording_surface_ink_extents = void function (cairo_surface_t* surface,
                                         double* x0,
                                         double* y0,
                                         double* width,
                                         double* height);

    alias da_cairo_recording_surface_get_extents = cairo_bool_t function (cairo_surface_t* surface,
                         cairo_rectangle_t* extents);


    alias da_cairo_pattern_create_raster_source = cairo_pattern_t* function (void* user_data,
                        cairo_content_t content,
                        int width, int height);

    alias da_cairo_raster_source_pattern_set_callback_data = void function (cairo_pattern_t* pattern,
                               void* data);

    alias da_cairo_raster_source_pattern_get_callback_data = void* function (cairo_pattern_t* pattern);

    alias da_cairo_raster_source_pattern_set_acquire = void function (cairo_pattern_t* pattern,
                         cairo_raster_source_acquire_func_t acquire,
                         cairo_raster_source_release_func_t release);

    alias da_cairo_raster_source_pattern_get_acquire = void function (cairo_pattern_t* pattern,
                         cairo_raster_source_acquire_func_t* acquire,
                         cairo_raster_source_release_func_t* release);
    alias da_cairo_raster_source_pattern_set_snapshot = void function (cairo_pattern_t* pattern,
                          cairo_raster_source_snapshot_func_t snapshot);

    alias da_cairo_raster_source_pattern_get_snapshot = cairo_raster_source_snapshot_func_t function (cairo_pattern_t* pattern);

    alias da_cairo_raster_source_pattern_set_copy = void function (cairo_pattern_t* pattern,
                          cairo_raster_source_copy_func_t copy);

    alias da_cairo_raster_source_pattern_get_copy = cairo_raster_source_copy_func_t function (cairo_pattern_t* pattern);

    alias da_cairo_raster_source_pattern_set_finish = void function (cairo_pattern_t* pattern,
                        cairo_raster_source_finish_func_t finish);

    alias da_cairo_raster_source_pattern_get_finish = cairo_raster_source_finish_func_t function (cairo_pattern_t* pattern);


    alias da_cairo_pattern_create_rgb = cairo_pattern_t* function (double red, double green, double blue);

    alias da_cairo_pattern_create_rgba = cairo_pattern_t* function (double red, double green, double blue,
                   double alpha);

    alias da_cairo_pattern_create_for_surface = cairo_pattern_t* function (cairo_surface_t* surface);

    alias da_cairo_pattern_create_linear = cairo_pattern_t* function (double x0, double y0,
                     double x1, double y1);

    alias da_cairo_pattern_create_radial = cairo_pattern_t* function (double cx0, double cy0, double radius0,
                     double cx1, double cy1, double radius1);

    alias da_cairo_pattern_create_mesh = cairo_pattern_t* function ();

    alias da_cairo_pattern_reference = cairo_pattern_t* function (cairo_pattern_t* pattern);

    alias da_cairo_pattern_destroy = void function (cairo_pattern_t* pattern);

    alias da_cairo_pattern_get_reference_count = uint function (cairo_pattern_t* pattern);

    alias da_cairo_pattern_status = cairo_status_t function (cairo_pattern_t* pattern);

    alias da_cairo_pattern_get_user_data = void* function (cairo_pattern_t* pattern,
                     const(cairo_user_data_key_t)* key);

    alias da_cairo_pattern_set_user_data = cairo_status_t function (cairo_pattern_t* pattern,
                     const(cairo_user_data_key_t)* key,
                     void* user_data,
                     cairo_destroy_func_t	  destroy);

    alias da_cairo_pattern_get_type = cairo_pattern_type_t function (cairo_pattern_t* pattern);

    alias da_cairo_pattern_add_color_stop_rgb = void function (cairo_pattern_t* pattern,
                      double offset,
                      double red, double green, double blue);

    alias da_cairo_pattern_add_color_stop_rgba = void function (cairo_pattern_t* pattern,
                       double offset,
                       double red, double green, double blue,
                       double alpha);

    alias da_cairo_mesh_pattern_begin_patch = void function (cairo_pattern_t* pattern);

    alias da_cairo_mesh_pattern_end_patch = void function (cairo_pattern_t* pattern);

    alias da_cairo_mesh_pattern_curve_to = void function (cairo_pattern_t* pattern,
                     double x1, double y1,
                     double x2, double y2,
                     double x3, double y3);

    alias da_cairo_mesh_pattern_line_to = void function (cairo_pattern_t* pattern,
                    double x, double y);

    alias da_cairo_mesh_pattern_move_to = void function (cairo_pattern_t* pattern,
                    double x, double y);

    alias da_cairo_mesh_pattern_set_control_point = void function (cairo_pattern_t* pattern,
                          uint point_num,
                          double x, double y);

    alias da_cairo_mesh_pattern_set_corner_color_rgb = void function (cairo_pattern_t* pattern,
                         uint corner_num,
                         double red, double green, double blue);

    alias da_cairo_mesh_pattern_set_corner_color_rgba = void function (cairo_pattern_t* pattern,
                          uint corner_num,
                          double red, double green, double blue,
                          double alpha);

    alias da_cairo_pattern_set_matrix = void function (cairo_pattern_t* pattern,
                  const(cairo_matrix_t)* matrix);

    alias da_cairo_pattern_get_matrix = void function (cairo_pattern_t* pattern,
                  cairo_matrix_t* matrix);


    alias da_cairo_pattern_set_extend = void function (cairo_pattern_t* pattern, cairo_extend_t extend);

    alias da_cairo_pattern_get_extend = cairo_extend_t function (cairo_pattern_t* pattern);


    alias da_cairo_pattern_set_filter = void function (cairo_pattern_t* pattern, cairo_filter_t filter);

    alias da_cairo_pattern_get_filter = cairo_filter_t function (cairo_pattern_t* pattern);

    alias da_cairo_pattern_get_rgba = cairo_status_t function (cairo_pattern_t* pattern,
                double* red, double* green,
                double* blue, double* alpha);

    alias da_cairo_pattern_get_surface = cairo_status_t function (cairo_pattern_t* pattern,
                   cairo_surface_t* *surface);


    alias da_cairo_pattern_get_color_stop_rgba = cairo_status_t function (cairo_pattern_t* pattern,
                       int index, double* offset,
                       double* red, double* green,
                       double* blue, double* alpha);

    alias da_cairo_pattern_get_color_stop_count = cairo_status_t function (cairo_pattern_t* pattern,
                        int* count);

    alias da_cairo_pattern_get_linear_points = cairo_status_t function (cairo_pattern_t* pattern,
                     double* x0, double* y0,
                     double* x1, double* y1);

    alias da_cairo_pattern_get_radial_circles = cairo_status_t function (cairo_pattern_t* pattern,
                      double* x0, double* y0, double* r0,
                      double* x1, double* y1, double* r1);

    alias da_cairo_mesh_pattern_get_patch_count = cairo_status_t function (cairo_pattern_t* pattern,
                        uint* count);

    alias da_cairo_mesh_pattern_get_path = cairo_path_t* function (cairo_pattern_t* pattern,
                     uint patch_num);

    alias da_cairo_mesh_pattern_get_corner_color_rgba = cairo_status_t function (cairo_pattern_t* pattern,
                          uint patch_num,
                          uint corner_num,
                          double* red, double* green,
                          double* blue, double* alpha);

    alias da_cairo_mesh_pattern_get_control_point = cairo_status_t function (cairo_pattern_t* pattern,
                          uint patch_num,
                          uint point_num,
                          double* x, double* y);

    alias da_cairo_matrix_init = void function (cairo_matrix_t* matrix,
               double  xx, double  yx,
               double  xy, double  yy,
               double  x0, double  y0);

    alias da_cairo_matrix_init_identity = void function (cairo_matrix_t* matrix);

    alias da_cairo_matrix_init_translate = void function (cairo_matrix_t* matrix,
                     double tx, double ty);

    alias da_cairo_matrix_init_scale = void function (cairo_matrix_t* matrix,
                 double sx, double sy);

    alias da_cairo_matrix_init_rotate = void function (cairo_matrix_t* matrix,
                  double radians);

    alias da_cairo_matrix_translate = void function (cairo_matrix_t* matrix, double tx, double ty);

    alias da_cairo_matrix_scale = void function (cairo_matrix_t* matrix, double sx, double sy);

    alias da_cairo_matrix_rotate = void function (cairo_matrix_t* matrix, double radians);

    alias da_cairo_matrix_invert = cairo_status_t function (cairo_matrix_t* matrix);

    alias da_cairo_matrix_multiply = void function (cairo_matrix_t* result,
                   const(cairo_matrix_t)* a,
                   const(cairo_matrix_t)* b);

    alias da_cairo_matrix_transform_distance = void function (const(cairo_matrix_t)* matrix,
                     double* dx, double* dy);

    alias da_cairo_matrix_transform_point = void function (const(cairo_matrix_t)* matrix,
                      double* x, double* y);


    alias da_cairo_region_create = cairo_region_t* function ();

    alias da_cairo_region_create_rectangle = cairo_region_t* function (const(cairo_rectangle_int_t)* rectangle);

    alias da_cairo_region_create_rectangles = cairo_region_t* function (const(cairo_rectangle_int_t)* rects,
                    int count);

    alias da_cairo_region_copy = cairo_region_t* function (const(cairo_region_t)* original);

    alias da_cairo_region_reference = cairo_region_t* function (cairo_region_t* region);

    alias da_cairo_region_destroy = void function (cairo_region_t* region);

    alias da_cairo_region_equal = cairo_bool_t function (const(cairo_region_t)* a, const(cairo_region_t)* b);

    alias da_cairo_region_status = cairo_status_t function (const(cairo_region_t)* region);

    alias da_cairo_region_get_extents = void function (const cairo_region_t* region,
                  cairo_rectangle_int_t* extents);

    alias da_cairo_region_num_rectangles = int function (const(cairo_region_t)* region);

    alias da_cairo_region_get_rectangle = void function (const cairo_region_t* region,
                    int                    nth,
                    cairo_rectangle_int_t* rectangle);

    alias da_cairo_region_is_empty = cairo_bool_t function (const(cairo_region_t)* region);

    alias da_cairo_region_contains_rectangle = cairo_region_overlap_t function (const(cairo_region_t)* region,
                     const(cairo_rectangle_int_t)* rectangle);

    alias da_cairo_region_contains_point = cairo_bool_t function (const(cairo_region_t)* region, int x, int y);

    alias da_cairo_region_translate = void function (cairo_region_t* region, int dx, int dy);

    alias da_cairo_region_subtract = cairo_status_t function (cairo_region_t* dst, const(cairo_region_t)* other);

    alias da_cairo_region_subtract_rectangle = cairo_status_t function (cairo_region_t* dst,
                     const(cairo_rectangle_int_t)* rectangle);

    alias da_cairo_region_intersect = cairo_status_t function (cairo_region_t* dst, const(cairo_region_t)* other);

    alias da_cairo_region_intersect_rectangle = cairo_status_t function (cairo_region_t* dst,
                      const(cairo_rectangle_int_t)* rectangle);

    alias da_cairo_region_union = cairo_status_t function (cairo_region_t* dst, const(cairo_region_t)* other);

    alias da_cairo_region_union_rectangle = cairo_status_t function (cairo_region_t* dst,
                      const(cairo_rectangle_int_t)* rectangle);

    alias da_cairo_region_xor = cairo_status_t function (cairo_region_t* dst, const(cairo_region_t)* other);

    alias da_cairo_region_xor_rectangle = cairo_status_t function (cairo_region_t* dst,
                    const(cairo_rectangle_int_t)* rectangle);

    alias da_cairo_debug_reset_static_data = void function ();
}


__gshared
{
    da_cairo_version cairo_version;

    da_cairo_version_string cairo_version_string;

    da_cairo_create cairo_create;

    da_cairo_reference cairo_reference;

    da_cairo_destroy cairo_destroy;

    da_cairo_get_reference_count cairo_get_reference_count;

    da_cairo_get_user_data cairo_get_user_data;

    da_cairo_set_user_data cairo_set_user_data;

    da_cairo_save cairo_save;

    da_cairo_restore cairo_restore;

    da_cairo_push_group cairo_push_group;

    da_cairo_push_group_with_content cairo_push_group_with_content;

    da_cairo_pop_group cairo_pop_group;

    da_cairo_pop_group_to_source cairo_pop_group_to_source;


    da_cairo_set_operator cairo_set_operator;

    da_cairo_set_source cairo_set_source;

    da_cairo_set_source_rgb cairo_set_source_rgb;

    da_cairo_set_source_rgba cairo_set_source_rgba;

    da_cairo_set_source_surface cairo_set_source_surface;

    da_cairo_set_tolerance cairo_set_tolerance;


    da_cairo_set_antialias cairo_set_antialias;

    da_cairo_set_fill_rule cairo_set_fill_rule;

    da_cairo_set_line_width cairo_set_line_width;

    da_cairo_set_line_cap cairo_set_line_cap;

    da_cairo_set_line_join cairo_set_line_join;

    da_cairo_set_dash cairo_set_dash;

    da_cairo_set_miter_limit cairo_set_miter_limit;

    da_cairo_translate cairo_translate;

    da_cairo_scale cairo_scale;

    da_cairo_rotate cairo_rotate;

    da_cairo_transform cairo_transform;

    da_cairo_set_matrix cairo_set_matrix;

    da_cairo_identity_matrix cairo_identity_matrix;

    da_cairo_user_to_device cairo_user_to_device;

    da_cairo_user_to_device_distance cairo_user_to_device_distance;

    da_cairo_device_to_user cairo_device_to_user;

    da_cairo_device_to_user_distance cairo_device_to_user_distance;

    da_cairo_new_path cairo_new_path;

    da_cairo_move_to cairo_move_to;

    da_cairo_new_sub_path cairo_new_sub_path;

    da_cairo_line_to cairo_line_to;

    da_cairo_curve_to cairo_curve_to;

    da_cairo_arc cairo_arc;

    da_cairo_arc_negative cairo_arc_negative;


    da_cairo_rel_move_to cairo_rel_move_to;

    da_cairo_rel_line_to cairo_rel_line_to;

    da_cairo_rel_curve_to cairo_rel_curve_to;

    da_cairo_rectangle cairo_rectangle;


    da_cairo_close_path cairo_close_path;

    da_cairo_path_extents cairo_path_extents;

    da_cairo_paint cairo_paint;

    da_cairo_paint_with_alpha cairo_paint_with_alpha;

    da_cairo_mask cairo_mask;

    da_cairo_mask_surface cairo_mask_surface;

    da_cairo_stroke cairo_stroke;

    da_cairo_stroke_preserve cairo_stroke_preserve;

    da_cairo_fill cairo_fill;

    da_cairo_fill_preserve cairo_fill_preserve;

    da_cairo_copy_page cairo_copy_page;

    da_cairo_show_page cairo_show_page;

    da_cairo_in_stroke cairo_in_stroke;

    da_cairo_in_fill cairo_in_fill;

    da_cairo_in_clip cairo_in_clip;

    da_cairo_stroke_extents cairo_stroke_extents;

    da_cairo_fill_extents cairo_fill_extents;

    da_cairo_reset_clip cairo_reset_clip;

    da_cairo_clip cairo_clip;

    da_cairo_clip_preserve cairo_clip_preserve;

    da_cairo_clip_extents cairo_clip_extents;


    da_cairo_copy_clip_rectangle_list cairo_copy_clip_rectangle_list;

    da_cairo_rectangle_list_destroy cairo_rectangle_list_destroy;


    da_cairo_glyph_allocate cairo_glyph_allocate;

    da_cairo_glyph_free cairo_glyph_free;

    da_cairo_text_cluster_allocate cairo_text_cluster_allocate;

    da_cairo_text_cluster_free cairo_text_cluster_free;


    da_cairo_font_options_create cairo_font_options_create;

    da_cairo_font_options_copy cairo_font_options_copy;

    da_cairo_font_options_destroy cairo_font_options_destroy;

    da_cairo_font_options_status cairo_font_options_status;

    da_cairo_font_options_merge cairo_font_options_merge;
    da_cairo_font_options_equal cairo_font_options_equal;

    da_cairo_font_options_hash cairo_font_options_hash;

    da_cairo_font_options_set_antialias cairo_font_options_set_antialias;
    da_cairo_font_options_get_antialias cairo_font_options_get_antialias;

    da_cairo_font_options_set_subpixel_order cairo_font_options_set_subpixel_order;
    da_cairo_font_options_get_subpixel_order cairo_font_options_get_subpixel_order;

    da_cairo_font_options_set_hint_style cairo_font_options_set_hint_style;
    da_cairo_font_options_get_hint_style cairo_font_options_get_hint_style;

    da_cairo_font_options_set_hint_metrics cairo_font_options_set_hint_metrics;
    da_cairo_font_options_get_hint_metrics cairo_font_options_get_hint_metrics;

    da_cairo_select_font_face cairo_select_font_face;

    da_cairo_set_font_size cairo_set_font_size;

    da_cairo_set_font_matrix cairo_set_font_matrix;

    da_cairo_get_font_matrix cairo_get_font_matrix;

    da_cairo_set_font_options cairo_set_font_options;

    da_cairo_get_font_options cairo_get_font_options;

    da_cairo_set_font_face cairo_set_font_face;

    da_cairo_get_font_face cairo_get_font_face;

    da_cairo_set_scaled_font cairo_set_scaled_font;

    da_cairo_get_scaled_font cairo_get_scaled_font;

    da_cairo_show_text cairo_show_text;

    da_cairo_show_glyphs cairo_show_glyphs;

    da_cairo_show_text_glyphs cairo_show_text_glyphs;

    da_cairo_text_path  cairo_text_path ;

    da_cairo_glyph_path cairo_glyph_path;

    da_cairo_text_extents cairo_text_extents;

    da_cairo_glyph_extents cairo_glyph_extents;

    da_cairo_font_extents cairo_font_extents;


    da_cairo_font_face_reference cairo_font_face_reference;

    da_cairo_font_face_destroy cairo_font_face_destroy;

    da_cairo_font_face_get_reference_count cairo_font_face_get_reference_count;

    da_cairo_font_face_status cairo_font_face_status;



    da_cairo_font_face_get_type cairo_font_face_get_type;

    da_cairo_font_face_get_user_data cairo_font_face_get_user_data;

    da_cairo_font_face_set_user_data cairo_font_face_set_user_data;


    da_cairo_scaled_font_create cairo_scaled_font_create;

    da_cairo_scaled_font_reference cairo_scaled_font_reference;

    da_cairo_scaled_font_destroy cairo_scaled_font_destroy;

    da_cairo_scaled_font_get_reference_count cairo_scaled_font_get_reference_count;

    da_cairo_scaled_font_status cairo_scaled_font_status;

    da_cairo_scaled_font_get_type cairo_scaled_font_get_type;

    da_cairo_scaled_font_get_user_data cairo_scaled_font_get_user_data;

    da_cairo_scaled_font_set_user_data cairo_scaled_font_set_user_data;

    da_cairo_scaled_font_extents cairo_scaled_font_extents;

    da_cairo_scaled_font_text_extents cairo_scaled_font_text_extents;

    da_cairo_scaled_font_glyph_extents cairo_scaled_font_glyph_extents;

    da_cairo_scaled_font_text_to_glyphs cairo_scaled_font_text_to_glyphs;

    da_cairo_scaled_font_get_font_face cairo_scaled_font_get_font_face;

    da_cairo_scaled_font_get_font_matrix cairo_scaled_font_get_font_matrix;

    da_cairo_scaled_font_get_ctm cairo_scaled_font_get_ctm;

    da_cairo_scaled_font_get_scale_matrix cairo_scaled_font_get_scale_matrix;

    da_cairo_scaled_font_get_font_options cairo_scaled_font_get_font_options;


    da_cairo_toy_font_face_create cairo_toy_font_face_create;

    da_cairo_toy_font_face_get_family cairo_toy_font_face_get_family;

    da_cairo_toy_font_face_get_slant cairo_toy_font_face_get_slant;

    da_cairo_toy_font_face_get_weight cairo_toy_font_face_get_weight;



    da_cairo_user_font_face_create cairo_user_font_face_create;

    da_cairo_user_font_face_set_init_func cairo_user_font_face_set_init_func;

    da_cairo_user_font_face_set_render_glyph_func cairo_user_font_face_set_render_glyph_func;

    da_cairo_user_font_face_set_text_to_glyphs_func cairo_user_font_face_set_text_to_glyphs_func;

    da_cairo_user_font_face_set_unicode_to_glyph_func cairo_user_font_face_set_unicode_to_glyph_func;


    da_cairo_user_font_face_get_init_func cairo_user_font_face_get_init_func;

    da_cairo_user_font_face_get_render_glyph_func cairo_user_font_face_get_render_glyph_func;

    da_cairo_user_font_face_get_text_to_glyphs_func cairo_user_font_face_get_text_to_glyphs_func;

    da_cairo_user_font_face_get_unicode_to_glyph_func cairo_user_font_face_get_unicode_to_glyph_func;


    da_cairo_get_operator cairo_get_operator;

    da_cairo_get_source cairo_get_source;

    da_cairo_get_tolerance cairo_get_tolerance;

    da_cairo_get_antialias cairo_get_antialias;

    da_cairo_has_current_point cairo_has_current_point;

    da_cairo_get_current_point cairo_get_current_point;

    da_cairo_get_fill_rule cairo_get_fill_rule;

    da_cairo_get_line_width cairo_get_line_width;

    da_cairo_get_line_cap cairo_get_line_cap;

    da_cairo_get_line_join cairo_get_line_join;

    da_cairo_get_miter_limit cairo_get_miter_limit;

    da_cairo_get_dash_count cairo_get_dash_count;

    da_cairo_get_dash cairo_get_dash;

    da_cairo_get_matrix cairo_get_matrix;

    da_cairo_get_target cairo_get_target;

    da_cairo_get_group_target cairo_get_group_target;

    da_cairo_copy_path cairo_copy_path;

    da_cairo_copy_path_flat cairo_copy_path_flat;

    da_cairo_append_path cairo_append_path;

    da_cairo_path_destroy cairo_path_destroy;


    da_cairo_status cairo_status;

    da_cairo_status_to_string cairo_status_to_string;


    da_cairo_device_reference cairo_device_reference;


    da_cairo_device_get_type cairo_device_get_type;

    da_cairo_device_status cairo_device_status;

    da_cairo_device_acquire cairo_device_acquire;

    da_cairo_device_release cairo_device_release;

    da_cairo_device_flush cairo_device_flush;

    da_cairo_device_finish cairo_device_finish;

    da_cairo_device_destroy cairo_device_destroy;

    da_cairo_device_get_reference_count cairo_device_get_reference_count;

    da_cairo_device_get_user_data cairo_device_get_user_data;

    da_cairo_device_set_user_data cairo_device_set_user_data;


    da_cairo_surface_create_similar cairo_surface_create_similar;

    da_cairo_surface_create_similar_image cairo_surface_create_similar_image;

    da_cairo_surface_map_to_image cairo_surface_map_to_image;

    da_cairo_surface_unmap_image cairo_surface_unmap_image;

    da_cairo_surface_create_for_rectangle cairo_surface_create_for_rectangle;


    da_cairo_surface_create_observer cairo_surface_create_observer;

    da_cairo_surface_observer_add_paint_callback cairo_surface_observer_add_paint_callback;

    da_cairo_surface_observer_add_mask_callback cairo_surface_observer_add_mask_callback;

    da_cairo_surface_observer_add_fill_callback cairo_surface_observer_add_fill_callback;

    da_cairo_surface_observer_add_stroke_callback cairo_surface_observer_add_stroke_callback;

    da_cairo_surface_observer_add_glyphs_callback cairo_surface_observer_add_glyphs_callback;

    da_cairo_surface_observer_add_flush_callback cairo_surface_observer_add_flush_callback;

    da_cairo_surface_observer_add_finish_callback cairo_surface_observer_add_finish_callback;

    da_cairo_surface_observer_print cairo_surface_observer_print;
    da_cairo_surface_observer_elapsed cairo_surface_observer_elapsed;

    da_cairo_device_observer_print cairo_device_observer_print;

    da_cairo_device_observer_elapsed cairo_device_observer_elapsed;

    da_cairo_device_observer_paint_elapsed cairo_device_observer_paint_elapsed;

    da_cairo_device_observer_mask_elapsed cairo_device_observer_mask_elapsed;

    da_cairo_device_observer_fill_elapsed cairo_device_observer_fill_elapsed;

    da_cairo_device_observer_stroke_elapsed cairo_device_observer_stroke_elapsed;

    da_cairo_device_observer_glyphs_elapsed cairo_device_observer_glyphs_elapsed;

    da_cairo_surface_reference cairo_surface_reference;

    da_cairo_surface_finish cairo_surface_finish;

    da_cairo_surface_destroy cairo_surface_destroy;

    da_cairo_surface_get_device cairo_surface_get_device;

    da_cairo_surface_get_reference_count cairo_surface_get_reference_count;

    da_cairo_surface_status cairo_surface_status;


    da_cairo_surface_get_type cairo_surface_get_type;

    da_cairo_surface_get_content cairo_surface_get_content;


    da_cairo_surface_get_user_data cairo_surface_get_user_data;

    da_cairo_surface_set_user_data cairo_surface_set_user_data;


    da_cairo_surface_get_mime_data cairo_surface_get_mime_data;

    da_cairo_surface_set_mime_data cairo_surface_set_mime_data;

    da_cairo_surface_supports_mime_type cairo_surface_supports_mime_type;

    da_cairo_surface_get_font_options cairo_surface_get_font_options;

    da_cairo_surface_flush cairo_surface_flush;

    da_cairo_surface_mark_dirty cairo_surface_mark_dirty;

    da_cairo_surface_mark_dirty_rectangle cairo_surface_mark_dirty_rectangle;

    da_cairo_surface_set_device_scale cairo_surface_set_device_scale;

    da_cairo_surface_get_device_scale cairo_surface_get_device_scale;

    da_cairo_surface_set_device_offset cairo_surface_set_device_offset;

    da_cairo_surface_get_device_offset cairo_surface_get_device_offset;

    da_cairo_surface_set_fallback_resolution cairo_surface_set_fallback_resolution;

    da_cairo_surface_get_fallback_resolution cairo_surface_get_fallback_resolution;

    da_cairo_surface_copy_page cairo_surface_copy_page;

    da_cairo_surface_show_page cairo_surface_show_page;

    da_cairo_surface_has_show_text_glyphs cairo_surface_has_show_text_glyphs;

    da_cairo_image_surface_create cairo_image_surface_create;

    da_cairo_format_stride_for_width cairo_format_stride_for_width;

    da_cairo_image_surface_create_for_data cairo_image_surface_create_for_data;

    da_cairo_image_surface_get_data cairo_image_surface_get_data;

    da_cairo_image_surface_get_format cairo_image_surface_get_format;

    da_cairo_image_surface_get_width cairo_image_surface_get_width;

    da_cairo_image_surface_get_height cairo_image_surface_get_height;

    da_cairo_image_surface_get_stride cairo_image_surface_get_stride;


    da_cairo_recording_surface_create cairo_recording_surface_create;

    da_cairo_recording_surface_ink_extents cairo_recording_surface_ink_extents;

    da_cairo_recording_surface_get_extents cairo_recording_surface_get_extents;


    da_cairo_pattern_create_raster_source cairo_pattern_create_raster_source;

    da_cairo_raster_source_pattern_set_callback_data cairo_raster_source_pattern_set_callback_data;

    da_cairo_raster_source_pattern_get_callback_data cairo_raster_source_pattern_get_callback_data;

    da_cairo_raster_source_pattern_set_acquire cairo_raster_source_pattern_set_acquire;

    da_cairo_raster_source_pattern_get_acquire cairo_raster_source_pattern_get_acquire;
    da_cairo_raster_source_pattern_set_snapshot cairo_raster_source_pattern_set_snapshot;

    da_cairo_raster_source_pattern_get_snapshot cairo_raster_source_pattern_get_snapshot;

    da_cairo_raster_source_pattern_set_copy cairo_raster_source_pattern_set_copy;

    da_cairo_raster_source_pattern_get_copy cairo_raster_source_pattern_get_copy;

    da_cairo_raster_source_pattern_set_finish cairo_raster_source_pattern_set_finish;

    da_cairo_raster_source_pattern_get_finish cairo_raster_source_pattern_get_finish;


    da_cairo_pattern_create_rgb cairo_pattern_create_rgb;

    da_cairo_pattern_create_rgba cairo_pattern_create_rgba;

    da_cairo_pattern_create_for_surface cairo_pattern_create_for_surface;

    da_cairo_pattern_create_linear cairo_pattern_create_linear;

    da_cairo_pattern_create_radial cairo_pattern_create_radial;

    da_cairo_pattern_create_mesh cairo_pattern_create_mesh;

    da_cairo_pattern_reference cairo_pattern_reference;

    da_cairo_pattern_destroy cairo_pattern_destroy;

    da_cairo_pattern_get_reference_count cairo_pattern_get_reference_count;

    da_cairo_pattern_status cairo_pattern_status;

    da_cairo_pattern_get_user_data cairo_pattern_get_user_data;

    da_cairo_pattern_set_user_data cairo_pattern_set_user_data;

    da_cairo_pattern_get_type cairo_pattern_get_type;

    da_cairo_pattern_add_color_stop_rgb cairo_pattern_add_color_stop_rgb;

    da_cairo_pattern_add_color_stop_rgba cairo_pattern_add_color_stop_rgba;

    da_cairo_mesh_pattern_begin_patch cairo_mesh_pattern_begin_patch;

    da_cairo_mesh_pattern_end_patch cairo_mesh_pattern_end_patch;

    da_cairo_mesh_pattern_curve_to cairo_mesh_pattern_curve_to;

    da_cairo_mesh_pattern_line_to cairo_mesh_pattern_line_to;

    da_cairo_mesh_pattern_move_to cairo_mesh_pattern_move_to;

    da_cairo_mesh_pattern_set_control_point cairo_mesh_pattern_set_control_point;

    da_cairo_mesh_pattern_set_corner_color_rgb cairo_mesh_pattern_set_corner_color_rgb;

    da_cairo_mesh_pattern_set_corner_color_rgba cairo_mesh_pattern_set_corner_color_rgba;

    da_cairo_pattern_set_matrix cairo_pattern_set_matrix;

    da_cairo_pattern_get_matrix cairo_pattern_get_matrix;


    da_cairo_pattern_set_extend cairo_pattern_set_extend;

    da_cairo_pattern_get_extend cairo_pattern_get_extend;


    da_cairo_pattern_set_filter cairo_pattern_set_filter;

    da_cairo_pattern_get_filter cairo_pattern_get_filter;

    da_cairo_pattern_get_rgba cairo_pattern_get_rgba;

    da_cairo_pattern_get_surface cairo_pattern_get_surface;


    da_cairo_pattern_get_color_stop_rgba cairo_pattern_get_color_stop_rgba;

    da_cairo_pattern_get_color_stop_count cairo_pattern_get_color_stop_count;

    da_cairo_pattern_get_linear_points cairo_pattern_get_linear_points;

    da_cairo_pattern_get_radial_circles cairo_pattern_get_radial_circles;

    da_cairo_mesh_pattern_get_patch_count cairo_mesh_pattern_get_patch_count;

    da_cairo_mesh_pattern_get_path cairo_mesh_pattern_get_path;

    da_cairo_mesh_pattern_get_corner_color_rgba cairo_mesh_pattern_get_corner_color_rgba;

    da_cairo_mesh_pattern_get_control_point cairo_mesh_pattern_get_control_point;

    da_cairo_matrix_init cairo_matrix_init;

    da_cairo_matrix_init_identity cairo_matrix_init_identity;

    da_cairo_matrix_init_translate cairo_matrix_init_translate;

    da_cairo_matrix_init_scale cairo_matrix_init_scale;

    da_cairo_matrix_init_rotate cairo_matrix_init_rotate;

    da_cairo_matrix_translate cairo_matrix_translate;

    da_cairo_matrix_scale cairo_matrix_scale;

    da_cairo_matrix_rotate cairo_matrix_rotate;

    da_cairo_matrix_invert cairo_matrix_invert;

    da_cairo_matrix_multiply cairo_matrix_multiply;

    da_cairo_matrix_transform_distance cairo_matrix_transform_distance;

    da_cairo_matrix_transform_point cairo_matrix_transform_point;


    da_cairo_region_create cairo_region_create;

    da_cairo_region_create_rectangle cairo_region_create_rectangle;

    da_cairo_region_create_rectangles cairo_region_create_rectangles;

    da_cairo_region_copy cairo_region_copy;

    da_cairo_region_reference cairo_region_reference;

    da_cairo_region_destroy cairo_region_destroy;

    da_cairo_region_equal cairo_region_equal;

    da_cairo_region_status cairo_region_status;

    da_cairo_region_get_extents cairo_region_get_extents;

    da_cairo_region_num_rectangles cairo_region_num_rectangles;

    da_cairo_region_get_rectangle cairo_region_get_rectangle;

    da_cairo_region_is_empty cairo_region_is_empty;

    da_cairo_region_contains_rectangle cairo_region_contains_rectangle;

    da_cairo_region_contains_point cairo_region_contains_point;

    da_cairo_region_translate cairo_region_translate;

    da_cairo_region_subtract cairo_region_subtract;

    da_cairo_region_subtract_rectangle cairo_region_subtract_rectangle;

    da_cairo_region_intersect cairo_region_intersect;

    da_cairo_region_intersect_rectangle cairo_region_intersect_rectangle;

    da_cairo_region_union cairo_region_union;

    da_cairo_region_union_rectangle cairo_region_union_rectangle;

    da_cairo_region_xor cairo_region_xor;

    da_cairo_region_xor_rectangle cairo_region_xor_rectangle;

    da_cairo_debug_reset_static_data cairo_debug_reset_static_data;
}

