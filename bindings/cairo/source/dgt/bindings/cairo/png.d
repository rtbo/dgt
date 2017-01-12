module dgt.bindings.cairo.png;

import dgt.bindings.cairo.enums;
import dgt.bindings.cairo.types;

extern(C) nothrow @nogc
{
    alias da_cairo_surface_write_to_png = cairo_status_t function (cairo_surface_t* surface, const(char)* filename);

    alias da_cairo_surface_write_to_png_stream = cairo_status_t function (cairo_surface_t* surface, cairo_write_func_t write_func,
                             void* closure);

    alias da_cairo_image_surface_create_from_png = cairo_surface_t* function (const(char)* filename);

    alias da_cairo_image_surface_create_from_png_stream = cairo_surface_t* function (cairo_read_func_t read_func, void* closure);
}


__gshared
{
    da_cairo_surface_write_to_png cairo_surface_write_to_png;

    da_cairo_surface_write_to_png_stream cairo_surface_write_to_png_stream;

    da_cairo_image_surface_create_from_png cairo_image_surface_create_from_png;

    da_cairo_image_surface_create_from_png_stream cairo_image_surface_create_from_png_stream;
}

