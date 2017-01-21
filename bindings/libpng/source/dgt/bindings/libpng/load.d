module dgt.bindings.libpng.load;

import dgt.bindings.libpng.pnglibconf;
import dgt.bindings.libpng.pngconf;
import dgt.bindings.libpng.symbols;
import dgt.bindings;

import std.meta : AliasSeq;
import std.typecons : Yes;

/// Load the linpng library symbols.
/// Must be called before any use of png_* functions.
/// If no libNames is provided, a per-platform guess is performed.
public void loadLibpngSymbols(string[] libNames = [])
{
    version (linux)
    {
        auto defaultLibNames = ["libpng.so", "libpng.so.16"];
    }
    version (Windows)
    {
        auto defaultLibNames = ["libpng.dll", "libpng-16.dll"];
    }
    if (libNames.length == 0)
    {
        libNames = defaultLibNames;
    }
    libpngLoader.load(libNames);
}

/// Checks whether libpng is loaded
public @property bool libpngLoaded()
{
    return libpngLoader.loaded;
}

shared static this()
{
    libpngLoader = new LibpngLoader();
}

private __gshared LibpngLoader libpngLoader;

private class LibpngLoader : SharedLibLoader
{
    override void bindSymbols()
    {
        bind!(png_access_version_number)();
        bind!(png_set_sig_bytes)();
        bind!(png_sig_cmp)();
        bind!(png_create_read_struct)();
        bind!(png_create_write_struct)();
        bind!(png_get_compression_buffer_size)();
        bind!(png_set_compression_buffer_size)();
        bind!(png_longjmp)();
        static if (PNG_USER_MEM_SUPPORTED)
        {
            bind!(png_create_read_struct_2)();
            bind!(png_create_write_struct_2)();
        }
        bind!(png_write_sig)();
        bind!(png_write_chunk)();
        bind!(png_write_chunk_start)();
        bind!(png_write_chunk_data)();
        bind!(png_write_chunk_end)();
        bind!(png_create_info_struct)();
        bind!(png_write_info_before_PLTE)();
        bind!(png_write_info)();
        static if (PNG_SEQUENTIAL_READ_SUPPORTED)
        {
            bind!(png_read_info)();
        }
        static if (PNG_TIME_RFC1123_SUPPORTED)
        {
            bind!(png_convert_to_rfc1123_buffer)();
        }
        static if (PNG_CONVERT_tIME_SUPPORTED)
        {
            bind!(png_convert_from_struct_tm)();
            bind!(png_convert_from_time_t)();
        }
        static if (PNG_READ_EXPAND_SUPPORTED)
        {
            bind!(png_set_expand)();
            bind!(png_set_expand_gray_1_2_4_to_8)();
            bind!(png_set_palette_to_rgb)();
            bind!(png_set_tRNS_to_alpha)();
        }
        static if (PNG_READ_EXPAND_16_SUPPORTED)
        {
            bind!(png_set_expand_16)();
        }
        static if (PNG_READ_BGR_SUPPORTED || PNG_WRITE_BGR_SUPPORTED)
        {
            bind!(png_set_bgr)();
        }
        static if (PNG_READ_GRAY_TO_RGB_SUPPORTED)
        {
            bind!(png_set_gray_to_rgb)();
        }
        static if (PNG_READ_RGB_TO_GRAY_SUPPORTED)
        {
            bind!(png_set_rgb_to_gray)();
            bind!(png_set_rgb_to_gray_fixed)();
            bind!(png_get_rgb_to_gray_status)();
        }
        static if (PNG_BUILD_GRAYSCALE_PALETTE_SUPPORTED)
        {
            bind!(png_build_grayscale_palette)();
        }
        static if (PNG_READ_ALPHA_MODE_SUPPORTED)
        {
            bind!(png_set_alpha_mode)();
            bind!(png_set_alpha_mode_fixed)();
        }
        static if (PNG_READ_STRIP_ALPHA_SUPPORTED)
        {
            bind!(png_set_strip_alpha)();
        }
        static if (PNG_READ_SWAP_ALPHA_SUPPORTED || PNG_WRITE_SWAP_ALPHA_SUPPORTED)
        {
            bind!(png_set_swap_alpha)();
        }
        static if (PNG_READ_INVERT_ALPHA_SUPPORTED || PNG_WRITE_INVERT_ALPHA_SUPPORTED)
        {
            bind!(png_set_invert_alpha)();
        }
        static if (PNG_READ_FILLER_SUPPORTED || PNG_WRITE_FILLER_SUPPORTED)
        {
            bind!(png_set_filler)();
            bind!(png_set_add_alpha)();
        }
        static if (PNG_READ_SWAP_SUPPORTED || PNG_WRITE_SWAP_SUPPORTED)
        {
            bind!(png_set_swap)();
        }
        static if (PNG_READ_PACK_SUPPORTED || PNG_WRITE_PACK_SUPPORTED)
        {
            bind!(png_set_packing)();
        }
        static if (PNG_READ_PACKSWAP_SUPPORTED || PNG_WRITE_PACKSWAP_SUPPORTED)
        {
            bind!(png_set_packswap)();
        }
        static if (PNG_READ_SHIFT_SUPPORTED || PNG_WRITE_SHIFT_SUPPORTED)
        {
            bind!(png_set_shift)();
        }
        static if (PNG_READ_INTERLACING_SUPPORTED || PNG_WRITE_INTERLACING_SUPPORTED)
        {
            bind!(png_set_interlace_handling)();
        }
        static if (PNG_READ_INVERT_SUPPORTED || PNG_WRITE_INVERT_SUPPORTED)
        {
            bind!(png_set_invert_mono)();
        }
        static if (PNG_READ_BACKGROUND_SUPPORTED)
        {
            bind!(png_set_background)();
            bind!(png_set_background_fixed)();
        }
        static if (PNG_READ_SCALE_16_TO_8_SUPPORTED)
        {
            bind!(png_set_scale_16)();
        }
        static if (PNG_READ_STRIP_16_TO_8_SUPPORTED)
        {
            bind!(png_set_strip_16)();
        }
        static if (PNG_READ_QUANTIZE_SUPPORTED)
        {
            bind!(png_set_quantize)();
        }
        static if (PNG_READ_GAMMA_SUPPORTED)
        {
            bind!(png_set_gamma)();
            bind!(png_set_gamma_fixed)();
        }
        static if (PNG_WRITE_FLUSH_SUPPORTED)
        {
            bind!(png_set_flush)();
            bind!(png_write_flush)();
        }
        bind!(png_start_read_image)();
        bind!(png_read_update_info)();
        static if (PNG_SEQUENTIAL_READ_SUPPORTED)
        {
            bind!(png_read_rows)();
        }
        static if (PNG_SEQUENTIAL_READ_SUPPORTED)
        {
            bind!(png_read_row)();
        }
        static if (PNG_SEQUENTIAL_READ_SUPPORTED)
        {
            bind!(png_read_image)();
        }
        bind!(png_write_row)();
        bind!(png_write_rows)();
        bind!(png_write_image)();
        bind!(png_write_end)();
        static if (PNG_SEQUENTIAL_READ_SUPPORTED)
        {
            bind!(png_read_end)();
        }
        bind!(png_destroy_info_struct)();
        bind!(png_destroy_read_struct)();
        bind!(png_destroy_write_struct)();
        bind!(png_set_crc_action)();
        bind!(png_set_filter)();
        static if (PNG_WRITE_WEIGHTED_FILTER_SUPPORTED)
        {
            bind!(png_set_filter_heuristics)();
            bind!(png_set_filter_heuristics_fixed)();
        }
        static if (PNG_WRITE_SUPPORTED)
        {
            bind!(png_set_compression_level)();
            bind!(png_set_compression_mem_level)();
            bind!(png_set_compression_strategy)();
            bind!(png_set_compression_window_bits)();
            bind!(png_set_compression_method)();
        }
        static if (PNG_WRITE_CUSTOMIZE_ZTXT_COMPRESSION_SUPPORTED)
        {
            bind!(png_set_text_compression_level)();
            bind!(png_set_text_compression_mem_level)();
            bind!(png_set_text_compression_strategy)();
            bind!(png_set_text_compression_window_bits)();
            bind!(png_set_text_compression_method)();
        }
        static if (PNG_STDIO_SUPPORTED)
        {
            bind!(png_init_io)();
        }
        bind!(png_set_error_fn)();
        bind!(png_get_error_ptr)();
        bind!(png_set_write_fn)();
        bind!(png_set_read_fn)();
        bind!(png_get_io_ptr)();
        bind!(png_set_read_status_fn)();
        bind!(png_set_write_status_fn)();
        static if (PNG_USER_MEM_SUPPORTED)
        {
            bind!(png_set_mem_fn)();
            bind!(png_get_mem_ptr)();
        }
        static if (PNG_READ_USER_TRANSFORM_SUPPORTED)
        {
            bind!(png_set_read_user_transform_fn)();
        }
        static if (PNG_WRITE_USER_TRANSFORM_SUPPORTED)
        {
            bind!(png_set_write_user_transform_fn)();
        }
        static if (PNG_USER_TRANSFORM_PTR_SUPPORTED)
        {
            bind!(png_set_user_transform_info)();
            bind!(png_get_user_transform_ptr)();
        }
        static if (PNG_USER_TRANSFORM_INFO_SUPPORTED)
        {
            bind!(png_get_current_row_number)();
            bind!(png_get_current_pass_number)();
        }
        static if (PNG_READ_USER_CHUNKS_SUPPORTED)
        {
            bind!(png_set_read_user_chunk_fn)();
        }
        static if (PNG_USER_CHUNKS_SUPPORTED)
        {
            bind!(png_get_user_chunk_ptr)();
        }
        static if (PNG_PROGRESSIVE_READ_SUPPORTED)
        {
            bind!(png_set_progressive_read_fn)();
            bind!(png_get_progressive_ptr)();
            bind!(png_process_data)();
            bind!(png_process_data_pause)();
            bind!(png_process_data_skip)();
            bind!(png_progressive_combine_row)();
        }
        bind!(png_malloc)();
        bind!(png_calloc)();
        bind!(png_malloc_warn)();
        bind!(png_free)();
        bind!(png_free_data)();
        bind!(png_data_freer)();
        static if (PNG_ERROR_TEXT_SUPPORTED)
        {
            bind!(png_error)();
            bind!(png_chunk_error)();
        }
        else
        {
            bind!(png_err)();
        }
        static if (PNG_WARNINGS_SUPPORTED)
        {
            bind!(png_warning)();
            bind!(png_chunk_warning)();
        }
        static if (PNG_BENIGN_ERRORS_SUPPORTED)
        {
            bind!(png_benign_error)();
            static if (PNG_READ_SUPPORTED)
            {
                bind!(png_chunk_benign_error)();
            }
            bind!(png_set_benign_errors)();
        }
        bind!(png_get_valid)();
        bind!(png_get_rowbytes)();
        static if (PNG_INFO_IMAGE_SUPPORTED)
        {
            bind!(png_get_rows)();
            bind!(png_set_rows)();
        }
        bind!(png_get_channels)();
        static if (PNG_EASY_ACCESS_SUPPORTED)
        {
            bind!(png_get_image_width)();
            bind!(png_get_image_height)();
            bind!(png_get_bit_depth)();
            bind!(png_get_color_type)();
            bind!(png_get_filter_type)();
            bind!(png_get_interlace_type)();
            bind!(png_get_compression_type)();
            bind!(png_get_pixels_per_meter)();
            bind!(png_get_x_pixels_per_meter)();
            bind!(png_get_y_pixels_per_meter)();
            bind!(png_get_pixel_aspect_ratio)();
            bind!(png_get_pixel_aspect_ratio_fixed)();
            bind!(png_get_x_offset_pixels)();
            bind!(png_get_y_offset_pixels)();
            bind!(png_get_x_offset_microns)();
            bind!(png_get_y_offset_microns)();
        }
        static if (PNG_READ_SUPPORTED)
        {
            bind!(png_get_signature)();
        }
        static if (PNG_bKGD_SUPPORTED)
        {
            bind!(png_get_bKGD)();
        }
        static if (PNG_bKGD_SUPPORTED)
        {
            bind!(png_set_bKGD)();
        }
        static if (PNG_cHRM_SUPPORTED)
        {
            bind!(png_get_cHRM)();
            bind!(png_get_cHRM_XYZ)();
            static if (PNG_FIXED_POINT_SUPPORTED)
            {
                bind!(png_get_cHRM_fixed)();
            }
            bind!(png_get_cHRM_XYZ_fixed)();
        }
        static if (PNG_cHRM_SUPPORTED)
        {
            bind!(png_set_cHRM)();
            bind!(png_set_cHRM_XYZ)();
            bind!(png_set_cHRM_fixed)();
            bind!(png_set_cHRM_XYZ_fixed)();
        }
        static if (PNG_gAMA_SUPPORTED)
        {
            bind!(png_get_gAMA)();
            bind!(png_get_gAMA_fixed)();
        }
        static if (PNG_gAMA_SUPPORTED)
        {
            bind!(png_set_gAMA)();
            bind!(png_set_gAMA_fixed)();
        }
        static if (PNG_hIST_SUPPORTED)
        {
            bind!(png_get_hIST)();
        }
        static if (PNG_hIST_SUPPORTED)
        {
            bind!(png_set_hIST)();
        }
        bind!(png_get_IHDR)();
        bind!(png_set_IHDR)();
        static if (PNG_oFFs_SUPPORTED)
        {
            bind!(png_get_oFFs)();
        }
        static if (PNG_oFFs_SUPPORTED)
        {
            bind!(png_set_oFFs)();
        }
        static if (PNG_pCAL_SUPPORTED)
        {
            bind!(png_get_pCAL)();
        }
        static if (PNG_pCAL_SUPPORTED)
        {
            bind!(png_set_pCAL)();
        }
        static if (PNG_pHYs_SUPPORTED)
        {
            bind!(png_get_pHYs)();
        }
        static if (PNG_pHYs_SUPPORTED)
        {
            bind!(png_set_pHYs)();
        }
        bind!(png_get_PLTE)();
        bind!(png_set_PLTE)();
        static if (PNG_sBIT_SUPPORTED)
        {
            bind!(png_get_sBIT)();
            bind!(png_set_sBIT)();
        }
        static if (PNG_sRGB_SUPPORTED)
        {
            bind!(png_get_sRGB)();
            bind!(png_set_sRGB)();
            bind!(png_set_sRGB_gAMA_and_cHRM)();
        }
        static if (PNG_iCCP_SUPPORTED)
        {
            bind!(png_get_iCCP)();
            bind!(png_set_iCCP)();
        }
        static if (PNG_sPLT_SUPPORTED)
        {
            bind!(png_get_sPLT)();
            bind!(png_set_sPLT)();
        }
        static if (PNG_TEXT_SUPPORTED)
        {
            bind!(png_get_text)();
            bind!(png_set_text)();
        }
        static if (PNG_tIME_SUPPORTED)
        {
            bind!(png_get_tIME)();
            bind!(png_set_tIME)();
        }
        static if (PNG_tRNS_SUPPORTED)
        {
            bind!(png_get_tRNS)();
            bind!(png_set_tRNS)();
        }
        static if (PNG_sCAL_SUPPORTED)
        {
            bind!(png_get_sCAL)();
            static if (PNG_FLOATING_ARITHMETIC_SUPPORTED || PNG_FLOATING_POINT_SUPPORTED)
            {
                bind!(png_get_sCAL_fixed)();
            }
            bind!(png_get_sCAL_s)();
            bind!(png_set_sCAL)();
            bind!(png_const_set_sCAL_fixed)();
            bind!(png_set_sCAL_s)();
        }
        static if (PNG_SET_UNKNOWN_CHUNKS_SUPPORTED)
        {
            bind!(png_set_keep_unknown_chunks)();
            bind!(png_handle_as_unknown)();
        }
        static if (PNG_STORE_UNKNOWN_CHUNKS_SUPPORTED)
        {
            bind!(png_set_unknown_chunks)();
            bind!(png_set_unknown_chunk_location)();
            bind!(png_get_unknown_chunks)();
        }
        bind!(png_set_invalid)();
        static if (PNG_INFO_IMAGE_SUPPORTED)
        {
            static if (PNG_SEQUENTIAL_READ_SUPPORTED)
            {
                bind!(png_read_png)();
            }
            static if (PNG_WRITE_SUPPORTED)
            {
                bind!(png_write_png)();
            }
        }
        bind!(png_get_copyright)();
        bind!(png_get_header_ver)();
        bind!(png_get_header_version)();
        bind!(png_get_libpng_ver)();
        static if (PNG_MNG_FEATURES_SUPPORTED)
        {
            bind!(png_permit_mng_features)();
        }
        static if (PNG_SET_USER_LIMITS_SUPPORTED)
        {
            bind!(png_set_user_limits)();
            bind!(png_get_user_width_max)();
            bind!(png_get_user_height_max)();
            bind!(png_set_chunk_cache_max)();
            bind!(png_get_chunk_cache_max)();
            bind!(png_set_chunk_malloc_max)();
            bind!(png_get_chunk_malloc_max)();
        }
        static if (PNG_INCH_CONVERSIONS_SUPPORTED)
        {
            bind!(png_get_pixels_per_inch)();
            bind!(png_get_x_pixels_per_inch)();
            bind!(png_get_y_pixels_per_inch)();
            bind!(png_get_x_offset_inches)();
            static if (PNG_FIXED_POINT_SUPPORTED)
            {
                bind!(png_get_x_offset_inches_fixed)();
            }
            bind!(png_get_y_offset_inches)();
            static if (PNG_FIXED_POINT_SUPPORTED)
            {
                bind!(png_get_y_offset_inches_fixed)();
            }
            static if (PNG_pHYs_SUPPORTED)
            {
                bind!(png_get_pHYs_dpi)();
            }
        }
        static if (PNG_IO_STATE_SUPPORTED)
        {
            bind!(png_get_io_state)();
            bind!(png_get_io_chunk_type)();
        }
        static if (PNG_READ_INT_FUNCTIONS_SUPPORTED)
        {
            bind!(png_get_uint_32)();
            bind!(png_get_uint_16)();
            bind!(png_get_int_32)();
        }
        bind!(png_get_uint_31)();
        static if (PNG_WRITE_INT_FUNCTIONS_SUPPORTED)
        {
            bind!(png_save_uint_32)();
        }
        static if (PNG_SAVE_INT_32_SUPPORTED)
        {
            bind!(png_save_int_32)();
        }
        static if (PNG_WRITE_INT_FUNCTIONS_SUPPORTED)
        {
            bind!(png_save_uint_16)();
        }
        static if (PNG_SIMPLIFIED_READ_SUPPORTED)
        {
            static if (PNG_STDIO_SUPPORTED)
            {
                bind!(png_image_begin_read_from_file)();
                bind!(png_image_begin_read_from_stdio)();
            }
            bind!(png_image_begin_read_from_memory)();
            bind!(png_image_finish_read)();
            bind!(png_image_free)();
        }
        static if (PNG_SIMPLIFIED_WRITE_SUPPORTED)
        {
            static if (PNG_STDIO_SUPPORTED)
            {
                bind!(png_image_write_to_file)();
                bind!(png_image_write_to_stdio)();
            }
        }
        static if (PNG_CHECK_FOR_INVALID_INDEX_SUPPORTED)
        {
            bind!(png_set_check_for_invalid_index)();
            static if (PNG_GET_PALETTE_MAX_SUPPORTED)
            {
                bind!(png_get_palette_max)();
            }
        }
        static if (PNG_SET_OPTION_SUPPORTED)
        {
            bind!(png_set_option)();
        }
    }
}
