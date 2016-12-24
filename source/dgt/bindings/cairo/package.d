module dgt.bindings.cairo;

public import dgt.bindings.cairo.enums;
public import dgt.bindings.cairo.types;
public import dgt.bindings.cairo.png;
public import dgt.bindings.cairo.xcb;
public import dgt.bindings.cairo.win32;
import dgt.bindings;

import std.typecons : Flag, Yes, No;
import std.meta : AliasSeq;
import core.stdc.config : c_ulong;

/// Load the cairo library symbols.
/// Must be called before any use of cairo_* functions.
/// If no libNames is provided, a per-platform guess is performed.
public void loadCairoSymbols(string[] libNames = [])
{
    version (linux)
    {
        auto defaultLibNames = ["libcairo.so", "libcairo.so.2"];
    }
    if (libNames.length == 0)
    {
        libNames = defaultLibNames;
    }
    cairoLoader.load(libNames);
}

/// Checks whether cairo is loaded
public @property bool cairoLoaded()
{
    return cairoLoader.loaded;
}

version(linux)
{
    /// Checks whether cairo has XCB surface symbols loaded
    public @property bool cairoHasXcb()
    in
    {
        assert(cairoLoaded);
    }
    body
    {
        return cairo_xcb_surface_create.bound;
    }
}

shared static ~this()
{
    cairoLoader.unload();
}

private CairoLoader cairoLoader;

// cairo symbols are logically grouped in AliasSeq that are concatenated in the
// SymbolLoader instanciation.

private alias CairoLoader = SymbolLoader!(
    CairoContextSymbols,
    CairoPathSymbols,
    // CairoTransformSymbols,
    // CairoTextSymbols,
    // CairoDeviceSymbols,
    CairoSurfaceSymbols,
    // CairoImageSymbols,
    // CairoRasterSourceSymbols,
    // CairoRecordingSymbols,
    CairoPatternSymbols,
    // CairoMatrixSymbols,
    // CairoRegionSymbols,
    // CairoDebugSymbols,

    // CairoPngSymbols,
    CairoPlatformSymbols,
);

alias CairoContextSymbols = AliasSeq!(
    cairo_create,
    // cairo_reference,
    cairo_destroy,
    // cairo_get_reference_count,
    // cairo_get_user_data,
    // cairo_set_user_data,
    cairo_save,
    cairo_restore,
    // cairo_push_group,
    // cairo_push_group_with_content,
    // cairo_pop_group,
    // cairo_pop_group_to_source,
    // cairo_set_operator,
    cairo_set_source,
    // cairo_set_source_rgb,
    cairo_set_source_rgba,
    // cairo_set_source_surface,
    // cairo_set_tolerance,
    // cairo_set_antialias,
    cairo_set_fill_rule,
    cairo_set_line_width,
    cairo_set_line_cap,
    cairo_set_line_join,
    cairo_set_dash,
    cairo_set_miter_limit,
    cairo_paint,
    // cairo_paint_with_alpha,
    // cairo_mask,
    // cairo_mask_surface,
    cairo_stroke,
    // cairo_stroke_preserve,
    cairo_fill,
    cairo_fill_preserve,
    // cairo_copy_page,
    // cairo_show_page,
    // cairo_in_stroke,
    // cairo_in_fill,
    // cairo_in_clip,
    // cairo_stroke_extents,
    // cairo_fill_extents,
    cairo_reset_clip,
    cairo_clip,
    // cairo_clip_preserve,
    // cairo_clip_extents,
    // cairo_copy_clip_rectangle_list,
    // cairo_rectangle_list_destroy,
    // cairo_get_operator,
    cairo_get_source,
    // cairo_get_tolerance,
    // cairo_get_antialias,
    // cairo_has_current_point,
    // cairo_get_current_point,
    cairo_get_fill_rule,
    cairo_get_line_width,
    cairo_get_line_cap,
    cairo_get_line_join,
    cairo_get_miter_limit,
    cairo_get_dash_count,
    cairo_get_dash,
    // cairo_get_target,
    // cairo_get_group_target,
    // cairo_status,
    // cairo_status_to_string,
);

alias CairoPathSymbols = AliasSeq!(
    // cairo_copy_path,
    // cairo_copy_path_flat,
    // cairo_append_path,
    // cairo_path_destroy,
    cairo_new_path,
    cairo_move_to,
    // cairo_new_sub_path,
    cairo_line_to,
    cairo_curve_to,
    // cairo_arc,
    // cairo_arc_negative,
    // cairo_rel_move_to,
    // cairo_rel_line_to,
    // cairo_rel_curve_to,
    // cairo_rectangle,
    cairo_close_path,
    // cairo_path_extents,
);

alias CairoTransformSymbols = AliasSeq!(
//     cairo_translate,
//     cairo_scale,
//     cairo_rotate,
//     cairo_transform,
    cairo_get_matrix,
    cairo_set_matrix,
//     cairo_identity_matrix,
//     cairo_user_to_device,
//     cairo_user_to_device_distance,
//     cairo_device_to_user,
//     cairo_device_to_user_distance,
);

// alias CairoTextSymbols = AliasSeq!(
//     cairo_glyph_allocate,
//     cairo_glyph_free,
//     cairo_text_cluster_allocate,
//     cairo_text_cluster_free,
//     cairo_font_options_create,
//     cairo_font_options_copy,
//     cairo_font_options_destroy,
//     cairo_font_options_status,
//     cairo_font_options_merge,
//     cairo_font_options_equal,
//     cairo_font_options_hash,
//     cairo_font_options_set_antialias,
//     cairo_font_options_get_antialias,
//     cairo_font_options_set_subpixel_order,
//     cairo_font_options_get_subpixel_order,
//     cairo_font_options_set_hint_style,
//     cairo_font_options_get_hint_style,
//     cairo_font_options_set_hint_metrics,
//     cairo_font_options_get_hint_metrics,
//     cairo_select_font_face,
//     cairo_set_font_size,
//     cairo_set_font_matrix,
//     cairo_get_font_matrix,
//     cairo_set_font_options,
//     cairo_get_font_options,
//     cairo_set_font_face,
//     cairo_get_font_face,
//     cairo_set_scaled_font,
//     cairo_get_scaled_font,
//     cairo_show_text,
//     cairo_show_glyphs,
//     cairo_show_text_glyphs,
//     cairo_text_path,
//     cairo_glyph_path,
//     cairo_text_extents,
//     cairo_glyph_extents,
//     cairo_font_extents,
//     cairo_font_face_reference,
//     cairo_font_face_destroy,
//     cairo_font_face_get_reference_count,
//     cairo_font_face_status,
//     cairo_font_face_get_type,
//     cairo_font_face_get_user_data,
//     cairo_font_face_set_user_data,
//     cairo_scaled_font_create,
//     cairo_scaled_font_reference,
//     cairo_scaled_font_destroy,
//     cairo_scaled_font_get_reference_count,
//     cairo_scaled_font_status,
//     cairo_scaled_font_get_type,
//     cairo_scaled_font_get_user_data,
//     cairo_scaled_font_set_user_data,
//     cairo_scaled_font_extents,
//     cairo_scaled_font_text_extents,
//     cairo_scaled_font_glyph_extents,
//     cairo_scaled_font_text_to_glyphs,
//     cairo_scaled_font_get_font_face,
//     cairo_scaled_font_get_font_matrix,
//     cairo_scaled_font_get_ctm,
//     cairo_scaled_font_get_scale_matrix,
//     cairo_scaled_font_get_font_options,
//     cairo_toy_font_face_create,
//     cairo_toy_font_face_get_family,
//     cairo_toy_font_face_get_slant,
//     cairo_toy_font_face_get_weight,
//     cairo_user_font_face_create,
//     cairo_user_font_face_set_init_func,
//     cairo_user_font_face_set_render_glyph_func,
//     cairo_user_font_face_set_text_to_glyphs_func,
//     cairo_user_font_face_set_unicode_to_glyph_func,
//     cairo_user_font_face_get_init_func,
//     cairo_user_font_face_get_render_glyph_func,
//     cairo_user_font_face_get_text_to_glyphs_func,
//     cairo_user_font_face_get_unicode_to_glyph_func,
// );

