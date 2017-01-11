module dgt.bindings.cairo.win32;

version (Windows):

import dgt.bindings.cairo.types;
import dgt.bindings.cairo.enums;

import core.sys.windows.windef;

extern(C) nothrow @nogc __gshared
{
    cairo_surface_t * function (HDC hdc)
            cairo_win32_surface_create;

    cairo_surface_t * function (HDC hdc)
            cairo_win32_printing_surface_create;

    cairo_surface_t * function (HDC hdc,
                                         cairo_format_t format,
                                         int width,
                                         int height)
            cairo_win32_surface_create_with_ddb;

    cairo_surface_t * function (cairo_format_t format,
                                         int width,
                                         int height)
            cairo_win32_surface_create_with_dib;

    HDC function (cairo_surface_t *surface)
            cairo_win32_surface_get_dc;

    cairo_surface_t * function (cairo_surface_t *surface)
            cairo_win32_surface_get_image;


    cairo_font_face_t * function (LOGFONTW *logfont)
            cairo_win32_font_face_create_for_logfontw;

    cairo_font_face_t * function (HFONT font)
            cairo_win32_font_face_create_for_hfont;

    cairo_font_face_t * function (LOGFONTW *logfont, HFONT font)
            cairo_win32_font_face_create_for_logfontw_hfont;

    cairo_status_t function (cairo_scaled_font_t *scaled_font,
                         HDC                  hdc)
            cairo_win32_scaled_font_select_font;

    void function (cairo_scaled_font_t *scaled_font)
            cairo_win32_scaled_font_done_font;

    double function (cairo_scaled_font_t *scaled_font)
            cairo_win32_scaled_font_get_metrics_factor;

    void function (cairo_scaled_font_t *scaled_font,
                               cairo_matrix_t *logical_to_device)
            cairo_win32_scaled_font_get_logical_to_device;

    void function (cairo_scaled_font_t *scaled_font,
                               cairo_matrix_t *device_to_logical)
            cairo_win32_scaled_font_get_device_to_logical;
}

