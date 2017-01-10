module dgt.bindings.cairo.xcb;

version(linux):

import dgt.bindings.cairo.types;
import dgt.bindings.cairo.enums;

import xcb.xcb;
import xcb.render;

extern(C) nothrow @nogc __gshared
{
    cairo_surface_t * function (xcb_connection_t	*connection,
                                xcb_drawable_t	 drawable,
                                xcb_visualtype_t	*visual,
                                int			 width,
                                int			 height)
            cairo_xcb_surface_create;

    cairo_surface_t * function (xcb_connection_t	*connection,
                                xcb_screen_t	*screen,
                                xcb_pixmap_t	 bitmap,
                                int		 width,
                                int		 height)
            cairo_xcb_surface_create_for_bitmap;

    cairo_surface_t * function (xcb_connection_t			*connection,
                                xcb_screen_t			*screen,
                                xcb_drawable_t			 drawable,
                                xcb_render_pictforminfo_t		*format,
                                int				 width,
                                int				 height)
            cairo_xcb_surface_create_with_xrender_format;

    void function (cairo_surface_t *surface,
                   int		     width,
                   int		     height)
            cairo_xcb_surface_set_size;

    void function (cairo_surface_t *surface,
                   xcb_drawable_t	drawable,
                   int		width,
                   int		height)
            cairo_xcb_surface_set_drawable;

    xcb_connection_t * function (cairo_device_t *device)
            cairo_xcb_device_get_connection;


    void function (cairo_device_t *device,
                   int major_version,
                   int minor_version)
            cairo_xcb_device_debug_cap_xshm_version;

    void function (cairo_device_t *device,
                   int major_version,
                   int minor_version)
            cairo_xcb_device_debug_cap_xrender_version;

    void function (cairo_device_t *device,
                   int precision)
            cairo_xcb_device_debug_set_precision;

    int function (cairo_device_t *device)
            cairo_xcb_device_debug_get_precision;
}