// alias CairoDeviceSymbols = AliasSeq!(
//     cairo_device_reference,
//     cairo_device_get_type,
//     cairo_device_status,
//     cairo_device_acquire,
//     cairo_device_release,
//     cairo_device_flush,
//     cairo_device_finish,
//     cairo_device_destroy,
//     cairo_device_get_reference_count,
//     cairo_device_get_user_data,
//     cairo_device_set_user_data,
//     cairo_device_observer_print,
//     cairo_device_observer_elapsed,
//     cairo_device_observer_paint_elapsed,
//     cairo_device_observer_mask_elapsed,
//     cairo_device_observer_fill_elapsed,
//     cairo_device_observer_stroke_elapsed,
//     cairo_device_observer_glyphs_elapsed,
// );

alias CairoSurfaceSymbols = AliasSeq!(
    cairo_surface_reference,
//     cairo_surface_finish,
    cairo_surface_destroy,
//     cairo_surface_get_device,
//     cairo_surface_get_reference_count,
//     cairo_surface_status,
//     cairo_surface_get_type,
//     cairo_surface_get_content,
//     cairo_surface_get_user_data,
//     cairo_surface_set_user_data,
//     cairo_surface_get_mime_data,
//     cairo_surface_set_mime_data,
//     cairo_surface_supports_mime_type,
//     cairo_surface_get_font_options,
    cairo_surface_flush,
//     cairo_surface_mark_dirty,
//     cairo_surface_mark_dirty_rectangle,
//     cairo_surface_set_device_scale,
//     cairo_surface_get_device_scale,
//     cairo_surface_set_device_offset,
//     cairo_surface_get_device_offset,
//     cairo_surface_set_fallback_resolution,
//     cairo_surface_get_fallback_resolution,
//     cairo_surface_copy_page,
//     cairo_surface_show_page,
//     cairo_surface_has_show_text_glyphs,
//     cairo_surface_create_similar,
//     cairo_surface_create_similar_image,
//     cairo_surface_map_to_image,
//     cairo_surface_unmap_image,
//     cairo_surface_create_for_rectangle,
//     cairo_surface_create_observer,
//     cairo_surface_observer_add_paint_callback,
//     cairo_surface_observer_add_mask_callback,
//     cairo_surface_observer_add_fill_callback,
//     cairo_surface_observer_add_stroke_callback,
//     cairo_surface_observer_add_glyphs_callback,
//     cairo_surface_observer_add_flush_callback,
//     cairo_surface_observer_add_finish_callback,
//     cairo_surface_observer_print,
//     cairo_surface_observer_elapsed,
);

// alias CairoImageSymbols = AliasSeq!(
//     cairo_image_surface_create,
//     cairo_format_stride_for_width,
//     cairo_image_surface_create_for_data,
//     cairo_image_surface_get_data,
//     cairo_image_surface_get_format,
//     cairo_image_surface_get_width,
//     cairo_image_surface_get_height,
//     cairo_image_surface_get_stride,
// );

// alias CairoRecordingSymbols = AliasSeq!(
//     cairo_recording_surface_create,
//     cairo_recording_surface_ink_extents,
//     cairo_recording_surface_get_extents,
// );

// alias CairoRasterSourceSymbols = AliasSeq!(
//     cairo_pattern_create_raster_source,
//     cairo_raster_source_pattern_set_callback_data,
//     cairo_raster_source_pattern_get_callback_data,
//     cairo_raster_source_pattern_set_acquire,
//     cairo_raster_source_pattern_get_acquire,
//     cairo_raster_source_pattern_set_snapshot,
//     cairo_raster_source_pattern_get_snapshot,
//     cairo_raster_source_pattern_set_copy,
//     cairo_raster_source_pattern_get_copy,
//     cairo_raster_source_pattern_set_finish,
//     cairo_raster_source_pattern_get_finish,
// );

alias CairoPatternSymbols = AliasSeq!(
//     cairo_pattern_create_rgb,
    cairo_pattern_create_rgba,
//     cairo_pattern_create_for_surface,
    cairo_pattern_create_linear,
    cairo_pattern_create_radial,
//     cairo_pattern_create_mesh,
    cairo_pattern_reference,
    cairo_pattern_destroy,
//     cairo_pattern_get_reference_count,
//     cairo_pattern_status,
//     cairo_pattern_get_user_data,
//     cairo_pattern_set_user_data,
    cairo_pattern_get_type,
//     cairo_pattern_add_color_stop_rgb,
    cairo_pattern_add_color_stop_rgba,
//     cairo_mesh_pattern_begin_patch,
//     cairo_mesh_pattern_end_patch,
//     cairo_mesh_pattern_curve_to,
//     cairo_mesh_pattern_line_to,
//     cairo_mesh_pattern_move_to,
//     cairo_mesh_pattern_set_control_point,
//     cairo_mesh_pattern_set_corner_color_rgb,
//     cairo_mesh_pattern_set_corner_color_rgba,
//     cairo_pattern_set_matrix,
//     cairo_pattern_get_matrix,
    cairo_pattern_set_extend,
    cairo_pattern_get_extend,
//     cairo_pattern_set_filter,
//     cairo_pattern_get_filter,
    cairo_pattern_get_rgba,
//     cairo_pattern_get_surface,
    cairo_pattern_get_color_stop_rgba,
    cairo_pattern_get_color_stop_count,
    cairo_pattern_get_linear_points,
    cairo_pattern_get_radial_circles,
//     cairo_mesh_pattern_get_patch_count,
//     cairo_mesh_pattern_get_path,
//     cairo_mesh_pattern_get_corner_color_rgba,
//     cairo_mesh_pattern_get_control_point,
);

