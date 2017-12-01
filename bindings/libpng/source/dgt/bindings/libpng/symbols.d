module dgt.bindings.libpng.symbols;

import dgt.bindings.libpng.pnglibconf;
import dgt.bindings.libpng.pngconf;
import dgt.bindings.libpng.definitions;

import core.stdc.stdio : FILE;
import core.stdc.time : tm, time_t;

@property auto png_libpng_ver()
{
    return png_get_header_ver(null);
}

auto png_check_sig(S, N)(S sig, N n)
{
    return !png_sig_cmp((sig), 0, (n));
}

extern (C) nothrow @nogc
{
    alias da_png_access_version_number = uint function();
    alias da_png_set_sig_bytes = void function(png_structrp png_ptr, int num_bytes);
    alias da_png_sig_cmp = int function(png_const_bytep sig, size_t start, size_t num_to_check);
    alias da_png_create_read_struct = png_structp function(png_const_charp user_png_ver,
            png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warn_fn);
    alias da_png_create_write_struct = png_structp function(png_const_charp user_png_ver,
            png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warn_fn);
    alias da_png_get_compression_buffer_size = size_t function(png_const_structrp png_ptr);
    alias da_png_set_compression_buffer_size = void function(png_structrp png_ptr, size_t size);
    alias da_png_longjmp = void function(png_const_structrp png_ptr, int val);
    static if (PNG_USER_MEM_SUPPORTED)
    {
        alias da_png_create_read_struct_2 = png_structp function(png_const_charp user_png_ver,
                png_voidp error_ptr, png_error_ptr error_fn,
                png_error_ptr warn_fn, png_voidp mem_ptr,
                png_malloc_ptr malloc_fn, png_free_ptr free_fn);
        alias da_png_create_write_struct_2 = png_structp function(png_const_charp user_png_ver,
                png_voidp error_ptr, png_error_ptr error_fn,
                png_error_ptr warn_fn, png_voidp mem_ptr,
                png_malloc_ptr malloc_fn, png_free_ptr free_fn);
    }
    alias da_png_write_sig = void function(png_structrp png_ptr);
    alias da_png_write_chunk = void function(png_structrp png_ptr,
            png_const_bytep chunk_name, png_const_bytep data, size_t length);
    alias da_png_write_chunk_start = void function(png_structrp png_ptr,
            png_const_bytep chunk_name, uint length);
    alias da_png_write_chunk_data = void function(png_structrp png_ptr,
            png_const_bytep data, size_t length);
    alias da_png_write_chunk_end = void function(png_structrp png_ptr);
    alias da_png_create_info_struct = png_infop function(png_const_structrp png_ptr);
    alias da_png_write_info_before_PLTE = void function(png_structrp png_ptr,
            png_const_inforp info_ptr);
    alias da_png_write_info = void function(png_structrp png_ptr, png_const_inforp info_ptr);
    static if (PNG_SEQUENTIAL_READ_SUPPORTED)
    {
        alias da_png_read_info = void function(png_structrp png_ptr, png_inforp info_ptr);
    }
    static if (PNG_TIME_RFC1123_SUPPORTED)
    {
        alias da_png_convert_to_rfc1123_buffer = int function(char[29] out_, png_const_timep ptime);
    }
    static if (PNG_CONVERT_tIME_SUPPORTED)
    {
        alias da_png_convert_from_struct_tm = void function(png_timep ptime, const(tm)* ttime);
        alias da_png_convert_from_time_t = void function(png_timep ptime, time_t ttime);
    }
    static if (PNG_READ_EXPAND_SUPPORTED)
    {
        alias da_png_set_expand = void function(png_structrp png_ptr);
        alias da_png_set_expand_gray_1_2_4_to_8 = void function(png_structrp png_ptr);
        alias da_png_set_palette_to_rgb = void function(png_structrp png_ptr);
        alias da_png_set_tRNS_to_alpha = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_EXPAND_16_SUPPORTED)
    {
        alias da_png_set_expand_16 = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_BGR_SUPPORTED || PNG_WRITE_BGR_SUPPORTED)
    {
        alias da_png_set_bgr = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_GRAY_TO_RGB_SUPPORTED)
    {
        alias da_png_set_gray_to_rgb = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_RGB_TO_GRAY_SUPPORTED)
    {
        alias da_png_set_rgb_to_gray = void function(png_structrp png_ptr,
                int error_action, double red, double green);
        alias da_png_set_rgb_to_gray_fixed = void function(png_structrp png_ptr,
                int error_action, png_fixed_point red, png_fixed_point green);
        alias da_png_get_rgb_to_gray_status = png_byte function(png_const_structrp png_ptr);
    }
    static if (PNG_BUILD_GRAYSCALE_PALETTE_SUPPORTED)
    {
        alias da_png_build_grayscale_palette = void function(int bit_depth, png_colorp palette);
    }
    static if (PNG_READ_ALPHA_MODE_SUPPORTED)
    {
        alias da_png_set_alpha_mode = void function(png_structrp png_ptr,
                int mode, double output_gamma);
        alias da_png_set_alpha_mode_fixed = void function(png_structrp png_ptr,
                int mode, png_fixed_point output_gamma);
    }
    static if (PNG_READ_STRIP_ALPHA_SUPPORTED)
    {
        alias da_png_set_strip_alpha = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_SWAP_ALPHA_SUPPORTED || PNG_WRITE_SWAP_ALPHA_SUPPORTED)
    {
        alias da_png_set_swap_alpha = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_INVERT_ALPHA_SUPPORTED || PNG_WRITE_INVERT_ALPHA_SUPPORTED)
    {
        alias da_png_set_invert_alpha = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_FILLER_SUPPORTED || PNG_WRITE_FILLER_SUPPORTED)
    {
        alias da_png_set_filler = void function(png_structrp png_ptr, uint filler, int flags);
        alias da_png_set_add_alpha = void function(png_structrp png_ptr, uint filler, int flags);
    }
    static if (PNG_READ_SWAP_SUPPORTED || PNG_WRITE_SWAP_SUPPORTED)
    {
        alias da_png_set_swap = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_PACK_SUPPORTED || PNG_WRITE_PACK_SUPPORTED)
    {
        alias da_png_set_packing = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_PACKSWAP_SUPPORTED || PNG_WRITE_PACKSWAP_SUPPORTED)
    {
        alias da_png_set_packswap = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_SHIFT_SUPPORTED || PNG_WRITE_SHIFT_SUPPORTED)
    {
        alias da_png_set_shift = void function(png_structrp png_ptr, png_const_color_8p true_bits);
    }
    static if (PNG_READ_INTERLACING_SUPPORTED || PNG_WRITE_INTERLACING_SUPPORTED)
    {
        alias da_png_set_interlace_handling = int function(png_structrp png_ptr);
    }
    static if (PNG_READ_INVERT_SUPPORTED || PNG_WRITE_INVERT_SUPPORTED)
    {
        alias da_png_set_invert_mono = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_BACKGROUND_SUPPORTED)
    {
        alias da_png_set_background = void function(png_structrp png_ptr, png_const_color_16p background_color,
                int background_gamma_code, int need_expand, double background_gamma);
        alias da_png_set_background_fixed = void function(png_structrp png_ptr, png_const_color_16p background_color,
                int background_gamma_code, int need_expand, png_fixed_point background_gamma);
    }
    static if (PNG_READ_SCALE_16_TO_8_SUPPORTED)
    {
        alias da_png_set_scale_16 = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_STRIP_16_TO_8_SUPPORTED)
    {
        alias da_png_set_strip_16 = void function(png_structrp png_ptr);
    }
    static if (PNG_READ_QUANTIZE_SUPPORTED)
    {
        alias da_png_set_quantize = void function(png_structrp png_ptr, png_colorp palette,
                int num_palette, int maximum_colors, png_const_uint_16p histogram, int full_quantize);
    }
    static if (PNG_READ_GAMMA_SUPPORTED)
    {
        alias da_png_set_gamma = void function(png_structrp png_ptr,
                double screen_gamma, double override_file_gamma);
        alias da_png_set_gamma_fixed = void function(png_structrp png_ptr,
                png_fixed_point screen_gamma, png_fixed_point override_file_gamma);
    }
    static if (PNG_WRITE_FLUSH_SUPPORTED)
    {
        alias da_png_set_flush = void function(png_structrp png_ptr, int nrows);
        alias da_png_write_flush = void function(png_structrp png_ptr);
    }
    alias da_png_start_read_image = void function(png_structrp png_ptr);
    alias da_png_read_update_info = void function(png_structrp png_ptr, png_inforp info_ptr);
    static if (PNG_SEQUENTIAL_READ_SUPPORTED)
    {
        alias da_png_read_rows = void function(png_structrp png_ptr,
                png_bytepp row, png_bytepp display_row, uint num_rows);
    }
    static if (PNG_SEQUENTIAL_READ_SUPPORTED)
    {
        alias da_png_read_row = void function(png_structrp png_ptr,
                png_bytep row, png_bytep display_row);
    }
    static if (PNG_SEQUENTIAL_READ_SUPPORTED)
    {
        alias da_png_read_image = void function(png_structrp png_ptr, png_bytepp image);
    }
    alias da_png_write_row = void function(png_structrp png_ptr, png_const_bytep row);
    alias da_png_write_rows = void function(png_structrp png_ptr, in png_bytepp row, uint num_rows);
    alias da_png_write_image = void function(png_structrp png_ptr, in png_bytepp image);
    alias da_png_write_end = void function(png_structrp png_ptr, png_inforp info_ptr);
    static if (PNG_SEQUENTIAL_READ_SUPPORTED)
    {
        alias da_png_read_end = void function(png_structrp png_ptr, png_inforp info_ptr);
    }
    alias da_png_destroy_info_struct = void function(png_const_structrp png_ptr,
            png_infopp info_ptr_ptr);
    alias da_png_destroy_read_struct = void function(png_structpp png_ptr_ptr,
            png_infopp info_ptr_ptr, png_infopp end_info_ptr_ptr);
    alias da_png_destroy_write_struct = void function(png_structrp png_ptr_ptr,
            png_infopp info_ptr_ptr);
    alias da_png_set_crc_action = void function(png_structrp png_ptr,
            int crit_action, int ancil_action);
    alias da_png_set_filter = void function(png_structrp png_ptr, int method, int filters);
    static if (PNG_WRITE_WEIGHTED_FILTER_SUPPORTED)
    {
        alias da_png_set_filter_heuristics = void function(png_structrp png_ptr, int heuristic_method,
                int num_weights, png_const_doublep filter_weights, png_const_doublep filter_costs);
        alias da_png_set_filter_heuristics_fixed = void function(png_structrp png_ptr,
                int heuristic_method, int num_weights,
                png_const_fixed_point_p filter_weights, png_const_fixed_point_p filter_costs);
    }
    static if (PNG_WRITE_SUPPORTED)
    {
        alias da_png_set_compression_level = void function(png_structrp png_ptr, int level);
        alias da_png_set_compression_mem_level = void function(png_structrp png_ptr, int mem_level);
        alias da_png_set_compression_strategy = void function(png_structrp png_ptr, int strategy);
        alias da_png_set_compression_window_bits = void function(png_structrp png_ptr,
                int window_bits);
        alias da_png_set_compression_method = void function(png_structrp png_ptr, int method);
    }
    static if (PNG_WRITE_CUSTOMIZE_ZTXT_COMPRESSION_SUPPORTED)
    {
        alias da_png_set_text_compression_level = void function(png_structrp png_ptr, int level);
        alias da_png_set_text_compression_mem_level = void function(png_structrp png_ptr,
                int mem_level);
        alias da_png_set_text_compression_strategy = void function(png_structrp png_ptr,
                int strategy);
        alias da_png_set_text_compression_window_bits = void function(png_structrp png_ptr,
                int window_bits);
        alias da_png_set_text_compression_method = void function(png_structrp png_ptr, int method);
    }
    static if (PNG_STDIO_SUPPORTED)
    {
        alias da_png_init_io = void function(png_structrp png_ptr, png_FILE_p fp);
    }
    alias da_png_set_error_fn = void function(png_structrp png_ptr,
            png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warning_fn);
    alias da_png_get_error_ptr = png_voidp function(png_const_structrp png_ptr);
    alias da_png_set_write_fn = void function(png_structrp png_ptr,
            png_voidp io_ptr, png_rw_ptr write_data_fn, png_flush_ptr output_flush_fn);
    alias da_png_set_read_fn = void function(png_structrp png_ptr,
            png_voidp io_ptr, png_rw_ptr read_data_fn);
    alias da_png_get_io_ptr = png_voidp function(png_const_structrp png_ptr);
    alias da_png_set_read_status_fn = void function(png_structrp png_ptr,
            png_read_status_ptr read_row_fn);
    alias da_png_set_write_status_fn = void function(png_structrp png_ptr,
            png_write_status_ptr write_row_fn);
    static if (PNG_USER_MEM_SUPPORTED)
    {
        alias da_png_set_mem_fn = void function(png_structrp png_ptr,
                png_voidp mem_ptr, png_malloc_ptr malloc_fn, png_free_ptr free_fn);
        alias da_png_get_mem_ptr = png_voidp function(png_const_structrp png_ptr);
    }
    static if (PNG_READ_USER_TRANSFORM_SUPPORTED)
    {
        alias da_png_set_read_user_transform_fn = void function(png_structrp png_ptr,
                png_user_transform_ptr read_user_transform_fn);
    }
    static if (PNG_WRITE_USER_TRANSFORM_SUPPORTED)
    {
        alias da_png_set_write_user_transform_fn = void function(png_structrp png_ptr,
                png_user_transform_ptr write_user_transform_fn);
    }
    static if (PNG_USER_TRANSFORM_PTR_SUPPORTED)
    {
        alias da_png_set_user_transform_info = void function(png_structrp png_ptr,
                png_voidp user_transform_ptr, int user_transform_depth, int user_transform_channels);
        alias da_png_get_user_transform_ptr = png_voidp function(png_const_structrp png_ptr);
    }
    static if (PNG_USER_TRANSFORM_INFO_SUPPORTED)
    {
        alias da_png_get_current_row_number = uint function(png_const_structrp);
        alias da_png_get_current_pass_number = png_byte function(png_const_structrp);
    }
    static if (PNG_READ_USER_CHUNKS_SUPPORTED)
    {
        alias da_png_set_read_user_chunk_fn = void function(png_structrp png_ptr,
                png_voidp user_chunk_ptr, png_user_chunk_ptr read_user_chunk_fn);
    }
    static if (PNG_USER_CHUNKS_SUPPORTED)
    {
        alias da_png_get_user_chunk_ptr = png_voidp function(png_const_structrp png_ptr);
    }
    static if (PNG_PROGRESSIVE_READ_SUPPORTED)
    {
        alias da_png_set_progressive_read_fn = void function(png_structrp png_ptr, png_voidp progressive_ptr,
                png_progressive_info_ptr info_fn,
                png_progressive_row_ptr row_fn, png_progressive_end_ptr end_fn);
        alias da_png_get_progressive_ptr = png_voidp function(png_const_structrp png_ptr);
        alias da_png_process_data = void function(png_structrp png_ptr,
                png_inforp info_ptr, png_bytep buffer, size_t buffer_size);
        alias da_png_process_data_pause = size_t function(png_structrp, int save);
        alias da_png_process_data_skip = uint function(png_structrp);
        alias da_png_progressive_combine_row = void function(png_const_structrp png_ptr,
                png_bytep old_row, png_const_bytep new_row);
    }
    alias da_png_malloc = png_voidp function(png_const_structrp png_ptr, png_alloc_size_t size);
    alias da_png_calloc = png_voidp function(png_const_structrp png_ptr, png_alloc_size_t size);
    alias da_png_malloc_warn = png_voidp function(png_const_structrp png_ptr, png_alloc_size_t size);
    alias da_png_free = void function(png_const_structrp png_ptr, png_voidp ptr);
    alias da_png_free_data = void function(png_const_structrp png_ptr,
            png_inforp info_ptr, uint free_me, int num);
    alias da_png_data_freer = void function(png_const_structrp png_ptr,
            png_inforp info_ptr, int freer, uint mask);
    static if (PNG_ERROR_TEXT_SUPPORTED)
    {
        alias da_png_error = void function(png_const_structrp png_ptr, png_const_charp error_message);
        alias da_png_chunk_error = void function(png_const_structrp png_ptr,
                png_const_charp error_mes);
    }
    else
    {
        alias da_png_err = void function(png_const_structrp png);
    }
    static if (PNG_WARNINGS_SUPPORTED)
    {
        alias da_png_warning = void function(png_const_structrp png_ptr,
                png_const_charp warning_message);
        alias da_png_chunk_warning = void function(png_const_structrp png_ptr,
                png_const_charp warning_message);
    }
    static if (PNG_BENIGN_ERRORS_SUPPORTED)
    {
        alias da_png_benign_error = void function(png_const_structrp png_ptr,
                png_const_charp warning_message);
        static if (PNG_READ_SUPPORTED)
        {
            alias da_png_chunk_benign_error = void function(png_const_structrp png_ptr,
                    png_const_charp warning_message);
        }
        alias da_png_set_benign_errors = void function(png_structrp png_ptr, int allowed);
    }
    alias da_png_get_valid = uint function(png_const_structrp png_ptr,
            png_const_inforp info_ptr, uint flag);
    alias da_png_get_rowbytes = size_t function(png_const_structrp png_ptr,
            png_const_inforp info_ptr);
    static if (PNG_INFO_IMAGE_SUPPORTED)
    {
        alias da_png_get_rows = png_bytepp function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_set_rows = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_bytepp row_pointers);
    }
    alias da_png_get_channels = png_byte function(png_const_structrp png_ptr,
            png_const_inforp info_ptr);
    static if (PNG_EASY_ACCESS_SUPPORTED)
    {
        alias da_png_get_image_width = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_image_height = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_bit_depth = png_byte function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_color_type = png_byte function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_filter_type = png_byte function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_interlace_type = png_byte function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_compression_type = png_byte function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_pixels_per_meter = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_x_pixels_per_meter = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_y_pixels_per_meter = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_pixel_aspect_ratio = float function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_pixel_aspect_ratio_fixed = png_fixed_point function(
                png_const_structrp png_ptr, png_const_inforp info_ptr);
        alias da_png_get_x_offset_pixels = png_int_32 function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_y_offset_pixels = png_int_32 function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_x_offset_microns = png_int_32 function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_y_offset_microns = png_int_32 function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
    }
    static if (PNG_READ_SUPPORTED)
    {
        alias da_png_get_signature = png_const_bytep function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
    }
    static if (PNG_bKGD_SUPPORTED)
    {
        alias da_png_get_bKGD = uint function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_color_16p* background);
    }
    static if (PNG_bKGD_SUPPORTED)
    {
        alias da_png_set_bKGD = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_const_color_16p background);
    }
    static if (PNG_cHRM_SUPPORTED)
    {
        alias da_png_get_cHRM = png_uint_32 function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, double* white_x,
                double* white_y, double* red_x, double* red_y, double* green_x,
                double* green_y, double* blue_x, double* blue_y);
        alias da_png_get_cHRM_XYZ = png_uint_32 function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, double* red_X,
                double* red_Y, double* red_Z, double* green_X, double* green_Y,
                double* green_Z, double* blue_X, double* blue_Y, double* blue_Z);
        static if (PNG_FIXED_POINT_SUPPORTED)
        {
            alias da_png_get_cHRM_fixed = uint function(png_const_structrp png_ptr,
                    png_const_inforp info_ptr, png_fixed_point* int_white_x,
                    png_fixed_point* int_white_y,
                    png_fixed_point* int_red_x,
                    png_fixed_point* int_red_y, png_fixed_point* int_green_x, png_fixed_point* int_green_y,
                    png_fixed_point* int_blue_x, png_fixed_point* int_blue_y);
        }
        alias da_png_get_cHRM_XYZ_fixed = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, png_fixed_point* int_red_X,
                png_fixed_point* int_red_Y,
                png_fixed_point* int_red_Z,
                png_fixed_point* int_green_X, png_fixed_point* int_green_Y, png_fixed_point* int_green_Z,
                png_fixed_point* int_blue_X, png_fixed_point* int_blue_Y,
                png_fixed_point* int_blue_Z);
    }
    static if (PNG_cHRM_SUPPORTED)
    {
        alias da_png_set_cHRM = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, double white_x, double white_y,
                double red_x, double red_y, double green_x, double green_y,
                double blue_x, double blue_y);
        alias da_png_set_cHRM_XYZ = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, double red_X, double red_Y,
                double red_Z, double green_X, double green_Y, double green_Z,
                double blue_X, double blue_Y, double blue_Z);
        alias da_png_set_cHRM_fixed = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_fixed_point int_white_x,
                png_fixed_point int_white_y, png_fixed_point int_red_x,
                png_fixed_point int_red_y, png_fixed_point int_green_x,
                png_fixed_point int_green_y, png_fixed_point int_blue_x, png_fixed_point int_blue_y);
        alias da_png_set_cHRM_XYZ_fixed = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_fixed_point int_red_X,
                png_fixed_point int_red_Y, png_fixed_point int_red_Z,
                png_fixed_point int_green_X,
                png_fixed_point int_green_Y, png_fixed_point int_green_Z,
                png_fixed_point int_blue_X, png_fixed_point int_blue_Y, png_fixed_point int_blue_Z);
    }
    static if (PNG_gAMA_SUPPORTED)
    {
        alias da_png_get_gAMA = png_uint_32 function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, double* file_gamma);
        alias da_png_get_gAMA_fixed = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, png_fixed_point* int_file_gamma);
    }
    static if (PNG_gAMA_SUPPORTED)
    {
        alias da_png_set_gAMA = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, double file_gamma);
        alias da_png_set_gAMA_fixed = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_fixed_point int_file_gamma);
    }
    static if (PNG_hIST_SUPPORTED)
    {
        alias da_png_get_hIST = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, png_uint_16p* hist);
    }
    static if (PNG_hIST_SUPPORTED)
    {
        alias da_png_set_hIST = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_const_uint_16p hist);
    }
    alias da_png_get_IHDR = uint function(png_const_structrp png_ptr,
            png_const_inforp info_ptr, uint* width, uint* height,
            int* bit_depth, int* color_type, int* interlace_method,
            int* compression_method, int* filter_method);
    alias da_png_set_IHDR = void function(png_const_structrp png_ptr,
            png_inforp info_ptr, uint width, uint height, int bit_depth,
            int color_type, int interlace_method, int compression_method, int filter_method);
    static if (PNG_oFFs_SUPPORTED)
    {
        alias da_png_get_oFFs = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, png_int_32* offset_x,
                png_int_32* offset_y, int* unit_type);
    }
    static if (PNG_oFFs_SUPPORTED)
    {
        alias da_png_set_oFFs = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_int_32 offset_x, png_int_32 offset_y, int unit_type);
    }
    static if (PNG_pCAL_SUPPORTED)
    {
        alias da_png_get_pCAL = uint function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_charp* purpose, png_int_32* X0,
                png_int_32* X1, int* type, int* nparams, png_charp* units, png_charpp* params);
    }
    static if (PNG_pCAL_SUPPORTED)
    {
        alias da_png_set_pCAL = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_const_charp purpose, png_int_32 X0,
                png_int_32 X1, int type, int nparams, png_const_charp units, png_charpp params);
    }
    static if (PNG_pHYs_SUPPORTED)
    {
        alias da_png_get_pHYs = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, uint* res_x, uint* res_y, int* unit_type);
    }
    static if (PNG_pHYs_SUPPORTED)
    {
        alias da_png_set_pHYs = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, uint res_x, uint res_y, int unit_type);
    }
    alias da_png_get_PLTE = uint function(png_const_structrp png_ptr,
            png_inforp info_ptr, png_colorp* palette, int* num_palette);
    alias da_png_set_PLTE = void function(png_structrp png_ptr,
            png_inforp info_ptr, png_const_colorp palette, int num_palette);
    static if (PNG_sBIT_SUPPORTED)
    {
        alias da_png_get_sBIT = uint function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_color_8p* sig_bit);
        alias da_png_set_sBIT = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_const_color_8p sig_bit);
    }
    static if (PNG_sRGB_SUPPORTED)
    {
        alias da_png_get_sRGB = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, int* file_srgb_intent);
        alias da_png_set_sRGB = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, int srgb_intent);
        alias da_png_set_sRGB_gAMA_and_cHRM = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, int srgb_intent);
    }
    static if (PNG_iCCP_SUPPORTED)
    {
        alias da_png_get_iCCP = uint function(png_const_structrp png_ptr, png_inforp info_ptr,
                png_charpp name, int* compression_type, png_bytepp profile, uint* proflen);
        alias da_png_set_iCCP = void function(png_const_structrp png_ptr, png_inforp info_ptr,
                png_const_charp name, int compression_type, png_const_bytep profile, uint proflen);
    }
    static if (PNG_sPLT_SUPPORTED)
    {
        alias da_png_get_sPLT = uint function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_sPLT_tpp entries);
        alias da_png_set_sPLT = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_const_sPLT_tp entries, int nentries);
    }
    static if (PNG_TEXT_SUPPORTED)
    {
        alias da_png_get_text = uint function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_textp* text_ptr, int* num_text);
        alias da_png_set_text = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_const_textp text_ptr, int num_text);
    }
    static if (PNG_tIME_SUPPORTED)
    {
        alias da_png_get_tIME = uint function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_timep* mod_time);
        alias da_png_set_tIME = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_const_timep mod_time);
    }
    static if (PNG_tRNS_SUPPORTED)
    {
        alias da_png_get_tRNS = uint function(png_const_structrp png_ptr, png_inforp info_ptr,
                png_bytep* trans_alpha, int* num_trans, png_color_16p* trans_color);
        alias da_png_set_tRNS = void function(png_structrp png_ptr, png_inforp info_ptr,
                png_const_bytep trans_alpha, int num_trans, png_const_color_16p trans_color);
    }
    static if (PNG_sCAL_SUPPORTED)
    {
        alias da_png_get_sCAL = png_uint_32 function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, int* unit, double* width, double* height);
        static if (PNG_FLOATING_ARITHMETIC_SUPPORTED || PNG_FLOATING_POINT_SUPPORTED)
        {
            alias da_png_get_sCAL_fixed = uint function(png_const_structrp png_ptr,
                    png_const_inforp info_ptr, int* unit,
                    png_fixed_point* width, png_fixed_point* height);
        }
        alias da_png_get_sCAL_s = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr, int* unit, png_charpp swidth, png_charpp sheight);
        alias da_png_set_sCAL = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, int unit, double width, double height);
        alias da_png_const_set_sCAL_fixed = void function(png_structrp png_ptr,
                png_inforp info_ptr, int unit, png_fixed_point width, png_fixed_point height);
        alias da_png_set_sCAL_s = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, int unit, png_const_charp swidth, png_const_charp sheight);
    }
    static if (PNG_SET_UNKNOWN_CHUNKS_SUPPORTED)
    {
        alias da_png_set_keep_unknown_chunks = void function(png_structrp png_ptr,
                int keep, png_const_bytep chunk_list, int num_chunks);
        alias da_png_handle_as_unknown = int function(png_const_structrp png_ptr,
                png_const_bytep chunk_name);
    }
    static if (PNG_STORE_UNKNOWN_CHUNKS_SUPPORTED)
    {
        alias da_png_set_unknown_chunks = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_const_unknown_chunkp unknowns, int num_unknowns);
        alias da_png_set_unknown_chunk_location = void function(png_const_structrp png_ptr,
                png_inforp info_ptr, int chunk, int location);
        alias da_png_get_unknown_chunks = int function(png_const_structrp png_ptr,
                png_inforp info_ptr, png_unknown_chunkpp entries);
    }
    alias da_png_set_invalid = void function(png_const_structrp png_ptr,
            png_inforp info_ptr, int mask);
    static if (PNG_INFO_IMAGE_SUPPORTED)
    {
        static if (PNG_SEQUENTIAL_READ_SUPPORTED)
        {
            alias da_png_read_png = void function(png_structrp png_ptr,
                    png_inforp info_ptr, int transforms, png_voidp params);
        }
        static if (PNG_WRITE_SUPPORTED)
        {
            alias da_png_write_png = void function(png_structrp png_ptr,
                    png_inforp info_ptr, int transforms, png_voidp params);
        }
    }
    alias da_png_get_copyright = png_const_charp function(png_const_structrp png_ptr);
    alias da_png_get_header_ver = png_const_charp function(png_const_structrp png_ptr);
    alias da_png_get_header_version = png_const_charp function(png_const_structrp png_ptr);
    alias da_png_get_libpng_ver = png_const_charp function(png_const_structrp png_ptr);
    static if (PNG_MNG_FEATURES_SUPPORTED)
    {
        alias da_png_permit_mng_features = uint function(png_structrp png_ptr,
                uint mng_features_permitted);
    }
    static if (PNG_SET_USER_LIMITS_SUPPORTED)
    {
        alias da_png_set_user_limits = void function(png_structrp png_ptr,
                uint user_width_max, uint user_height_max);
        alias da_png_get_user_width_max = uint function(png_const_structrp png_ptr);
        alias da_png_get_user_height_max = uint function(png_const_structrp png_ptr);
        alias da_png_set_chunk_cache_max = void function(png_structrp png_ptr,
                uint user_chunk_cache_max);
        alias da_png_get_chunk_cache_max = uint function(png_const_structrp png_ptr);
        alias da_png_set_chunk_malloc_max = void function(png_structrp png_ptr,
                png_alloc_size_t user_chunk_cache_max);
        alias da_png_get_chunk_malloc_max = png_alloc_size_t function(png_const_structrp png_ptr);
    }
    static if (PNG_INCH_CONVERSIONS_SUPPORTED)
    {
        alias da_png_get_pixels_per_inch = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_x_pixels_per_inch = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_y_pixels_per_inch = uint function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        alias da_png_get_x_offset_inches = float function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        static if (PNG_FIXED_POINT_SUPPORTED)
        {
            alias da_png_get_x_offset_inches_fixed = png_fixed_point function(
                    png_const_structrp png_ptr, png_const_inforp info_ptr);
        }
        alias da_png_get_y_offset_inches = float function(png_const_structrp png_ptr,
                png_const_inforp info_ptr);
        static if (PNG_FIXED_POINT_SUPPORTED)
        {
            alias da_png_get_y_offset_inches_fixed = png_fixed_point function(
                    png_const_structrp png_ptr, png_const_inforp info_ptr);
        }
        static if (PNG_pHYs_SUPPORTED)
        {
            alias da_png_get_pHYs_dpi = uint function(png_const_structrp png_ptr,
                    png_const_inforp info_ptr, uint* res_x, uint* res_y, int* unit_type);
        }
    }
    static if (PNG_IO_STATE_SUPPORTED)
    {
        alias da_png_get_io_state = uint function(png_const_structrp png_ptr);
        alias da_png_get_io_chunk_type = uint function(png_const_structrp png_ptr);
    }
    static if (PNG_READ_INT_FUNCTIONS_SUPPORTED)
    {
        alias da_png_get_uint_32 = png_uint_32 function(png_const_bytep buf);
        alias da_png_get_uint_16 = png_uint_16 function(png_const_bytep buf);
        alias da_png_get_int_32 = png_int_32 function(png_const_bytep buf);
    }
    alias da_png_get_uint_31 = uint function(png_const_structrp png_ptr, png_const_bytep buf);
    static if (PNG_WRITE_INT_FUNCTIONS_SUPPORTED)
    {
        alias da_png_save_uint_32 = void function(png_bytep buf, uint i);
    }
    static if (PNG_SAVE_INT_32_SUPPORTED)
    {
        alias da_png_save_int_32 = void function(png_bytep buf, png_int_32 i);
    }
    static if (PNG_WRITE_INT_FUNCTIONS_SUPPORTED)
    {
        alias da_png_save_uint_16 = void function(png_bytep buf, uint i);
    }
    static if (PNG_SIMPLIFIED_READ_SUPPORTED)
    {
        static if (PNG_STDIO_SUPPORTED)
        {
            alias da_png_image_begin_read_from_file = int function(png_imagep image,
                    const char* file_name);
            alias da_png_image_begin_read_from_stdio = int function(png_imagep image, FILE* file);
        }
        alias da_png_image_begin_read_from_memory = int function(png_imagep image,
                png_const_voidp memory, png_size_t size);
        alias da_png_image_finish_read = int function(png_imagep image,
                png_const_colorp background, void* buffer, png_int_32 row_stride, void* colormap);
        alias da_png_image_free = void function(png_imagep image);
    }
    static if (PNG_SIMPLIFIED_WRITE_SUPPORTED)
    {
        static if (PNG_STDIO_SUPPORTED)
        {
            alias da_png_image_write_to_file = int function(png_imagep image, const char* file,
                    int convert_to_8bit, const void* buffer,
                    png_int_32 row_stride, const void* colormap);
            alias da_png_image_write_to_stdio = int function(png_imagep image, FILE* file,
                    int convert_to_8_bit, const void* buffer,
                    png_int_32 row_stride, const void* colormap);
        }
    }
    static if (PNG_CHECK_FOR_INVALID_INDEX_SUPPORTED)
    {
        alias da_png_set_check_for_invalid_index = void function(png_structp png_ptr, int allowed);
        static if (PNG_GET_PALETTE_MAX_SUPPORTED)
        {
            alias da_png_get_palette_max = int function(png_const_structrp png_ptr,
                    png_const_infop info_ptr);
        }
    }
    static if (PNG_SET_OPTION_SUPPORTED)
    {
        alias da_png_set_option = int function(png_structrp png_ptr, int option, int onoff);
    }
}

