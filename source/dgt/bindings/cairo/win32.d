module dgt.bindings.cairo.win32;

version(Windows):

import dgt.bindings.cairo.types;
import dgt.bindings.cairo.enums;
import dgt.bindings;

import core.sys.windows.windef;

__gshared Symbol!(cairo_surface_t*, HDC) cairo_win32_surface_create;

__gshared Symbol!(cairo_surface_t*, HDC) cairo_win32_printing_surface_create;

__gshared Symbol!(cairo_surface_t*, HDC, cairo_format_t, int, int) cairo_win32_surface_create_with_ddb;

__gshared Symbol!(cairo_surface_t*, cairo_format_t, int, int) cairo_win32_surface_create_with_dib;

__gshared Symbol!(HDC, cairo_surface_t*) cairo_win32_surface_get_dc;

__gshared Symbol!(cairo_surface_t*, cairo_surface_t*) cairo_win32_surface_get_image;

__gshared Symbol!(cairo_font_face_t*, LOGFONTW*) cairo_win32_font_face_create_for_logfontw;

__gshared Symbol!(cairo_font_face_t*, HFONT) cairo_win32_font_face_create_for_hfont;

__gshared Symbol!(cairo_font_face_t*, LOGFONTW*, HFONT) cairo_win32_font_face_create_for_logfontw_hfont;

__gshared Symbol!(cairo_status_t, cairo_scaled_font_t*, HDC) cairo_win32_scaled_font_select_font;

__gshared Symbol!(void, cairo_scaled_font_t*) cairo_win32_scaled_font_done_font;

__gshared Symbol!(double, cairo_scaled_font_t*) cairo_win32_scaled_font_get_metrics_factor;

__gshared Symbol!(void, cairo_scaled_font_t*, cairo_matrix_t*) cairo_win32_scaled_font_get_logical_to_device;

__gshared Symbol!(void, cairo_scaled_font_t*, cairo_matrix_t*) cairo_win32_scaled_font_get_device_to_logical;
