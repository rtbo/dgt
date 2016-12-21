module dgt.bindings.cairo.xcb;

version(linux):

import dgt.bindings.cairo.types;
import dgt.bindings.cairo.enums;
import dgt.bindings;

import xcb.xcb;
import xcb.render;

__gshared Symbol!(cairo_surface_t*, xcb_connection_t*, xcb_drawable_t, xcb_visualtype_t*, int, int) cairo_xcb_surface_create;

__gshared Symbol!(cairo_surface_t*, xcb_connection_t*, xcb_screen_t*, xcb_pixmap_t, int, int) cairo_xcb_surface_create_for_bitmap;

__gshared Symbol!(cairo_surface_t*, xcb_connection_t*, xcb_screen_t*, xcb_drawable_t,
        xcb_render_pictforminfo_t*, int, int) cairo_xcb_surface_create_with_xrender_format;

__gshared Symbol!(void, cairo_surface_t*, int, int) cairo_xcb_surface_set_size;

__gshared Symbol!(void, cairo_surface_t*, xcb_drawable_t, int, int) cairo_xcb_surface_set_drawable;

__gshared Symbol!(xcb_connection_t*, cairo_device_t*) cairo_xcb_device_get_connection;

__gshared Symbol!(void, cairo_device_t*, int, int) cairo_xcb_device_debug_cap_xshm_version;

__gshared Symbol!(void, cairo_device_t*, int, int) cairo_xcb_device_debug_cap_xrender_version;

__gshared Symbol!(void, cairo_device_t*, int) cairo_xcb_device_debug_set_precision;

__gshared Symbol!(int, cairo_device_t*) cairo_xcb_device_debug_get_precision;