// alias CairoMatrixSymbols = AliasSeq!(
//     cairo_matrix_init,
//     cairo_matrix_init_identity,
//     cairo_matrix_init_translate,
//     cairo_matrix_init_scale,
//     cairo_matrix_init_rotate,
//     cairo_matrix_translate,
//     cairo_matrix_scale,
//     cairo_matrix_rotate,
//     cairo_matrix_invert,
//     cairo_matrix_multiply,
//     cairo_matrix_transform_distance,
//     cairo_matrix_transform_point,
// );

// alias CairoRegionSymbols = AliasSeq!(
//     cairo_region_create,
//     cairo_region_create_rectangle,
//     cairo_region_create_rectangles,
//     cairo_region_copy,
//     cairo_region_reference,
//     cairo_region_destroy,
//     cairo_region_equal,
//     cairo_region_status,
//     cairo_region_get_extents,
//     cairo_region_num_rectangles,
//     cairo_region_get_rectangle,
//     cairo_region_is_empty,
//     cairo_region_contains_rectangle,
//     cairo_region_contains_point,
//     cairo_region_translate,
//     cairo_region_subtract,
//     cairo_region_subtract_rectangle,
//     cairo_region_intersect,
//     cairo_region_intersect_rectangle,
//     cairo_region_union,
//     cairo_region_union_rectangle,
//     cairo_region_xor,
//     cairo_region_xor_rectangle,
// );

// alias CairoDebugSymbols = AliasSeq!(
//     cairo_debug_reset_static_data,
// );

// alias CairoPngSymbols = AliasSeq!(
//     cairo_surface_write_to_png,						Yes.optional,
//     cairo_surface_write_to_png_stream,				Yes.optional,
//     cairo_image_surface_create_from_png,			Yes.optional,
//     cairo_image_surface_create_from_png_stream,		Yes.optional,
// );


version(linux)
{
    alias CairoXcbSymbols = AliasSeq!(
        cairo_xcb_surface_create,
//         cairo_xcb_surface_create_for_bitmap,
//         cairo_xcb_surface_create_with_xrender_format,
        cairo_xcb_surface_set_size,
//         cairo_xcb_surface_set_drawable,
//         cairo_xcb_device_get_connection,
//         cairo_xcb_device_debug_cap_xshm_version,
//         cairo_xcb_device_debug_cap_xrender_version,
//         cairo_xcb_device_debug_set_precision,
//         cairo_xcb_device_debug_get_precision,
    );
    alias CairoPlatformSymbols = CairoXcbSymbols;
}
// else version(Windows)
// {
//     alias CairoWin32Symbols = AliasSeq!(
//         cairo_win32_surface_create,
//         cairo_win32_printing_surface_create,
//         cairo_win32_surface_create_with_ddb,
//         cairo_win32_surface_create_with_dib,
//         cairo_win32_surface_get_dc,
//         cairo_win32_surface_get_image,
//         cairo_win32_font_face_create_for_logfontw,			Yes.optional,
//         cairo_win32_font_face_create_for_hfont,				Yes.optional,
//         cairo_win32_font_face_create_for_logfontw_hfont,	Yes.optional,
//         cairo_win32_scaled_font_select_font,				Yes.optional,
//         cairo_win32_scaled_font_done_font,					Yes.optional,
//         cairo_win32_scaled_font_get_metrics_factor,			Yes.optional,
//         cairo_win32_scaled_font_get_logical_to_device,		Yes.optional,
//         cairo_win32_scaled_font_get_device_to_logical,		Yes.optional,
//     );
//     alias CairoPlatformSymbols = CairoWin32Symbols;
// }


__gshared Symbol!(cairo_t*, cairo_surface_t*) cairo_create;

// __gshared Symbol!(cairo_t*, cairo_t*) cairo_reference;

__gshared Symbol!(void, cairo_t*) cairo_destroy;

// __gshared Symbol!(uint, cairo_t*) cairo_get_reference_count;

// __gshared Symbol!(void*, cairo_t*) cairo_get_user_data;

// __gshared Symbol!(cairo_status_t, cairo_t*, const(cairo_user_data_key_t)*, void*, cairo_destroy_func_t) cairo_set_user_data;

__gshared Symbol!(void, cairo_t*) cairo_save;

__gshared Symbol!(void, cairo_t*) cairo_restore;

// __gshared Symbol!(void, cairo_t*) cairo_push_group;

// __gshared Symbol!(void, cairo_t*, cairo_content_t) cairo_push_group_with_content;

// __gshared Symbol!(cairo_pattern_t*, cairo_t*) cairo_pop_group;

// __gshared Symbol!(void, cairo_t*) cairo_pop_group_to_source;

// __gshared Symbol!(void, cairo_t*, cairo_operator_t) cairo_set_operator;

__gshared Symbol!(void, cairo_t*, cairo_pattern_t*) cairo_set_source;

// __gshared Symbol!(void, cairo_t*, double, double, double) cairo_set_source_rgb;

__gshared Symbol!(void, cairo_t*, double, double, double, double) cairo_set_source_rgba;

// __gshared Symbol!(void, cairo_t*, cairo_surface_t*, double, double) cairo_set_source_surface;

// __gshared Symbol!(void, cairo_t*, double) cairo_set_tolerance;

// __gshared Symbol!(void, cairo_t*, cairo_antialias_t) cairo_set_antialias;

__gshared Symbol!(void, cairo_t*, cairo_fill_rule_t) cairo_set_fill_rule;

__gshared Symbol!(void, cairo_t*, double) cairo_set_line_width;

__gshared Symbol!(void, cairo_t*, cairo_line_cap_t) cairo_set_line_cap;

__gshared Symbol!(void, cairo_t*, cairo_line_join_t) cairo_set_line_join;

__gshared Symbol!(void, cairo_t*, const(double)*, int, double) cairo_set_dash;

__gshared Symbol!(void, cairo_t*, double) cairo_set_miter_limit;

// __gshared Symbol!(void, cairo_t*, double, double) cairo_translate;

// __gshared Symbol!(void, cairo_t*, double, double) cairo_scale;

// __gshared Symbol!(void, cairo_t*, double) cairo_rotate;

// __gshared Symbol!(void, cairo_t*, const(cairo_matrix_t)*) cairo_transform;

__gshared Symbol!(void, cairo_t*, const(cairo_matrix_t)*) cairo_set_matrix;

// __gshared Symbol!(void, cairo_t*) cairo_identity_matrix;

