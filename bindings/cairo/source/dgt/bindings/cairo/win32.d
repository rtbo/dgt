module dgt.bindings.cairo.win32;

version (Windows):

import dgt.bindings.cairo.types;
import dgt.bindings.cairo.enums;

import core.sys.windows.windef;
import core.sys.windows.wingdi;

extern(C) nothrow @nogc
{
    alias da_cairo_win32_surface_create = cairo_surface_t * function (HDC hdc);

    alias da_cairo_win32_printing_surface_create = cairo_surface_t * function (HDC hdc);

    alias da_cairo_win32_surface_create_with_ddb = cairo_surface_t * function (HDC hdc,
                                         cairo_format_t format,
                                         int width,
                                         int height);

    alias da_cairo_win32_surface_create_with_dib = cairo_surface_t * function (cairo_format_t format,
                                         int width,
                                         int height);

    alias da_cairo_win32_surface_get_dc = HDC function (cairo_surface_t *surface);

    alias da_cairo_win32_surface_get_image = cairo_surface_t * function (cairo_surface_t *surface);


    alias da_cairo_win32_font_face_create_for_logfontw = cairo_font_face_t * function (LOGFONTW *logfont);

    alias da_cairo_win32_font_face_create_for_hfont = cairo_font_face_t * function (HFONT font);

    alias da_cairo_win32_font_face_create_for_logfontw_hfont = cairo_font_face_t * function (LOGFONTW *logfont, HFONT font);

    alias da_cairo_win32_scaled_font_select_font = cairo_status_t function (cairo_scaled_font_t *scaled_font,
                         HDC                  hdc);

    alias da_cairo_win32_scaled_font_done_font = void function (cairo_scaled_font_t *scaled_font);

    alias da_cairo_win32_scaled_font_get_metrics_factor = double function (cairo_scaled_font_t *scaled_font);

    alias da_cairo_win32_scaled_font_get_logical_to_device = void function (cairo_scaled_font_t *scaled_font,
                               cairo_matrix_t *logical_to_device);

    alias da_cairo_win32_scaled_font_get_device_to_logical = void function (cairo_scaled_font_t *scaled_font,
                               cairo_matrix_t *device_to_logical);
}

extern(C) nothrow @nogc __gshared
{
    da_cairo_win32_surface_create cairo_win32_surface_create;

    da_cairo_win32_printing_surface_create cairo_win32_printing_surface_create;

    da_cairo_win32_surface_create_with_ddb cairo_win32_surface_create_with_ddb;

    da_cairo_win32_surface_create_with_dib cairo_win32_surface_create_with_dib;

    da_cairo_win32_surface_get_dc cairo_win32_surface_get_dc;

    da_cairo_win32_surface_get_image cairo_win32_surface_get_image;


    da_cairo_win32_font_face_create_for_logfontw cairo_win32_font_face_create_for_logfontw;

    da_cairo_win32_font_face_create_for_hfont cairo_win32_font_face_create_for_hfont;

    da_cairo_win32_font_face_create_for_logfontw_hfont cairo_win32_font_face_create_for_logfontw_hfont;

    da_cairo_win32_scaled_font_select_font cairo_win32_scaled_font_select_font;

    da_cairo_win32_scaled_font_done_font cairo_win32_scaled_font_done_font;

    da_cairo_win32_scaled_font_get_metrics_factor cairo_win32_scaled_font_get_metrics_factor;

    da_cairo_win32_scaled_font_get_logical_to_device cairo_win32_scaled_font_get_logical_to_device;

    da_cairo_win32_scaled_font_get_device_to_logical cairo_win32_scaled_font_get_device_to_logical;
}