__gshared
{
    da_png_access_version_number png_access_version_number;
    da_png_set_sig_bytes png_set_sig_bytes;
    da_png_sig_cmp png_sig_cmp;
    da_png_create_read_struct png_create_read_struct;
    da_png_create_write_struct png_create_write_struct;
    da_png_get_compression_buffer_size png_get_compression_buffer_size;
    da_png_set_compression_buffer_size png_set_compression_buffer_size;
    da_png_longjmp png_longjmp;
    static if (PNG_USER_MEM_SUPPORTED)
    {
        da_png_create_read_struct_2 png_create_read_struct_2;
        da_png_create_write_struct_2 png_create_write_struct_2;
    }
    da_png_write_sig png_write_sig;
    da_png_write_chunk png_write_chunk;
    da_png_write_chunk_start png_write_chunk_start;
    da_png_write_chunk_data png_write_chunk_data;
    da_png_write_chunk_end png_write_chunk_end;
    da_png_create_info_struct png_create_info_struct;
    da_png_write_info_before_PLTE png_write_info_before_PLTE;
    da_png_write_info png_write_info;
    static if (PNG_SEQUENTIAL_READ_SUPPORTED)
    {
        da_png_read_info png_read_info;
    }
    static if (PNG_TIME_RFC1123_SUPPORTED)
    {
        da_png_convert_to_rfc1123_buffer png_convert_to_rfc1123_buffer;
    }
    static if (PNG_CONVERT_tIME_SUPPORTED)
    {
        da_png_convert_from_struct_tm png_convert_from_struct_tm;
        da_png_convert_from_time_t png_convert_from_time_t;
    }
    static if (PNG_READ_EXPAND_SUPPORTED)
    {
        da_png_set_expand png_set_expand;
        da_png_set_expand_gray_1_2_4_to_8 png_set_expand_gray_1_2_4_to_8;
        da_png_set_palette_to_rgb png_set_palette_to_rgb;
        da_png_set_tRNS_to_alpha png_set_tRNS_to_alpha;
    }
    static if (PNG_READ_EXPAND_16_SUPPORTED)
    {
        da_png_set_expand_16 png_set_expand_16;
    }
    static if (PNG_READ_BGR_SUPPORTED || PNG_WRITE_BGR_SUPPORTED)
    {
        da_png_set_bgr png_set_bgr;
    }
    static if (PNG_READ_GRAY_TO_RGB_SUPPORTED)
    {
        da_png_set_gray_to_rgb png_set_gray_to_rgb;
    }
    static if (PNG_READ_RGB_TO_GRAY_SUPPORTED)
    {
        da_png_set_rgb_to_gray png_set_rgb_to_gray;
        da_png_set_rgb_to_gray_fixed png_set_rgb_to_gray_fixed;
        da_png_get_rgb_to_gray_status png_get_rgb_to_gray_status;
    }
    static if (PNG_BUILD_GRAYSCALE_PALETTE_SUPPORTED)
    {
        da_png_build_grayscale_palette png_build_grayscale_palette;
    }
    static if (PNG_READ_ALPHA_MODE_SUPPORTED)
    {
        da_png_set_alpha_mode png_set_alpha_mode;
        da_png_set_alpha_mode_fixed png_set_alpha_mode_fixed;
    }
    static if (PNG_READ_STRIP_ALPHA_SUPPORTED)
    {
        da_png_set_strip_alpha png_set_strip_alpha;
    }
    static if (PNG_READ_SWAP_ALPHA_SUPPORTED || PNG_WRITE_SWAP_ALPHA_SUPPORTED)
    {
        da_png_set_swap_alpha png_set_swap_alpha;
    }
    static if (PNG_READ_INVERT_ALPHA_SUPPORTED || PNG_WRITE_INVERT_ALPHA_SUPPORTED)
    {
        da_png_set_invert_alpha png_set_invert_alpha;
    }
    static if (PNG_READ_FILLER_SUPPORTED || PNG_WRITE_FILLER_SUPPORTED)
    {
        da_png_set_filler png_set_filler;
        da_png_set_add_alpha png_set_add_alpha;
    }
    static if (PNG_READ_SWAP_SUPPORTED || PNG_WRITE_SWAP_SUPPORTED)
    {
        da_png_set_swap png_set_swap;
    }
    static if (PNG_READ_PACK_SUPPORTED || PNG_WRITE_PACK_SUPPORTED)
    {
        da_png_set_packing png_set_packing;
    }
    static if (PNG_READ_PACKSWAP_SUPPORTED || PNG_WRITE_PACKSWAP_SUPPORTED)
    {
        da_png_set_packswap png_set_packswap;
    }
    static if (PNG_READ_SHIFT_SUPPORTED || PNG_WRITE_SHIFT_SUPPORTED)
    {
        da_png_set_shift png_set_shift;
    }
    static if (PNG_READ_INTERLACING_SUPPORTED || PNG_WRITE_INTERLACING_SUPPORTED)
    {
        da_png_set_interlace_handling png_set_interlace_handling;
    }
    static if (PNG_READ_INVERT_SUPPORTED || PNG_WRITE_INVERT_SUPPORTED)
    {
        da_png_set_invert_mono png_set_invert_mono;
    }
    static if (PNG_READ_BACKGROUND_SUPPORTED)
    {
        da_png_set_background png_set_background;
        da_png_set_background_fixed png_set_background_fixed;
    }
    static if (PNG_READ_SCALE_16_TO_8_SUPPORTED)
    {
        da_png_set_scale_16 png_set_scale_16;
    }
    static if (PNG_READ_STRIP_16_TO_8_SUPPORTED)
    {
        da_png_set_strip_16 png_set_strip_16;
    }
    static if (PNG_READ_QUANTIZE_SUPPORTED)
    {
        da_png_set_quantize png_set_quantize;
    }
    static if (PNG_READ_GAMMA_SUPPORTED)
    {
        da_png_set_gamma png_set_gamma;
        da_png_set_gamma_fixed png_set_gamma_fixed;
    }
    static if (PNG_WRITE_FLUSH_SUPPORTED)
    {
        da_png_set_flush png_set_flush;
        da_png_write_flush png_write_flush;
    }
    da_png_start_read_image png_start_read_image;
    da_png_read_update_info png_read_update_info;
    static if (PNG_SEQUENTIAL_READ_SUPPORTED)
    {
        da_png_read_rows png_read_rows;
    }
    static if (PNG_SEQUENTIAL_READ_SUPPORTED)
    {
        da_png_read_row png_read_row;
    }
    static if (PNG_SEQUENTIAL_READ_SUPPORTED)
    {
        da_png_read_image png_read_image;
    }
    da_png_write_row png_write_row;
    da_png_write_rows png_write_rows;
    da_png_write_image png_write_image;
    da_png_write_end png_write_end;
    static if (PNG_SEQUENTIAL_READ_SUPPORTED)
    {
        da_png_read_end png_read_end;
    }
    da_png_destroy_info_struct png_destroy_info_struct;
    da_png_destroy_read_struct png_destroy_read_struct;
    da_png_destroy_write_struct png_destroy_write_struct;
    da_png_set_crc_action png_set_crc_action;
    da_png_set_filter png_set_filter;
    static if (PNG_WRITE_WEIGHTED_FILTER_SUPPORTED)
    {
        da_png_set_filter_heuristics png_set_filter_heuristics;
        da_png_set_filter_heuristics_fixed png_set_filter_heuristics_fixed;
    }
    static if (PNG_WRITE_SUPPORTED)
    {
        da_png_set_compression_level png_set_compression_level;
        da_png_set_compression_mem_level png_set_compression_mem_level;
        da_png_set_compression_strategy png_set_compression_strategy;
        da_png_set_compression_window_bits png_set_compression_window_bits;
        da_png_set_compression_method png_set_compression_method;
    }
    static if (PNG_WRITE_CUSTOMIZE_ZTXT_COMPRESSION_SUPPORTED)
    {
        da_png_set_text_compression_level png_set_text_compression_level;
        da_png_set_text_compression_mem_level png_set_text_compression_mem_level;
        da_png_set_text_compression_strategy png_set_text_compression_strategy;
        da_png_set_text_compression_window_bits png_set_text_compression_window_bits;
        da_png_set_text_compression_method png_set_text_compression_method;
    }
    static if (PNG_STDIO_SUPPORTED)
    {
        da_png_init_io png_init_io;
    }
    da_png_set_error_fn png_set_error_fn;
    da_png_get_error_ptr png_get_error_ptr;
    da_png_set_write_fn png_set_write_fn;
    da_png_set_read_fn png_set_read_fn;
    da_png_get_io_ptr png_get_io_ptr;
    da_png_set_read_status_fn png_set_read_status_fn;
    da_png_set_write_status_fn png_set_write_status_fn;
    static if (PNG_USER_MEM_SUPPORTED)
    {
        da_png_set_mem_fn png_set_mem_fn;
        da_png_get_mem_ptr png_get_mem_ptr;
    }
    static if (PNG_READ_USER_TRANSFORM_SUPPORTED)
    {
        da_png_set_read_user_transform_fn png_set_read_user_transform_fn;
    }
    static if (PNG_WRITE_USER_TRANSFORM_SUPPORTED)
    {
        da_png_set_write_user_transform_fn png_set_write_user_transform_fn;
    }
    static if (PNG_USER_TRANSFORM_PTR_SUPPORTED)
    {
        da_png_set_user_transform_info png_set_user_transform_info;
        da_png_get_user_transform_ptr png_get_user_transform_ptr;
    }
    static if (PNG_USER_TRANSFORM_INFO_SUPPORTED)
    {
        da_png_get_current_row_number png_get_current_row_number;
        da_png_get_current_pass_number png_get_current_pass_number;
    }
    static if (PNG_READ_USER_CHUNKS_SUPPORTED)
    {
        da_png_set_read_user_chunk_fn png_set_read_user_chunk_fn;
    }
    static if (PNG_USER_CHUNKS_SUPPORTED)
    {
        da_png_get_user_chunk_ptr png_get_user_chunk_ptr;
    }
    static if (PNG_PROGRESSIVE_READ_SUPPORTED)
    {
        da_png_set_progressive_read_fn png_set_progressive_read_fn;
        da_png_get_progressive_ptr png_get_progressive_ptr;
        da_png_process_data png_process_data;
        da_png_process_data_pause png_process_data_pause;
        da_png_process_data_skip png_process_data_skip;
        da_png_progressive_combine_row png_progressive_combine_row;
    }
    da_png_malloc png_malloc;
    da_png_calloc png_calloc;
    da_png_malloc_warn png_malloc_warn;
    da_png_free png_free;
    da_png_free_data png_free_data;
    da_png_data_freer png_data_freer;
    static if (PNG_ERROR_TEXT_SUPPORTED)
    {
        da_png_error png_error;
        da_png_chunk_error png_chunk_error;
    }
    else
    {
        da_png_err png_err;
    }
    static if (PNG_WARNINGS_SUPPORTED)
    {
        da_png_warning png_warning;
        da_png_chunk_warning png_chunk_warning;
    }
    static if (PNG_BENIGN_ERRORS_SUPPORTED)
    {
        da_png_benign_error png_benign_error;
        static if (PNG_READ_SUPPORTED)
        {
            da_png_chunk_benign_error png_chunk_benign_error;
        }
        da_png_set_benign_errors png_set_benign_errors;
    }
    da_png_get_valid png_get_valid;
    da_png_get_rowbytes png_get_rowbytes;
    static if (PNG_INFO_IMAGE_SUPPORTED)
    {
        da_png_get_rows png_get_rows;
        da_png_set_rows png_set_rows;
    }
    da_png_get_channels png_get_channels;
    static if (PNG_EASY_ACCESS_SUPPORTED)
    {
        da_png_get_image_width png_get_image_width;
        da_png_get_image_height png_get_image_height;
        da_png_get_bit_depth png_get_bit_depth;
        da_png_get_color_type png_get_color_type;
        da_png_get_filter_type png_get_filter_type;
        da_png_get_interlace_type png_get_interlace_type;
        da_png_get_compression_type png_get_compression_type;
        da_png_get_pixels_per_meter png_get_pixels_per_meter;
        da_png_get_x_pixels_per_meter png_get_x_pixels_per_meter;
        da_png_get_y_pixels_per_meter png_get_y_pixels_per_meter;
        da_png_get_pixel_aspect_ratio png_get_pixel_aspect_ratio;
        da_png_get_pixel_aspect_ratio_fixed png_get_pixel_aspect_ratio_fixed;
        da_png_get_x_offset_pixels png_get_x_offset_pixels;
        da_png_get_y_offset_pixels png_get_y_offset_pixels;
        da_png_get_x_offset_microns png_get_x_offset_microns;
        da_png_get_y_offset_microns png_get_y_offset_microns;
    }
    static if (PNG_READ_SUPPORTED)
    {
        da_png_get_signature png_get_signature;
    }
    static if (PNG_bKGD_SUPPORTED)
    {
        da_png_get_bKGD png_get_bKGD;
    }
    static if (PNG_bKGD_SUPPORTED)
    {
        da_png_set_bKGD png_set_bKGD;
    }
    static if (PNG_cHRM_SUPPORTED)
    {
        da_png_get_cHRM png_get_cHRM;
        da_png_get_cHRM_XYZ png_get_cHRM_XYZ;
        static if (PNG_FIXED_POINT_SUPPORTED)
        {
            da_png_get_cHRM_fixed png_get_cHRM_fixed;
        }
        da_png_get_cHRM_XYZ_fixed png_get_cHRM_XYZ_fixed;
    }
    static if (PNG_cHRM_SUPPORTED)
    {
        da_png_set_cHRM png_set_cHRM;
        da_png_set_cHRM_XYZ png_set_cHRM_XYZ;
        da_png_set_cHRM_fixed png_set_cHRM_fixed;
        da_png_set_cHRM_XYZ_fixed png_set_cHRM_XYZ_fixed;
    }
    static if (PNG_gAMA_SUPPORTED)
    {
        da_png_get_gAMA png_get_gAMA;
        da_png_get_gAMA_fixed png_get_gAMA_fixed;
    }
    static if (PNG_gAMA_SUPPORTED)
    {
        da_png_set_gAMA png_set_gAMA;
        da_png_set_gAMA_fixed png_set_gAMA_fixed;
    }
    static if (PNG_hIST_SUPPORTED)
    {
        da_png_get_hIST png_get_hIST;
    }
    static if (PNG_hIST_SUPPORTED)
    {
        da_png_set_hIST png_set_hIST;
    }
    da_png_get_IHDR png_get_IHDR;
    da_png_set_IHDR png_set_IHDR;
    static if (PNG_oFFs_SUPPORTED)
    {
        da_png_get_oFFs png_get_oFFs;
    }
    static if (PNG_oFFs_SUPPORTED)
    {
        da_png_set_oFFs png_set_oFFs;
    }
    static if (PNG_pCAL_SUPPORTED)
    {
        da_png_get_pCAL png_get_pCAL;
    }
    static if (PNG_pCAL_SUPPORTED)
    {
        da_png_set_pCAL png_set_pCAL;
    }
    static if (PNG_pHYs_SUPPORTED)
    {
        da_png_get_pHYs png_get_pHYs;
    }
    static if (PNG_pHYs_SUPPORTED)
    {
        da_png_set_pHYs png_set_pHYs;
    }
    da_png_get_PLTE png_get_PLTE;
    da_png_set_PLTE png_set_PLTE;
    static if (PNG_sBIT_SUPPORTED)
    {
        da_png_get_sBIT png_get_sBIT;
        da_png_set_sBIT png_set_sBIT;
    }
    static if (PNG_sRGB_SUPPORTED)
    {
        da_png_get_sRGB png_get_sRGB;
        da_png_set_sRGB png_set_sRGB;
        da_png_set_sRGB_gAMA_and_cHRM png_set_sRGB_gAMA_and_cHRM;
    }
    static if (PNG_iCCP_SUPPORTED)
    {
        da_png_get_iCCP png_get_iCCP;
        da_png_set_iCCP png_set_iCCP;
    }
    static if (PNG_sPLT_SUPPORTED)
    {
        da_png_get_sPLT png_get_sPLT;
        da_png_set_sPLT png_set_sPLT;
    }
    static if (PNG_TEXT_SUPPORTED)
    {
        da_png_get_text png_get_text;
        da_png_set_text png_set_text;
    }
    static if (PNG_tIME_SUPPORTED)
    {
        da_png_get_tIME png_get_tIME;
        da_png_set_tIME png_set_tIME;
    }
    static if (PNG_tRNS_SUPPORTED)
    {
        da_png_get_tRNS png_get_tRNS;
        da_png_set_tRNS png_set_tRNS;
    }
    static if (PNG_sCAL_SUPPORTED)
    {
        da_png_get_sCAL png_get_sCAL;
        static if (PNG_FLOATING_ARITHMETIC_SUPPORTED || PNG_FLOATING_POINT_SUPPORTED)
        {
            da_png_get_sCAL_fixed png_get_sCAL_fixed;
        }
        da_png_get_sCAL_s png_get_sCAL_s;
        da_png_set_sCAL png_set_sCAL;
        da_png_const_set_sCAL_fixed png_const_set_sCAL_fixed;
        da_png_set_sCAL_s png_set_sCAL_s;
    }
    static if (PNG_SET_UNKNOWN_CHUNKS_SUPPORTED)
    {
        da_png_set_keep_unknown_chunks png_set_keep_unknown_chunks;
        da_png_handle_as_unknown png_handle_as_unknown;
    }
    static if (PNG_STORE_UNKNOWN_CHUNKS_SUPPORTED)
    {
        da_png_set_unknown_chunks png_set_unknown_chunks;
        da_png_set_unknown_chunk_location png_set_unknown_chunk_location;
        da_png_get_unknown_chunks png_get_unknown_chunks;
    }
    da_png_set_invalid png_set_invalid;
    static if (PNG_INFO_IMAGE_SUPPORTED)
    {
        static if (PNG_SEQUENTIAL_READ_SUPPORTED)
        {
            da_png_read_png png_read_png;
        }
        static if (PNG_WRITE_SUPPORTED)
        {
            da_png_write_png png_write_png;
        }
    }
    da_png_get_copyright png_get_copyright;
    da_png_get_header_ver png_get_header_ver;
    da_png_get_header_version png_get_header_version;
    da_png_get_libpng_ver png_get_libpng_ver;
    static if (PNG_MNG_FEATURES_SUPPORTED)
    {
        da_png_permit_mng_features png_permit_mng_features;
    }
    static if (PNG_SET_USER_LIMITS_SUPPORTED)
    {
        da_png_set_user_limits png_set_user_limits;
        da_png_get_user_width_max png_get_user_width_max;
        da_png_get_user_height_max png_get_user_height_max;
        da_png_set_chunk_cache_max png_set_chunk_cache_max;
        da_png_get_chunk_cache_max png_get_chunk_cache_max;
        da_png_set_chunk_malloc_max png_set_chunk_malloc_max;
        da_png_get_chunk_malloc_max png_get_chunk_malloc_max;
    }
    static if (PNG_INCH_CONVERSIONS_SUPPORTED)
    {
        da_png_get_pixels_per_inch png_get_pixels_per_inch;
        da_png_get_x_pixels_per_inch png_get_x_pixels_per_inch;
        da_png_get_y_pixels_per_inch png_get_y_pixels_per_inch;
        da_png_get_x_offset_inches png_get_x_offset_inches;
        static if (PNG_FIXED_POINT_SUPPORTED)
        {
            da_png_get_x_offset_inches_fixed png_get_x_offset_inches_fixed;
        }
        da_png_get_y_offset_inches png_get_y_offset_inches;
        static if (PNG_FIXED_POINT_SUPPORTED)
        {
            da_png_get_y_offset_inches_fixed png_get_y_offset_inches_fixed;
        }
        static if (PNG_pHYs_SUPPORTED)
        {
            da_png_get_pHYs_dpi png_get_pHYs_dpi;
        }
    }
    static if (PNG_IO_STATE_SUPPORTED)
    {
        da_png_get_io_state png_get_io_state;
        da_png_get_io_chunk_type png_get_io_chunk_type;
    }
    static if (PNG_READ_INT_FUNCTIONS_SUPPORTED)
    {
        da_png_get_uint_32 png_get_uint_32;
        da_png_get_uint_16 png_get_uint_16;
        da_png_get_int_32 png_get_int_32;
    }
    da_png_get_uint_31 png_get_uint_31;
    static if (PNG_WRITE_INT_FUNCTIONS_SUPPORTED)
    {
        da_png_save_uint_32 png_save_uint_32;
    }
    static if (PNG_SAVE_INT_32_SUPPORTED)
    {
        da_png_save_int_32 png_save_int_32;
    }
    static if (PNG_WRITE_INT_FUNCTIONS_SUPPORTED)
    {
        da_png_save_uint_16 png_save_uint_16;
    }
    static if (PNG_SIMPLIFIED_READ_SUPPORTED)
    {
        static if (PNG_STDIO_SUPPORTED)
        {
            da_png_image_begin_read_from_file png_image_begin_read_from_file;
            da_png_image_begin_read_from_stdio png_image_begin_read_from_stdio;
        }
        da_png_image_begin_read_from_memory png_image_begin_read_from_memory;
        da_png_image_finish_read png_image_finish_read;
        da_png_image_free png_image_free;
    }
    static if (PNG_SIMPLIFIED_WRITE_SUPPORTED)
    {
        static if (PNG_STDIO_SUPPORTED)
        {
            da_png_image_write_to_file png_image_write_to_file;
            da_png_image_write_to_stdio png_image_write_to_stdio;
        }
    }
    static if (PNG_CHECK_FOR_INVALID_INDEX_SUPPORTED)
    {
        da_png_set_check_for_invalid_index png_set_check_for_invalid_index;
        static if (PNG_GET_PALETTE_MAX_SUPPORTED)
        {
            da_png_get_palette_max png_get_palette_max;
        }
    }
    static if (PNG_SET_OPTION_SUPPORTED)
    {
        da_png_set_option png_set_option;
    }
}