// __gshared Symbol!(void, cairo_t*, double*, double*) cairo_user_to_device;

// __gshared Symbol!(void, cairo_t*, double*, double*) cairo_user_to_device_distance;

// __gshared Symbol!(void, cairo_t*, double*, double*) cairo_device_to_user;

// __gshared Symbol!(void, cairo_t*, double*, double*) cairo_device_to_user_distance;

__gshared Symbol!(void, cairo_t*) cairo_new_path;

__gshared Symbol!(void, cairo_t*, double, double) cairo_move_to;

// __gshared Symbol!(void, cairo_t*) cairo_new_sub_path;

__gshared Symbol!(void, cairo_t*, double, double) cairo_line_to;

__gshared Symbol!(void, cairo_t*, double, double, double, double, double, double) cairo_curve_to;

// __gshared Symbol!(void, cairo_t*, double, double, double, double, double) cairo_arc;

// __gshared Symbol!(void, cairo_t*, double, double, double, double, double) cairo_arc_negative;

// /* XXX: NYI
// __gshared Symbol!(void, cairo_t* ,
//      double , double ,
//      double , double ,
//      double ) cairo_arc_to;
// */

// __gshared Symbol!(void, cairo_t*, double, double) cairo_rel_move_to;

// __gshared Symbol!(void, cairo_t*, double, double) cairo_rel_line_to;

// __gshared Symbol!(void, cairo_t*, double, double, double, double, double, double) cairo_rel_curve_to;

// __gshared Symbol!(void, cairo_t*, double, double, double, double) cairo_rectangle;

// /* XXX: NYI
// __gshared Symbol!(void, cairo_t* ) cairo_stroke_to_path;
// */

__gshared Symbol!(void, cairo_t*) cairo_close_path;

// __gshared Symbol!(void, cairo_t*, double*, double*, double*, double*) cairo_path_extents;

__gshared Symbol!(void, cairo_t*) cairo_paint;

// __gshared Symbol!(void, cairo_t*, double) cairo_paint_with_alpha;

// __gshared Symbol!(void, cairo_t*, cairo_pattern_t*) cairo_mask;

// __gshared Symbol!(void, cairo_t*, cairo_surface_t*, double, double) cairo_mask_surface;

__gshared Symbol!(void, cairo_t*) cairo_stroke;

// __gshared Symbol!(void, cairo_t*) cairo_stroke_preserve;

__gshared Symbol!(void, cairo_t*) cairo_fill;

__gshared Symbol!(void, cairo_t*) cairo_fill_preserve;

// __gshared Symbol!(void, cairo_t*) cairo_copy_page;

// __gshared Symbol!(void, cairo_t*) cairo_show_page;

// __gshared Symbol!(cairo_bool_t, cairo_t*, double, double) cairo_in_stroke;

// __gshared Symbol!(cairo_bool_t, cairo_t*, double, double) cairo_in_fill;

// __gshared Symbol!(cairo_bool_t, cairo_t*, double, double) cairo_in_clip;

// __gshared Symbol!(void, cairo_t*, double*, double*, double*, double*) cairo_stroke_extents;

// __gshared Symbol!(void, cairo_t*, double*, double*, double*, double*) cairo_fill_extents;

__gshared Symbol!(void, cairo_t*) cairo_reset_clip;

__gshared Symbol!(void, cairo_t*) cairo_clip;

// __gshared Symbol!(void, cairo_t*) cairo_clip_preserve;

// __gshared Symbol!(void, cairo_t*, double*, double*, double*, double*) cairo_clip_extents;

// __gshared Symbol!(cairo_rectangle_list_t*, cairo_t*) cairo_copy_clip_rectangle_list;

// __gshared Symbol!(void, cairo_rectangle_list_t*) cairo_rectangle_list_destroy;

// __gshared Symbol!(cairo_glyph_t*, int) cairo_glyph_allocate;

// __gshared Symbol!(void, cairo_glyph_t*) cairo_glyph_free;

// __gshared Symbol!(cairo_text_cluster_t*, int) cairo_text_cluster_allocate;

// __gshared Symbol!(void, cairo_text_cluster_t*) cairo_text_cluster_free;

// __gshared Symbol!(cairo_font_options_t*) cairo_font_options_create;

// __gshared Symbol!(cairo_font_options_t*, const(cairo_font_options_t)*) cairo_font_options_copy;

// __gshared Symbol!(void, cairo_font_options_t*) cairo_font_options_destroy;

// __gshared Symbol!(cairo_status_t, cairo_font_options_t*) cairo_font_options_status;

// __gshared Symbol!(void, cairo_font_options_t*, const(cairo_font_options_t)*) cairo_font_options_merge;
// __gshared Symbol!(cairo_bool_t, const(cairo_font_options_t)*, const(cairo_font_options_t)*) cairo_font_options_equal;

// __gshared Symbol!(uint, const(cairo_font_options_t)*) cairo_font_options_hash;

// __gshared Symbol!(void, cairo_font_options_t*, cairo_antialias_t) cairo_font_options_set_antialias;
// __gshared Symbol!(cairo_antialias_t, const(cairo_font_options_t)*) cairo_font_options_get_antialias;

// __gshared Symbol!(void, cairo_font_options_t*, cairo_subpixel_order_t) cairo_font_options_set_subpixel_order;
// __gshared Symbol!(cairo_subpixel_order_t, const(cairo_font_options_t)*) cairo_font_options_get_subpixel_order;

// __gshared Symbol!(void, cairo_font_options_t*, cairo_hint_style_t) cairo_font_options_set_hint_style;
// __gshared Symbol!(cairo_hint_style_t, const(cairo_font_options_t)*) cairo_font_options_get_hint_style;

// __gshared Symbol!(void, cairo_font_options_t*, cairo_hint_metrics_t) cairo_font_options_set_hint_metrics;
// __gshared Symbol!(cairo_hint_metrics_t, const(cairo_font_options_t)*) cairo_font_options_get_hint_metrics;

// __gshared Symbol!(void, cairo_t*, const(char)*, cairo_font_slant_t, cairo_font_weight_t) cairo_select_font_face;

// __gshared Symbol!(void, cairo_t*, double) cairo_set_font_size;

// __gshared Symbol!(void, cairo_t*, const(cairo_matrix_t)*) cairo_set_font_matrix;

// __gshared Symbol!(void, cairo_t*, cairo_matrix_t*) cairo_get_font_matrix;

// __gshared Symbol!(void, cairo_t*, const(cairo_font_options_t)*) cairo_set_font_options;

// __gshared Symbol!(void, cairo_t*, cairo_font_options_t*) cairo_get_font_options;

// __gshared Symbol!(void, cairo_t*, cairo_font_face_t*) cairo_set_font_face;

// __gshared Symbol!(cairo_font_face_t*, cairo_t*) cairo_get_font_face;

