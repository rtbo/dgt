module dgt.bindings.cairo.xcb;

version(linux):

import dgt.bindings.cairo.types;
import dgt.bindings.cairo.enums;

import xcb.xcb;
import xcb.render;

extern(C) nothrow @nogc
{
    alias da_cairo_xcb_surface_create = cairo_surface_t * function (xcb_connection_t	*connection,
                                xcb_drawable_t	 drawable,
                                xcb_visualtype_t	*visual,
                                int			 width,
                                int			 height);

    alias da_cairo_xcb_surface_create_for_bitmap = cairo_surface_t * function (xcb_connection_t	*connection,
                                xcb_screen_t	*screen,
                                xcb_pixmap_t	 bitmap,
                                int		 width,
                                int		 height);

    alias da_cairo_xcb_surface_create_with_xrender_format = cairo_surface_t * function (xcb_connection_t			*connection,
                                xcb_screen_t			*screen,
                                xcb_drawable_t			 drawable,
                                xcb_render_pictforminfo_t		*format,
                                int				 width,
                                int				 height);

    alias da_cairo_xcb_surface_set_size = void function (cairo_surface_t *surface,
                   int		     width,
                   int		     height);

    alias da_cairo_xcb_surface_set_drawable = void function (cairo_surface_t *surface,
                   xcb_drawable_t	drawable,
                   int		width,
                   int		height);

    alias da_cairo_xcb_device_get_connection = xcb_connection_t * function (cairo_device_t *device);


    alias da_cairo_xcb_device_debug_cap_xshm_version = void function (cairo_device_t *device,
                   int major_version,
                   int minor_version);

    alias da_cairo_xcb_device_debug_cap_xrender_version = void function (cairo_device_t *device,
                   int major_version,
                   int minor_version);

    alias da_cairo_xcb_device_debug_set_precision = void function (cairo_device_t *device,
                   int precision);

    alias da_cairo_xcb_device_debug_get_precision = int function (cairo_device_t *device);
}

__gshared
{
    da_cairo_xcb_surface_create cairo_xcb_surface_create;

    da_cairo_xcb_surface_create_for_bitmap cairo_xcb_surface_create_for_bitmap;

    da_cairo_xcb_surface_create_with_xrender_format cairo_xcb_surface_create_with_xrender_format;

    da_cairo_xcb_surface_set_size cairo_xcb_surface_set_size;

    da_cairo_xcb_surface_set_drawable cairo_xcb_surface_set_drawable;

    da_cairo_xcb_device_get_connection cairo_xcb_device_get_connection;


    da_cairo_xcb_device_debug_cap_xshm_version cairo_xcb_device_debug_cap_xshm_version;

    da_cairo_xcb_device_debug_cap_xrender_version cairo_xcb_device_debug_cap_xrender_version;

    da_cairo_xcb_device_debug_set_precision cairo_xcb_device_debug_set_precision;

    da_cairo_xcb_device_debug_get_precision cairo_xcb_device_debug_get_precision;
}

