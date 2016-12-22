module dgt.bindings.cairo.png;

import dgt.bindings.cairo.enums;
import dgt.bindings.cairo.types;
import dgt.bindings;

__gshared Symbol!(cairo_status_t, cairo_surface_t*, const(char)*) cairo_surface_write_to_png;

__gshared Symbol!(cairo_status_t, cairo_surface_t*, cairo_write_func_t, void*) cairo_surface_write_to_png_stream;

__gshared Symbol!(cairo_surface_t*, const(char)*) cairo_image_surface_create_from_png;

__gshared Symbol!(cairo_surface_t*, cairo_read_func_t, void*) cairo_image_surface_create_from_png_stream;