// __gshared Symbol!(void, cairo_t*, const(cairo_scaled_font_t)*) cairo_set_scaled_font;

// __gshared Symbol!(cairo_scaled_font_t*, cairo_t*) cairo_get_scaled_font;

// __gshared Symbol!(void, cairo_t*, const(char)*) cairo_show_text;

// __gshared Symbol!(void, cairo_t*, const(cairo_glyph_t)*, int) cairo_show_glyphs;

// __gshared Symbol!(void, cairo_t*, const(char)*, int, const(cairo_glyph_t)*, int,
//         const(cairo_text_cluster_t)*, int, cairo_text_cluster_flags_t) cairo_show_text_glyphs;

// __gshared Symbol!(void, cairo_t*, const(char)*) cairo_text_path;

// __gshared Symbol!(void, cairo_t*, const(cairo_glyph_t)*, int) cairo_glyph_path;

// __gshared Symbol!(void, cairo_t*, const(char)*, cairo_text_extents_t*) cairo_text_extents;

// __gshared Symbol!(void, cairo_t*, const(cairo_glyph_t)*, int, cairo_text_extents_t*) cairo_glyph_extents;

// __gshared Symbol!(void, cairo_t*, cairo_font_extents_t*) cairo_font_extents;

// __gshared Symbol!(cairo_font_face_t*, cairo_font_face_t*) cairo_font_face_reference;

// __gshared Symbol!(void, cairo_font_face_t*) cairo_font_face_destroy;

// __gshared Symbol!(uint, cairo_font_face_t*) cairo_font_face_get_reference_count;

// __gshared Symbol!(cairo_status_t, cairo_font_face_t*) cairo_font_face_status;

// __gshared Symbol!(cairo_font_type_t, cairo_font_face_t*) cairo_font_face_get_type;

// __gshared Symbol!(void*, cairo_font_face_t*, const(cairo_user_data_key_t)*) cairo_font_face_get_user_data;

// __gshared Symbol!(cairo_status_t, cairo_font_face_t*, const(cairo_user_data_key_t)*,
//         void*, cairo_destroy_func_t) cairo_font_face_set_user_data;

// __gshared Symbol!(cairo_scaled_font_t*, cairo_font_face_t*, const(cairo_matrix_t)*,
//         const(cairo_matrix_t)*, const(cairo_font_options_t)*) cairo_scaled_font_create;

// __gshared Symbol!(cairo_scaled_font_t*, cairo_scaled_font_t*) cairo_scaled_font_reference;

// __gshared Symbol!(void, cairo_scaled_font_t*) cairo_scaled_font_destroy;

// __gshared Symbol!(uint, cairo_scaled_font_t*) cairo_scaled_font_get_reference_count;

// __gshared Symbol!(cairo_status_t, cairo_scaled_font_t*) cairo_scaled_font_status;

// __gshared Symbol!(cairo_font_type_t, cairo_scaled_font_t*) cairo_scaled_font_get_type;

// __gshared Symbol!(void*, cairo_scaled_font_t*, const(cairo_user_data_key_t)*) cairo_scaled_font_get_user_data;

// __gshared Symbol!(cairo_status_t, cairo_scaled_font_t*, const(cairo_user_data_key_t)*,
//         void*, cairo_destroy_func_t) cairo_scaled_font_set_user_data;

// __gshared Symbol!(void, cairo_scaled_font_t*, cairo_font_extents_t*) cairo_scaled_font_extents;

// __gshared Symbol!(void, cairo_scaled_font_t*, const(char)*, cairo_text_extents_t*) cairo_scaled_font_text_extents;

// __gshared Symbol!(void, cairo_scaled_font_t*, const(cairo_glyph_t)*, int, cairo_text_extents_t*) cairo_scaled_font_glyph_extents;

// __gshared Symbol!(cairo_status_t, cairo_scaled_font_t*, double, double, const(char)*, int,
//         cairo_glyph_t**, int*, cairo_text_cluster_t**, int*, cairo_text_cluster_flags_t*) cairo_scaled_font_text_to_glyphs;

// __gshared Symbol!(cairo_font_face_t*, cairo_scaled_font_t*) cairo_scaled_font_get_font_face;

// __gshared Symbol!(void, cairo_scaled_font_t*, cairo_matrix_t*) cairo_scaled_font_get_font_matrix;

// __gshared Symbol!(void, cairo_scaled_font_t*, cairo_matrix_t*) cairo_scaled_font_get_ctm;

// __gshared Symbol!(void, cairo_scaled_font_t*, cairo_matrix_t*) cairo_scaled_font_get_scale_matrix;

// __gshared Symbol!(void, cairo_scaled_font_t*, cairo_font_options_t*) cairo_scaled_font_get_font_options;

// __gshared Symbol!(cairo_font_face_t*, const(char)*, cairo_font_slant_t, cairo_font_weight_t) cairo_toy_font_face_create;

// __gshared Symbol!(const(char)*, cairo_font_face_t*) cairo_toy_font_face_get_family;

// __gshared Symbol!(cairo_font_slant_t, cairo_font_face_t*) cairo_toy_font_face_get_slant;

// __gshared Symbol!(cairo_font_weight_t, cairo_font_face_t*) cairo_toy_font_face_get_weight;

// __gshared Symbol!(cairo_font_face_t*) cairo_user_font_face_create;

// __gshared Symbol!(void, cairo_font_face_t*, cairo_user_scaled_font_init_func_t) cairo_user_font_face_set_init_func;

// __gshared Symbol!(void, cairo_font_face_t*, cairo_user_scaled_font_render_glyph_func_t) cairo_user_font_face_set_render_glyph_func;

// __gshared Symbol!(void, cairo_font_face_t*, cairo_user_scaled_font_text_to_glyphs_func_t) cairo_user_font_face_set_text_to_glyphs_func;

// __gshared Symbol!(void, cairo_font_face_t*, cairo_user_scaled_font_unicode_to_glyph_func_t) cairo_user_font_face_set_unicode_to_glyph_func;

// __gshared Symbol!(cairo_user_scaled_font_init_func_t, cairo_font_face_t*) cairo_user_font_face_get_init_func;

// __gshared Symbol!(cairo_user_scaled_font_render_glyph_func_t, cairo_font_face_t*) cairo_user_font_face_get_render_glyph_func;

// __gshared Symbol!(cairo_user_scaled_font_text_to_glyphs_func_t, cairo_font_face_t*) cairo_user_font_face_get_text_to_glyphs_func;

// __gshared Symbol!(cairo_user_scaled_font_unicode_to_glyph_func_t, cairo_font_face_t*) cairo_user_font_face_get_unicode_to_glyph_func;

// __gshared Symbol!(cairo_operator_t, cairo_t*) cairo_get_operator;

