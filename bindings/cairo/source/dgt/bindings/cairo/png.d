module dgt.bindings.cairo.png;

import dgt.bindings.cairo.enums;
import dgt.bindings.cairo.types;

extern(C) nothrow @nogc __gshared
{
    cairo_status_t function (cairo_surface_t* surface, const(char)* filename)
            cairo_surface_write_to_png;

    cairo_status_t function (cairo_surface_t* surface, cairo_write_func_t write_func,
                             void* closure)
            cairo_surface_write_to_png_stream;

    cairo_surface_t* function (const(char)* filename)
            cairo_image_surface_create_from_png;

    cairo_surface_t* function (cairo_read_func_t read_func, void* closure)
            cairo_image_surface_create_from_png_stream;
}
