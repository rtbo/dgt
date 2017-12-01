module dgt.bindings.cairo.load;

import dgt.bindings.cairo;
import dgt.bindings;

import std.meta;
import std.typecons : Flag, Yes, No;


/// Load the cairo library symbols.
/// Must be called before any use of cairo_* functions.
/// If no libNames is provided, a per-platform guess is performed.
public void loadCairoSymbols(string[] libNames = [])
{
    version (linux)
    {
        auto defaultLibNames = ["libcairo.so", "libcairo.so.2"];
    }
    else version (Windows)
    {
        auto defaultLibNames = ["cairo.dll", "libcairo.dll", "libcairo-2.dll"];
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
        return cairo_xcb_surface_create !is null;
    }
}

shared static this()
{
    cairoLoader = new CairoLoader;
}

shared static ~this()
{
    //cairoLoader.unload();
}

private CairoLoader cairoLoader;

class CairoLoader : SharedLibLoader
{
    override void bindSymbols()
    {
        bind!(cairo_create)();
        bind!(cairo_reference)();
        bind!(cairo_destroy)();
        bind!(cairo_get_reference_count)();
        bind!(cairo_get_user_data)();
        bind!(cairo_set_user_data)();
        bind!(cairo_save)();
        bind!(cairo_restore)();
        bind!(cairo_push_group)();
        bind!(cairo_push_group_with_content)();
        bind!(cairo_pop_group)();
        bind!(cairo_pop_group_to_source)();
        bind!(cairo_set_operator)();
        bind!(cairo_set_source)();
        bind!(cairo_set_source_rgb)();
        bind!(cairo_set_source_rgba)();
        bind!(cairo_set_source_surface)();
        bind!(cairo_set_tolerance)();
        bind!(cairo_set_antialias)();
        bind!(cairo_set_fill_rule)();
        bind!(cairo_set_line_width)();
        bind!(cairo_set_line_cap)();
        bind!(cairo_set_line_join)();
        bind!(cairo_set_dash)();
        bind!(cairo_set_miter_limit)();
        bind!(cairo_paint)();
        bind!(cairo_paint_with_alpha)();
        bind!(cairo_mask)();
        bind!(cairo_mask_surface)();
        bind!(cairo_stroke)();
        bind!(cairo_stroke_preserve)();
        bind!(cairo_fill)();
        bind!(cairo_fill_preserve)();
        bind!(cairo_copy_page)();
        bind!(cairo_show_page)();
        bind!(cairo_in_stroke)();
        bind!(cairo_in_fill)();
        bind!(cairo_in_clip)();
        bind!(cairo_stroke_extents)();
        bind!(cairo_fill_extents)();
        bind!(cairo_reset_clip)();
        bind!(cairo_clip)();
        bind!(cairo_clip_preserve)();
        bind!(cairo_clip_extents)();
        bind!(cairo_copy_clip_rectangle_list)();
        bind!(cairo_rectangle_list_destroy)();
        bind!(cairo_get_operator)();
        bind!(cairo_get_source)();
        bind!(cairo_get_tolerance)();
        bind!(cairo_get_antialias)();
        bind!(cairo_has_current_point)();
        bind!(cairo_get_current_point)();
        bind!(cairo_get_fill_rule)();
        bind!(cairo_get_line_width)();
        bind!(cairo_get_line_cap)();
        bind!(cairo_get_line_join)();
        bind!(cairo_get_miter_limit)();
        bind!(cairo_get_dash_count)();
        bind!(cairo_get_dash)();
        bind!(cairo_get_target)();
        bind!(cairo_get_group_target)();
        bind!(cairo_status)();
        bind!(cairo_status_to_string)();


        bind!(cairo_copy_path)();
        bind!(cairo_copy_path_flat)();
        bind!(cairo_append_path)();
        bind!(cairo_path_destroy)();
        bind!(cairo_new_path)();
        bind!(cairo_move_to)();
        bind!(cairo_new_sub_path)();
        bind!(cairo_line_to)();
        bind!(cairo_curve_to)();
        bind!(cairo_arc)();
        bind!(cairo_arc_negative)();
        bind!(cairo_rel_move_to)();
        bind!(cairo_rel_line_to)();
        bind!(cairo_rel_curve_to)();
        bind!(cairo_rectangle)();
        bind!(cairo_close_path)();
        bind!(cairo_path_extents)();


        bind!(cairo_translate)();
        bind!(cairo_scale)();
        bind!(cairo_rotate)();
        bind!(cairo_transform)();
        bind!(cairo_get_matrix)();
        bind!(cairo_set_matrix)();
        bind!(cairo_identity_matrix)();
        bind!(cairo_user_to_device)();
        bind!(cairo_user_to_device_distance)();
        bind!(cairo_device_to_user)();
        bind!(cairo_device_to_user_distance)();
        bind!(cairo_glyph_allocate)();
        bind!(cairo_glyph_free)();
        bind!(cairo_text_cluster_allocate)();
        bind!(cairo_text_cluster_free)();
        bind!(cairo_font_options_create)();
        bind!(cairo_font_options_copy)();
        bind!(cairo_font_options_destroy)();
        bind!(cairo_font_options_status)();
        bind!(cairo_font_options_merge)();
        bind!(cairo_font_options_equal)();
        bind!(cairo_font_options_hash)();
        bind!(cairo_font_options_set_antialias)();
        bind!(cairo_font_options_get_antialias)();
        bind!(cairo_font_options_set_subpixel_order)();
        bind!(cairo_font_options_get_subpixel_order)();
        bind!(cairo_font_options_set_hint_style)();
        bind!(cairo_font_options_get_hint_style)();
        bind!(cairo_font_options_set_hint_metrics)();
        bind!(cairo_font_options_get_hint_metrics)();
        bind!(cairo_select_font_face)();
        bind!(cairo_set_font_size)();
        bind!(cairo_set_font_matrix)();
        bind!(cairo_get_font_matrix)();
        bind!(cairo_set_font_options)();
        bind!(cairo_get_font_options)();
        bind!(cairo_set_font_face)();
        bind!(cairo_get_font_face)();
        bind!(cairo_set_scaled_font)();
        bind!(cairo_get_scaled_font)();
        bind!(cairo_show_text)();
        bind!(cairo_show_glyphs)();
        bind!(cairo_show_text_glyphs)();
        bind!(cairo_text_path)();
        bind!(cairo_glyph_path)();
        bind!(cairo_text_extents)();
        bind!(cairo_glyph_extents)();
        bind!(cairo_font_extents)();
        bind!(cairo_font_face_reference)();
        bind!(cairo_font_face_destroy)();
        bind!(cairo_font_face_get_reference_count)();
        bind!(cairo_font_face_status)();
        bind!(cairo_font_face_get_type)();
        bind!(cairo_font_face_get_user_data)();
        bind!(cairo_font_face_set_user_data)();
        bind!(cairo_scaled_font_create)();
        bind!(cairo_scaled_font_reference)();
        bind!(cairo_scaled_font_destroy)();
        bind!(cairo_scaled_font_get_reference_count)();
        bind!(cairo_scaled_font_status)();
        bind!(cairo_scaled_font_get_type)();
        bind!(cairo_scaled_font_get_user_data)();
        bind!(cairo_scaled_font_set_user_data)();
        bind!(cairo_scaled_font_extents)();
        bind!(cairo_scaled_font_text_extents)();
        bind!(cairo_scaled_font_glyph_extents)();
        bind!(cairo_scaled_font_text_to_glyphs)();
        bind!(cairo_scaled_font_get_font_face)();
        bind!(cairo_scaled_font_get_font_matrix)();
        bind!(cairo_scaled_font_get_ctm)();
        bind!(cairo_scaled_font_get_scale_matrix)();
        bind!(cairo_scaled_font_get_font_options)();
        bind!(cairo_toy_font_face_create)();
        bind!(cairo_toy_font_face_get_family)();
        bind!(cairo_toy_font_face_get_slant)();
        bind!(cairo_toy_font_face_get_weight)();
        bind!(cairo_user_font_face_create)();
        bind!(cairo_user_font_face_set_init_func)();
        bind!(cairo_user_font_face_set_render_glyph_func)();
        bind!(cairo_user_font_face_set_text_to_glyphs_func)();
        bind!(cairo_user_font_face_set_unicode_to_glyph_func)();
        bind!(cairo_user_font_face_get_init_func)();
        bind!(cairo_user_font_face_get_render_glyph_func)();
        bind!(cairo_user_font_face_get_text_to_glyphs_func)();
        bind!(cairo_user_font_face_get_unicode_to_glyph_func)();

        bind!(cairo_device_reference)();
        bind!(cairo_device_get_type)();
        bind!(cairo_device_status)();
        bind!(cairo_device_acquire)();
        bind!(cairo_device_release)();
        bind!(cairo_device_flush)();
        bind!(cairo_device_finish)();
        bind!(cairo_device_destroy)();
        bind!(cairo_device_get_reference_count)();
        bind!(cairo_device_get_user_data)();
        bind!(cairo_device_set_user_data)();
        bind!(cairo_device_observer_print)();
        bind!(cairo_device_observer_elapsed)();
        bind!(cairo_device_observer_paint_elapsed)();
        bind!(cairo_device_observer_mask_elapsed)();
        bind!(cairo_device_observer_fill_elapsed)();
        bind!(cairo_device_observer_stroke_elapsed)();
        bind!(cairo_device_observer_glyphs_elapsed)();

        bind!(cairo_surface_reference)();
        bind!(cairo_surface_finish)();
        bind!(cairo_surface_destroy)();
        bind!(cairo_surface_get_device)();
        bind!(cairo_surface_get_reference_count)();
        bind!(cairo_surface_status)();
        bind!(cairo_surface_get_type)();
        bind!(cairo_surface_get_content)();
        bind!(cairo_surface_get_user_data)();
        bind!(cairo_surface_set_user_data)();
        bind!(cairo_surface_get_mime_data)();
        bind!(cairo_surface_set_mime_data)();
        bind!(cairo_surface_supports_mime_type)();
        bind!(cairo_surface_get_font_options)();
        bind!(cairo_surface_flush)();
        bind!(cairo_surface_mark_dirty)();
        bind!(cairo_surface_mark_dirty_rectangle)();
        bind!(cairo_surface_set_device_scale)();
        bind!(cairo_surface_get_device_scale)();
        bind!(cairo_surface_set_device_offset)();
        bind!(cairo_surface_get_device_offset)();
        bind!(cairo_surface_set_fallback_resolution)();
        bind!(cairo_surface_get_fallback_resolution)();
        bind!(cairo_surface_copy_page)();
        bind!(cairo_surface_show_page)();
        bind!(cairo_surface_has_show_text_glyphs)();
        bind!(cairo_surface_create_similar)();
        bind!(cairo_surface_create_similar_image)();
        bind!(cairo_surface_map_to_image)();
        bind!(cairo_surface_unmap_image)();
        bind!(cairo_surface_create_for_rectangle)();
        bind!(cairo_surface_create_observer)();
        bind!(cairo_surface_observer_add_paint_callback)();
        bind!(cairo_surface_observer_add_mask_callback)();
        bind!(cairo_surface_observer_add_fill_callback)();
        bind!(cairo_surface_observer_add_stroke_callback)();
        bind!(cairo_surface_observer_add_glyphs_callback)();
        bind!(cairo_surface_observer_add_flush_callback)();
        bind!(cairo_surface_observer_add_finish_callback)();
        bind!(cairo_surface_observer_print)();
        bind!(cairo_surface_observer_elapsed)();

        bind!(cairo_image_surface_create)();
        bind!(cairo_format_stride_for_width)();
        bind!(cairo_image_surface_create_for_data)();
        bind!(cairo_image_surface_get_data)();
        bind!(cairo_image_surface_get_format)();
        bind!(cairo_image_surface_get_width)();
        bind!(cairo_image_surface_get_height)();
        bind!(cairo_image_surface_get_stride)();

        bind!(cairo_recording_surface_create)();
        bind!(cairo_recording_surface_ink_extents)();
        bind!(cairo_recording_surface_get_extents)();

        bind!(cairo_pattern_create_raster_source)();
        bind!(cairo_raster_source_pattern_set_callback_data)();
        bind!(cairo_raster_source_pattern_get_callback_data)();
        bind!(cairo_raster_source_pattern_set_acquire)();
        bind!(cairo_raster_source_pattern_get_acquire)();
        bind!(cairo_raster_source_pattern_set_snapshot)();
        bind!(cairo_raster_source_pattern_get_snapshot)();
        bind!(cairo_raster_source_pattern_set_copy)();
        bind!(cairo_raster_source_pattern_get_copy)();
        bind!(cairo_raster_source_pattern_set_finish)();
        bind!(cairo_raster_source_pattern_get_finish)();


        bind!(cairo_pattern_create_rgb)();
        bind!(cairo_pattern_create_rgba)();
        bind!(cairo_pattern_create_for_surface)();
        bind!(cairo_pattern_create_linear)();
        bind!(cairo_pattern_create_radial)();
        bind!(cairo_pattern_create_mesh)();
        bind!(cairo_pattern_reference)();
        bind!(cairo_pattern_destroy)();
        bind!(cairo_pattern_get_reference_count)();
        bind!(cairo_pattern_status)();
        bind!(cairo_pattern_get_user_data)();
        bind!(cairo_pattern_set_user_data)();
        bind!(cairo_pattern_get_type)();
        bind!(cairo_pattern_add_color_stop_rgb)();
        bind!(cairo_pattern_add_color_stop_rgba)();
        bind!(cairo_mesh_pattern_begin_patch)();
        bind!(cairo_mesh_pattern_end_patch)();
        bind!(cairo_mesh_pattern_curve_to)();
        bind!(cairo_mesh_pattern_line_to)();
        bind!(cairo_mesh_pattern_move_to)();
        bind!(cairo_mesh_pattern_set_control_point)();
        bind!(cairo_mesh_pattern_set_corner_color_rgb)();
        bind!(cairo_mesh_pattern_set_corner_color_rgba)();
        bind!(cairo_pattern_set_matrix)();
        bind!(cairo_pattern_get_matrix)();
        bind!(cairo_pattern_set_extend)();
        bind!(cairo_pattern_get_extend)();
        bind!(cairo_pattern_set_filter)();
        bind!(cairo_pattern_get_filter)();
        bind!(cairo_pattern_get_rgba)();
        bind!(cairo_pattern_get_surface)();
        bind!(cairo_pattern_get_color_stop_rgba)();
        bind!(cairo_pattern_get_color_stop_count)();
        bind!(cairo_pattern_get_linear_points)();
        bind!(cairo_pattern_get_radial_circles)();
        bind!(cairo_mesh_pattern_get_patch_count)();
        bind!(cairo_mesh_pattern_get_path)();
        bind!(cairo_mesh_pattern_get_corner_color_rgba)();
        bind!(cairo_mesh_pattern_get_control_point)();


        bind!(cairo_matrix_init)();
        bind!(cairo_matrix_init_identity)();
        bind!(cairo_matrix_init_translate)();
        bind!(cairo_matrix_init_scale)();
        bind!(cairo_matrix_init_rotate)();
        bind!(cairo_matrix_translate)();
        bind!(cairo_matrix_scale)();
        bind!(cairo_matrix_rotate)();
        bind!(cairo_matrix_invert)();
        bind!(cairo_matrix_multiply)();
        bind!(cairo_matrix_transform_distance)();
        bind!(cairo_matrix_transform_point)();


        bind!(cairo_region_create)();
        bind!(cairo_region_create_rectangle)();
        bind!(cairo_region_create_rectangles)();
        bind!(cairo_region_copy)();
        bind!(cairo_region_reference)();
        bind!(cairo_region_destroy)();
        bind!(cairo_region_equal)();
        bind!(cairo_region_status)();
        bind!(cairo_region_get_extents)();
        bind!(cairo_region_num_rectangles)();
        bind!(cairo_region_get_rectangle)();
        bind!(cairo_region_is_empty)();
        bind!(cairo_region_contains_rectangle)();
        bind!(cairo_region_contains_point)();
        bind!(cairo_region_translate)();
        bind!(cairo_region_subtract)();
        bind!(cairo_region_subtract_rectangle)();
        bind!(cairo_region_intersect)();
        bind!(cairo_region_intersect_rectangle)();
        bind!(cairo_region_union)();
        bind!(cairo_region_union_rectangle)();
        bind!(cairo_region_xor)();
        bind!(cairo_region_xor_rectangle)();

        bind!(cairo_surface_write_to_png)(Yes.optional);
        bind!(cairo_surface_write_to_png_stream)(Yes.optional);
        bind!(cairo_image_surface_create_from_png)(Yes.optional);
        bind!(cairo_image_surface_create_from_png_stream)(Yes.optional);


        version(linux)
        {
            bind!(cairo_xcb_surface_create)();
            bind!(cairo_xcb_surface_create_for_bitmap)();
            bind!(cairo_xcb_surface_create_with_xrender_format)();
            bind!(cairo_xcb_surface_set_size)();
            bind!(cairo_xcb_surface_set_drawable)();
            bind!(cairo_xcb_device_get_connection)();
            bind!(cairo_xcb_device_debug_cap_xshm_version)();
            bind!(cairo_xcb_device_debug_cap_xrender_version)();
            bind!(cairo_xcb_device_debug_set_precision)();
        }
        else version(Windows)
        {
            bind!(cairo_win32_surface_create)();
            bind!(cairo_win32_printing_surface_create)();
            bind!(cairo_win32_surface_create_with_ddb)();
            bind!(cairo_win32_surface_create_with_dib)();
            bind!(cairo_win32_surface_get_dc)();
            bind!(cairo_win32_surface_get_image)();
            bind!(cairo_win32_font_face_create_for_logfontw)(Yes.optional);
            bind!(cairo_win32_font_face_create_for_hfont)(Yes.optional);
            bind!(cairo_win32_font_face_create_for_logfontw_hfont)(Yes.optional);
            bind!(cairo_win32_scaled_font_select_font)(Yes.optional);
            bind!(cairo_win32_scaled_font_done_font)(Yes.optional);
            bind!(cairo_win32_scaled_font_get_metrics_factor)(Yes.optional);
            bind!(cairo_win32_scaled_font_get_logical_to_device)(Yes.optional);
            bind!(cairo_win32_scaled_font_get_device_to_logical)(Yes.optional);
        }
    }
}



alias CairoSurfaceSymbols = AliasSeq!(

);

alias CairoImageSymbols = AliasSeq!(

);

alias CairoRecordingSymbols = AliasSeq!(

);

alias CairoRasterSourceSymbols = AliasSeq!(

);

alias CairoPatternSymbols = AliasSeq!(
);

alias CairoMatrixSymbols = AliasSeq!(
);

alias CairoRegionSymbols = AliasSeq!(
);

alias CairoDebugSymbols = AliasSeq!(
);

alias CairoPngSymbols = AliasSeq!(
);