__gshared Symbol!(cairo_pattern_t*, cairo_t*) cairo_get_source;

// __gshared Symbol!(double, cairo_t*) cairo_get_tolerance;

// __gshared Symbol!(cairo_antialias_t, cairo_t*) cairo_get_antialias;

// __gshared Symbol!(cairo_bool_t, cairo_t*) cairo_has_current_point;

// __gshared Symbol!(void, cairo_t*, double*, double*) cairo_get_current_point;

__gshared Symbol!(cairo_fill_rule_t, cairo_t*) cairo_get_fill_rule;

__gshared Symbol!(double, cairo_t*) cairo_get_line_width;

__gshared Symbol!(cairo_line_cap_t, cairo_t*) cairo_get_line_cap;

__gshared Symbol!(cairo_line_join_t, cairo_t*) cairo_get_line_join;

__gshared Symbol!(double, cairo_t*) cairo_get_miter_limit;

__gshared Symbol!(int, cairo_t*) cairo_get_dash_count;

__gshared Symbol!(void, cairo_t*, double*, double*) cairo_get_dash;

__gshared Symbol!(void, cairo_t*, cairo_matrix_t*) cairo_get_matrix;

// __gshared Symbol!(cairo_surface_t*, cairo_t*) cairo_get_target;

// __gshared Symbol!(cairo_surface_t*, cairo_t*) cairo_get_group_target;

// __gshared Symbol!(cairo_path_t*, cairo_t*) cairo_copy_path;

// __gshared Symbol!(cairo_path_t*, cairo_t*) cairo_copy_path_flat;

// __gshared Symbol!(void, cairo_t*, const(cairo_path_t)*) cairo_append_path;

// __gshared Symbol!(void, cairo_path_t*) cairo_path_destroy;

// __gshared Symbol!(cairo_status_t, cairo_t*) cairo_status;

// __gshared Symbol!(const(char)*, cairo_status_t) cairo_status_to_string;

// __gshared Symbol!(cairo_device_t*, cairo_device_t*) cairo_device_reference;

// __gshared Symbol!(cairo_device_type_t, cairo_device_t*) cairo_device_get_type;

// __gshared Symbol!(cairo_status_t, cairo_device_t*) cairo_device_status;

// __gshared Symbol!(cairo_status_t, cairo_device_t*) cairo_device_acquire;

// __gshared Symbol!(void, cairo_device_t*) cairo_device_release;

// __gshared Symbol!(void, cairo_device_t*) cairo_device_flush;

// __gshared Symbol!(void, cairo_device_t*) cairo_device_finish;

// __gshared Symbol!(void, cairo_device_t*) cairo_device_destroy;

// __gshared Symbol!(uint, cairo_device_t*) cairo_device_get_reference_count;

// __gshared Symbol!(void*, cairo_device_t*, const(cairo_user_data_key_t)*) cairo_device_get_user_data;

// __gshared Symbol!(cairo_status_t, cairo_device_t*, const(cairo_user_data_key_t)*, void*,
//         cairo_destroy_func_t) cairo_device_set_user_data;

// __gshared Symbol!(cairo_surface_t*, cairo_surface_t*, cairo_content_t, int, int) cairo_surface_create_similar;

// __gshared Symbol!(cairo_surface_t*, cairo_surface_t*, cairo_format_t, int, int) cairo_surface_create_similar_image;

// __gshared Symbol!(cairo_surface_t*, cairo_surface_t*, const(cairo_rectangle_int_t)*) cairo_surface_map_to_image;

// __gshared Symbol!(void, cairo_surface_t*, cairo_surface_t*) cairo_surface_unmap_image;

// __gshared Symbol!(cairo_surface_t*, cairo_surface_t*, double, double, double, double) cairo_surface_create_for_rectangle;

// __gshared Symbol!(cairo_surface_t*, cairo_surface_t*, cairo_surface_observer_mode_t) cairo_surface_create_observer;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*, cairo_surface_observer_callback_t, void*) cairo_surface_observer_add_paint_callback;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*, cairo_surface_observer_callback_t, void*) cairo_surface_observer_add_mask_callback;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*, cairo_surface_observer_callback_t, void*) cairo_surface_observer_add_fill_callback;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*, cairo_surface_observer_callback_t, void*) cairo_surface_observer_add_stroke_callback;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*, cairo_surface_observer_callback_t, void*) cairo_surface_observer_add_glyphs_callback;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*, cairo_surface_observer_callback_t, void*) cairo_surface_observer_add_flush_callback;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*, cairo_surface_observer_callback_t, void*) cairo_surface_observer_add_finish_callback;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*, cairo_write_func_t, void*) cairo_surface_observer_print;
// __gshared Symbol!(double, cairo_surface_t*) cairo_surface_observer_elapsed;

// __gshared Symbol!(cairo_status_t, cairo_device_t*, cairo_write_func_t, void*) cairo_device_observer_print;

// __gshared Symbol!(double, cairo_device_t*) cairo_device_observer_elapsed;

// __gshared Symbol!(double, cairo_device_t*) cairo_device_observer_paint_elapsed;

// __gshared Symbol!(double, cairo_device_t*) cairo_device_observer_mask_elapsed;

// __gshared Symbol!(double, cairo_device_t*) cairo_device_observer_fill_elapsed;

// __gshared Symbol!(double, cairo_device_t*) cairo_device_observer_stroke_elapsed;

// __gshared Symbol!(double, cairo_device_t*) cairo_device_observer_glyphs_elapsed;

__gshared Symbol!(cairo_surface_t*, cairo_surface_t*) cairo_surface_reference;

// __gshared Symbol!(void, cairo_surface_t*) cairo_surface_finish;

__gshared Symbol!(void, cairo_surface_t*) cairo_surface_destroy;

// __gshared Symbol!(cairo_device_t*, cairo_surface_t*) cairo_surface_get_device;

// __gshared Symbol!(uint, cairo_surface_t*) cairo_surface_get_reference_count;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*) cairo_surface_status;

// __gshared Symbol!(cairo_surface_type_t, cairo_surface_t*) cairo_surface_get_type;

// __gshared Symbol!(cairo_content_t, cairo_surface_t*) cairo_surface_get_content;

// __gshared Symbol!(void*, cairo_surface_t*, const(cairo_user_data_key_t)*) cairo_surface_get_user_data;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*, const(cairo_user_data_key_t)*,
//         void*, cairo_destroy_func_t) cairo_surface_set_user_data;

// __gshared Symbol!(void, cairo_surface_t*, const(char)*, const(ubyte)**, c_ulong*) cairo_surface_get_mime_data;

// __gshared Symbol!(cairo_status_t, cairo_surface_t*, const(char)*, const(ubyte)*, c_ulong,
//         cairo_destroy_func_t, void*) cairo_surface_set_mime_data;

// __gshared Symbol!(cairo_bool_t, cairo_surface_t*, const(char)*) cairo_surface_supports_mime_type;

// __gshared Symbol!(void, cairo_surface_t*, cairo_font_options_t*) cairo_surface_get_font_options;

__gshared Symbol!(void, cairo_surface_t*) cairo_surface_flush;

// __gshared Symbol!(void, cairo_surface_t*) cairo_surface_mark_dirty;

// __gshared Symbol!(void, cairo_surface_t*, int, int, int, int) cairo_surface_mark_dirty_rectangle;

// __gshared Symbol!(void, cairo_surface_t*, double, double) cairo_surface_set_device_scale;

// __gshared Symbol!(void, cairo_surface_t*, double*, double*) cairo_surface_get_device_scale;

// __gshared Symbol!(void, cairo_surface_t*, double, double) cairo_surface_set_device_offset;

// __gshared Symbol!(void, cairo_surface_t*, double*, double*) cairo_surface_get_device_offset;

// __gshared Symbol!(void, cairo_surface_t*, double, double) cairo_surface_set_fallback_resolution;

// __gshared Symbol!(void, cairo_surface_t*, double*, double*) cairo_surface_get_fallback_resolution;

// __gshared Symbol!(void, cairo_surface_t*) cairo_surface_copy_page;

// __gshared Symbol!(void, cairo_surface_t*) cairo_surface_show_page;

// __gshared Symbol!(cairo_bool_t, cairo_surface_t*) cairo_surface_has_show_text_glyphs;

// __gshared Symbol!(cairo_surface_t*, cairo_format_t, int, int) cairo_image_surface_create;

// __gshared Symbol!(int, cairo_format_t, int) cairo_format_stride_for_width;

// __gshared Symbol!(cairo_surface_t*, ubyte*, cairo_format_t, int, int, int) cairo_image_surface_create_for_data;

// __gshared Symbol!(ubyte*, cairo_surface_t*) cairo_image_surface_get_data;

// __gshared Symbol!(cairo_format_t, cairo_surface_t*) cairo_image_surface_get_format;

// __gshared Symbol!(int, cairo_surface_t*) cairo_image_surface_get_width;

// __gshared Symbol!(int, cairo_surface_t*) cairo_image_surface_get_height;

// __gshared Symbol!(int, cairo_surface_t*) cairo_image_surface_get_stride;

// __gshared Symbol!(cairo_surface_t*, cairo_content_t, const(cairo_rectangle_t)*) cairo_recording_surface_create;

// __gshared Symbol!(void, cairo_surface_t*, double*, double*, double*, double*) cairo_recording_surface_ink_extents;

// __gshared Symbol!(cairo_bool_t, cairo_surface_t*, cairo_rectangle_t*) cairo_recording_surface_get_extents;

// __gshared Symbol!(cairo_pattern_t*, void*, cairo_content_t, int, int) cairo_pattern_create_raster_source;

// __gshared Symbol!(void, cairo_pattern_t*, void*) cairo_raster_source_pattern_set_callback_data;

// __gshared Symbol!(void*, cairo_pattern_t*) cairo_raster_source_pattern_get_callback_data;

// __gshared Symbol!(void, cairo_pattern_t*, cairo_raster_source_acquire_func_t,
//         cairo_raster_source_release_func_t) cairo_raster_source_pattern_set_acquire;

// __gshared Symbol!(void, cairo_pattern_t*, cairo_raster_source_acquire_func_t*,
//         cairo_raster_source_release_func_t*) cairo_raster_source_pattern_get_acquire;
// __gshared Symbol!(void, cairo_pattern_t*, cairo_raster_source_snapshot_func_t) cairo_raster_source_pattern_set_snapshot;

// __gshared Symbol!(cairo_raster_source_snapshot_func_t, cairo_pattern_t*) cairo_raster_source_pattern_get_snapshot;

// __gshared Symbol!(void, cairo_pattern_t*, cairo_raster_source_copy_func_t) cairo_raster_source_pattern_set_copy;

// __gshared Symbol!(cairo_raster_source_copy_func_t, cairo_pattern_t*) cairo_raster_source_pattern_get_copy;

// __gshared Symbol!(void, cairo_pattern_t*, cairo_raster_source_finish_func_t) cairo_raster_source_pattern_set_finish;

// __gshared Symbol!(cairo_raster_source_finish_func_t, cairo_pattern_t*) cairo_raster_source_pattern_get_finish;

// __gshared Symbol!(cairo_pattern_t*, double, double, double) cairo_pattern_create_rgb;

__gshared Symbol!(cairo_pattern_t*, double, double, double, double) cairo_pattern_create_rgba;

// __gshared Symbol!(cairo_pattern_t*, cairo_surface_t*) cairo_pattern_create_for_surface;

__gshared Symbol!(cairo_pattern_t*, double, double, double, double) cairo_pattern_create_linear;

__gshared Symbol!(cairo_pattern_t*, double, double, double, double, double, double) cairo_pattern_create_radial;

// __gshared Symbol!(cairo_pattern_t*) cairo_pattern_create_mesh;

__gshared Symbol!(cairo_pattern_t*, cairo_pattern_t*) cairo_pattern_reference;

__gshared Symbol!(void, cairo_pattern_t*) cairo_pattern_destroy;

// __gshared Symbol!(uint, cairo_pattern_t*) cairo_pattern_get_reference_count;

// __gshared Symbol!(cairo_status_t, cairo_pattern_t*) cairo_pattern_status;

// __gshared Symbol!(void*, cairo_pattern_t*, const(cairo_user_data_key_t)*) cairo_pattern_get_user_data;

// __gshared Symbol!(cairo_status_t, cairo_pattern_t*, const(cairo_user_data_key_t)*,
//         void*, cairo_destroy_func_t) cairo_pattern_set_user_data;

__gshared Symbol!(cairo_pattern_type_t, cairo_pattern_t*) cairo_pattern_get_type;

// __gshared Symbol!(void, cairo_pattern_t*, double, double, double, double) cairo_pattern_add_color_stop_rgb;

__gshared Symbol!(void, cairo_pattern_t*, double, double, double, double, double) cairo_pattern_add_color_stop_rgba;

// __gshared Symbol!(void, cairo_pattern_t*) cairo_mesh_pattern_begin_patch;

// __gshared Symbol!(void, cairo_pattern_t*) cairo_mesh_pattern_end_patch;

// __gshared Symbol!(void, cairo_pattern_t*, double, double, double, double, double, double) cairo_mesh_pattern_curve_to;

// __gshared Symbol!(void, cairo_pattern_t*, double, double) cairo_mesh_pattern_line_to;

// __gshared Symbol!(void, cairo_pattern_t*, double, double) cairo_mesh_pattern_move_to;

// __gshared Symbol!(void, cairo_pattern_t*, uint, double, double) cairo_mesh_pattern_set_control_point;

// __gshared Symbol!(void, cairo_pattern_t*, uint, double, double, double) cairo_mesh_pattern_set_corner_color_rgb;

// __gshared Symbol!(void, cairo_pattern_t*, uint, double, double, double, double) cairo_mesh_pattern_set_corner_color_rgba;

// __gshared Symbol!(void, cairo_pattern_t*, const(cairo_matrix_t)*) cairo_pattern_set_matrix;

// __gshared Symbol!(void, cairo_pattern_t*, cairo_matrix_t*) cairo_pattern_get_matrix;

__gshared Symbol!(void, cairo_pattern_t*, cairo_extend_t) cairo_pattern_set_extend;

__gshared Symbol!(cairo_extend_t, cairo_pattern_t*) cairo_pattern_get_extend;

// __gshared Symbol!(void, cairo_pattern_t*, cairo_filter_t) cairo_pattern_set_filter;

// __gshared Symbol!(cairo_filter_t, cairo_pattern_t*) cairo_pattern_get_filter;

__gshared Symbol!(cairo_status_t, cairo_pattern_t*, double*, double*, double*, double*) cairo_pattern_get_rgba;

// __gshared Symbol!(cairo_status_t, cairo_pattern_t*, cairo_surface_t**) cairo_pattern_get_surface;

__gshared Symbol!(cairo_status_t, cairo_pattern_t*, int, double*, double*, double*, double*, double*) cairo_pattern_get_color_stop_rgba;

__gshared Symbol!(cairo_status_t, cairo_pattern_t*, int*) cairo_pattern_get_color_stop_count;

__gshared Symbol!(cairo_status_t, cairo_pattern_t*, double*, double*, double*, double*) cairo_pattern_get_linear_points;

__gshared Symbol!(cairo_status_t, cairo_pattern_t*, double*, double*, double*,
        double*, double*, double*) cairo_pattern_get_radial_circles;

// __gshared Symbol!(cairo_status_t, cairo_pattern_t*, uint*) cairo_mesh_pattern_get_patch_count;

// __gshared Symbol!(cairo_path_t*, cairo_pattern_t*, uint) cairo_mesh_pattern_get_path;

// __gshared Symbol!(cairo_status_t, cairo_pattern_t*, uint, uint, double*, double*, double*, double*) cairo_mesh_pattern_get_corner_color_rgba;

// __gshared Symbol!(cairo_status_t, cairo_pattern_t*, uint, uint, double*, double*) cairo_mesh_pattern_get_control_point;

// __gshared Symbol!(void, cairo_matrix_t*, double, double, double, double, double, double) cairo_matrix_init;

// __gshared Symbol!(void, cairo_matrix_t*) cairo_matrix_init_identity;

// __gshared Symbol!(void, cairo_matrix_t*, double, double) cairo_matrix_init_translate;

// __gshared Symbol!(void, cairo_matrix_t*, double, double) cairo_matrix_init_scale;

// __gshared Symbol!(void, cairo_matrix_t*, double) cairo_matrix_init_rotate;

// __gshared Symbol!(void, cairo_matrix_t*, double, double) cairo_matrix_translate;

// __gshared Symbol!(void, cairo_matrix_t*, double, double) cairo_matrix_scale;

// __gshared Symbol!(void, cairo_matrix_t*, double) cairo_matrix_rotate;

// __gshared Symbol!(cairo_status_t, cairo_matrix_t*) cairo_matrix_invert;

// __gshared Symbol!(void, cairo_matrix_t*, const(cairo_matrix_t)*, const(cairo_matrix_t)*) cairo_matrix_multiply;

// __gshared Symbol!(void, const(cairo_matrix_t)*, double*, double*) cairo_matrix_transform_distance;

// __gshared Symbol!(void, const(cairo_matrix_t)*, double*, double*) cairo_matrix_transform_point;

// __gshared Symbol!(cairo_region_t*) cairo_region_create;

// __gshared Symbol!(cairo_region_t*, const(cairo_rectangle_int_t)*) cairo_region_create_rectangle;

// __gshared Symbol!(cairo_region_t*, const(cairo_rectangle_int_t)*, int) cairo_region_create_rectangles;

// __gshared Symbol!(cairo_region_t*, const(cairo_region_t)*) cairo_region_copy;

// __gshared Symbol!(cairo_region_t*, cairo_region_t*) cairo_region_reference;

// __gshared Symbol!(void, cairo_region_t*) cairo_region_destroy;

// __gshared Symbol!(cairo_bool_t, const(cairo_region_t)*, const(cairo_region_t)*) cairo_region_equal;

// __gshared Symbol!(cairo_status_t, const(cairo_region_t)*) cairo_region_status;

// __gshared Symbol!(void, const(cairo_region_t)*, cairo_rectangle_int_t*) cairo_region_get_extents;

// __gshared Symbol!(int, const(cairo_region_t)*) cairo_region_num_rectangles;

// __gshared Symbol!(void, const(cairo_region_t)*, int, cairo_rectangle_int_t*) cairo_region_get_rectangle;

// __gshared Symbol!(cairo_bool_t, const(cairo_region_t)*) cairo_region_is_empty;

// __gshared Symbol!(cairo_region_overlap_t, const(cairo_region_t)*, const(cairo_rectangle_int_t)*) cairo_region_contains_rectangle;

// __gshared Symbol!(cairo_bool_t, const(cairo_region_t)*, int, int) cairo_region_contains_point;

// __gshared Symbol!(void, cairo_region_t*, int, int) cairo_region_translate;

// __gshared Symbol!(cairo_status_t, cairo_region_t*, const(cairo_region_t)*) cairo_region_subtract;

// __gshared Symbol!(cairo_status_t, cairo_region_t*, const(cairo_rectangle_int_t)*) cairo_region_subtract_rectangle;

// __gshared Symbol!(cairo_status_t, cairo_region_t*, const(cairo_region_t)*) cairo_region_intersect;

// __gshared Symbol!(cairo_status_t, cairo_region_t*, const(cairo_rectangle_int_t)*) cairo_region_intersect_rectangle;

// __gshared Symbol!(cairo_status_t, cairo_region_t*, const(cairo_region_t)*) cairo_region_union;

// __gshared Symbol!(cairo_status_t, cairo_region_t*, const(cairo_rectangle_int_t)*) cairo_region_union_rectangle;

// __gshared Symbol!(cairo_status_t, cairo_region_t*, const(cairo_region_t)*) cairo_region_xor;

// __gshared Symbol!(cairo_status_t, cairo_region_t*, const(cairo_rectangle_int_t)*) cairo_region_xor_rectangle;

// __gshared Symbol!(void) cairo_debug_reset_static_data;
