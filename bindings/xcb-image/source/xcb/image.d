module xcb.image;

import xcb.xcb;
import xcb.shm;

extern(C) nothrow @nogc:

/**
 * @defgroup xcb__image_t XCB Image Functions
 *
 * These are functions used to create and manipulate X images.
 *
 * The X image format we use is specific to this software,
 * which is probably a bug; it represents an intermediate
 * position between the wire format used by the X GetImage
 * and PutImage requests and standard formats like PBM.  An
 * image consists of a header of type @ref xcb_image_t
 * describing the properties of the image, together with a
 * pointer to the image data itself.
 *
 * X wire images come in three formats.  An xy-bitmap is a
 * bit-packed format that will be expanded to a two-color
 * pixmap using a GC when sent over the wire by PutImage.
 * An xy-pixmap is one or more bit-planes, each in the same
 * format as xy-bitmap.  A z-pixmap is a more conventional
 * pixmap representation, with each pixel packed into a
 * word.  Pixmaps are sent and received over the wire only
 * to/from drawables of their depth.
 *
 * Each X server defines, for each depth and format,
 * properties of images in that format that are sent and
 * received on the wire.  We refer to this as a "native"
 * image for a given X server.  It is not uncommon to want
 * to work with non-native images on the client side, or to
 * convert between the native images of different servers.
 *
 * This library provides several things.  Facilities for
 * creating and destroying images are, of course, provided.
 * Wrappers for xcb_get_image() and xcb_put_image() are
 * provided; these utilize the image header to simplify the
 * interface.  Routines for getting and putting image pixels
 * are provided: both a generic form that works with
 * arbitrary images, and fastpath forms for some common
 * cases.  Conversion routines are provided for X images;
 * these routines have been fairly well optimized for the
 * common cases, and should run fast even on older hardware.
 * A routine analogous to Xlib's XCreate*FromBitmapData() is
 * provided for creating X images from xbm-format data; this
 * routine is in this library only because it is a trivial
 * use case for the library.
 *
 * @{
 */


/**
 * @struct xcb_image_t
 * A structure that describes an xcb_image_t.
 */
struct xcb_image_t
{
  ushort           width;   /**< Width in pixels, excluding pads etc. */
  ushort           height;   /**< Height in pixels. */
  xcb_image_format_t format;   /**< Format. */
  ubyte            scanline_pad;   /**< Right pad in bits.  Valid pads
				      *   are 8, 16, 32.
				      */
  ubyte            depth;   /**< Depth in bits. Valid depths
			       *   are 1, 4, 8, 16, 24 for z format,
			       *   1 for xy-bitmap-format, anything
			       *   for xy-pixmap-format.
			       */
  ubyte            bpp;   /**< Storage per pixel in bits.
			     *   Must be >= depth. Valid bpp
			     *   are 1, 4, 8, 16, 24, 32 for z
			     *   format, 1 for xy-bitmap format,
			     *   anything for xy-pixmap-format.
			     */
  ubyte	     unit;  /**< Scanline unit in bits for
			     *   xy formats and for bpp == 1,
			     *   in which case valid scanline
			     *   units are 8, 16, 32.  Otherwise,
			     *   will be max(8, bpp).  Must be >= bpp.
			     */
  uint           plane_mask;   /**< When format is
				    *   xy-pixmap and depth >
				    *   1, this says which
				    *   planes are "valid" in
				    *   some vague sense.
				    *   Currently used only
				    *   by xcb_image_get/put_pixel(),
				    *   and set only by
				    *   xcb_image_get().
				    */
  xcb_image_order_t  byte_order;   /**< Component byte order
				    *   for z-pixmap, byte
				    *   order of scanline unit
				    *   for xy-bitmap and
				    *   xy-pixmap.  Nybble
				    *   order for z-pixmap
				    *   when bpp == 4.
				    */
  xcb_image_order_t  bit_order;    /**< Bit order of
				    *   scanline unit for
				    *   xy-bitmap and
				    *   xy-pixmap.
				    */
  uint           stride;   /**< Bytes per image row.
				*   Computable from other
				*   data, but cached for
				*   convenience/performance.
				*/
  uint           size;   /**< Size of image data in bytes.
			      *   Computable from other
			      *   data, but cached for
			      *   convenience/performance.
			      */
  void *             base;   /**< Malloced block of storage that
			      *   will be freed by
			      *   @ref xcb_image_destroy() if non-null.
			      */
  ubyte *          data;   /**< The actual image. */
}

/**
 * @struct xcb_shm_segment_info_t
 * A structure that stores the informations needed by the MIT Shm
 * Extension.
 */
struct xcb_shm_segment_info_t
{
  xcb_shm_seg_t shmseg;
  uint    shmid;
  ubyte     *shmaddr;
}


/**
 * Update the cached data of an image.
 * @param image The image.
 *
 * An image's size and stride, among other things, are
 * cached in its structure.  This function recomputes those
 * cached values for the given image.
 * @ingroup xcb__image_t
 */
void
xcb_image_annotate (xcb_image_t *image);

/**
 * Create a new image.
 * @param width The width of the image, in pixels.
 * @param height The height of the image, in pixels.
 * @param format The format of the image.
 * @param xpad The scanline pad of the image.
 * @param depth The depth of the image.
 * @param bpp The depth of the image storage.
 * @param unit The unit of image representation, in bits.
 * @param byte_order The byte order of the image.
 * @param bit_order The bit order of the image.
 * @param base The base address of malloced image data.
 * @param bytes The size in bytes of the storage pointed to by base.
 *              If base == 0 and bytes == ~0 and data == 0 on
 *              entry, no storage will be auto-allocated.
 * @param data The image data.  If data is null and bytes != ~0, then
 *             an attempt will be made to fill in data; from
 *             base if it is non-null (and bytes is large enough), else
 *             by mallocing sufficient storage and filling in base.
 * @return The new image.
 *
 * This function allocates the memory needed for an @ref xcb_image_t structure
 * with the given properties.  See the description of xcb_image_t for details.
 * This function initializes and returns a pointer to the
 * xcb_image_t structure.  It may try to allocate or reserve data for the
 * structure, depending on how @p base, @p bytes and @p data are set.
 *
 * The image must be destroyed with xcb_image_destroy().
 * @ingroup xcb__image_t
 */
xcb_image_t *
xcb_image_create (ushort           width,
		  ushort           height,
		  xcb_image_format_t format,
		  ubyte            xpad,
		  ubyte            depth,
		  ubyte            bpp,
		  ubyte            unit,
		  xcb_image_order_t  byte_order,
		  xcb_image_order_t  bit_order,
		  void *             base,
		  uint           bytes,
		  ubyte *          data);


/**
 * Create a new image in connection-native format.
 * @param c The connection.
 * @param width The width of the image, in pixels.
 * @param height The height of the image, in pixels.
 * @param format The format of the image.
 * @param depth The depth of the image.
 * @param base The base address of malloced image data.
 * @param bytes The size in bytes of the storage pointed to by base.
 *              If base == 0 and bytes == ~0 and data == 0 on
 *              entry, no storage will be auto-allocated.
 * @param data The image data.  If data is null and bytes != ~0, then
 *             an attempt will be made to fill in data; from
 *             base if it is non-null (and bytes is large enough), else
 *             by mallocing sufficient storage and filling in base.
 * @return The new image.
 *
 * This function calls @ref xcb_image_create() with the given
 * properties, and with the remaining properties chosen
 * according to the "native format" with the given
 * properties on the current connection.
 *
 * It is usual to use this rather
 * than calling xcb_image_create() directly.
 * @ingroup xcb__image_t
 */
xcb_image_t *
xcb_image_create_native (xcb_connection_t *  c,
			 ushort            width,
			 ushort            height,
			 xcb_image_format_t  format,
			 ubyte             depth,
			 void *              base,
			 uint            bytes,
			 ubyte *           data);


/**
 * Destroy an image.
 * @param image The image to be destroyed.
 *
 * This function frees the memory associated with the @p image
 * parameter.  If its base pointer is non-null, it frees
 * that also.
 * @ingroup xcb__image_t
 */
void
xcb_image_destroy (xcb_image_t *image);


/**
 * Get an image from the X server.
 * @param conn The connection to the X server.
 * @param draw The drawable to get the image from.
 * @param x The x coordinate in pixels, relative to the origin of the
 * drawable and defining the upper-left corner of the rectangle.
 * @param y The y coordinate in pixels, relative to the origin of the
 * drawable and defining the upper-left corner of the rectangle.
 * @param width The width of the subimage in pixels.
 * @param height The height of the subimage in pixels.
 * @param plane_mask The plane mask.  See the protocol document for details.
 * @param format The format of the image.
 * @return The subimage of @p draw defined by @p x, @p y, @p w, @p h.
 *

 * This function returns a new image taken from the
 * given drawable @p draw.
 * The image will be in connection native format. If the @p format
 * is xy-bitmap and the @p plane_mask masks bit planes out, those
 * bit planes will be made part of the returned image anyway,
 * by zero-filling them; this will require a fresh memory allocation
 * and some copying.  Otherwise, the resulting image will use the
 * xcb_get_image_reply() record as its backing store.
 *
 * If a problem occurs, the function returns null.
 * @ingroup xcb__image_t
 */
xcb_image_t *
xcb_image_get (xcb_connection_t *  conn,
	       xcb_drawable_t      draw,
	       short             x,
	       short             y,
	       ushort            width,
	       ushort            height,
	       uint            plane_mask,
	       xcb_image_format_t  format);


/**
 * Put an image onto the X server.
 * @param conn The connection to the X server.
 * @param draw The draw you get the image from.
 * @param gc The graphic context.
 * @param image The image you want to combine with the rectangle.
 * @param x The x coordinate, which is relative to the origin of the
 * drawable and defines the x coordinate of the upper-left corner of the
 * rectangle.
 * @param y The y coordinate, which is relative to the origin of the
 * drawable and defines the x coordinate of the upper-left corner of
 * the rectangle.
 * @param left_pad Notionally shift an xy-bitmap or xy-pixmap image
 * to the right some small amount, for some reason.  XXX Not clear
 * this is currently supported correctly.
 * @return The cookie returned by xcb_put_image().
 *
 * This function combines an image with a rectangle of the
 * specified drawable @p draw. The image must be in native
 * format for the connection.  The image is drawn at the
 * specified location in the drawable. For the xy-bitmap
 * format, the foreground pixel in @p gc defines the source
 * for the one bits in the image, and the background pixel
 * defines the source for the zero bits. For xy-pixmap and
 * z-pixmap formats, the depth of the image must match the
 * depth of the drawable; the gc is ignored.
 *
 * @ingroup xcb__image_t
 */
xcb_void_cookie_t
xcb_image_put (xcb_connection_t *  conn,
	       xcb_drawable_t      draw,
	       xcb_gcontext_t      gc,
	       xcb_image_t *       image,
	       short             x,
	       short             y,
	       ubyte             left_pad);


/**
 * Check image for or convert image to native format.
 * @param c The connection to the X server.
 * @param image The image.
 * @param convert  If 0, just check the image for native format.
 * Otherwise, actually convert it.
 * @return Null if the image is not in native format and can or will not
 * be converted.  Otherwise, the native format image.
 *
 * Each X display has its own "native format" for images of a given
 * format and depth.  This function either checks whether the given
 * @p image is in native format for the given connection @p c, or
 * actually tries to convert the image to native format, depending
 * on whether @p convert is true or false.
 *
 * When @p convert is true, and the image is not in native format
 * but can be converted, it will be, and a pointer to the new image
 * will be returned.  The image passed in will be unharmed in this
 * case; it is the caller's responsibility to check that the returned
 * pointer is different and to dispose of the old image if desired.
 * @ingroup xcb__image_t
 */
xcb_image_t *
xcb_image_native (xcb_connection_t *  c,
		  xcb_image_t *       image,
		  int                 convert);


/**
 * Put a pixel to an image.
 * @param image The image.
 * @param x The x coordinate of the pixel.
 * @param y The y coordinate of the pixel.
 * @param pixel The new pixel value.
 *
 * This function overwrites the pixel in the given @p image with the
 * specified @p pixel value (in client format). The image must contain the @p x
 * and @p y coordinates, as no clipping is done.  This function honors
 * the plane-mask for xy-pixmap images.
 * @ingroup xcb__image_t
 */
void
xcb_image_put_pixel (xcb_image_t *image,
		     uint x,
		     uint y,
		     uint pixel);

/**
 * Get a pixel from an image.
 * @param image The image.
 * @param x The x coordinate of the pixel.
 * @param y The y coordinate of the pixel.
 * @return The pixel value.
 *
 * This function retrieves a pixel from the given @p image.
 * The image must contain the @p x
 * and @p y coordinates, as no clipping is done.  This function honors
 * the plane-mask for xy-pixmap images.
 * @ingroup xcb__image_t
 */
uint
xcb_image_get_pixel (xcb_image_t *image,
		     uint x,
		     uint y);


/**
 * Convert an image to a new format.
 * @param src Source image.
 * @param dst Destination image.
 * @return The @p dst image, or null on error.
 *
 * This function tries to convert the image data of the @p
 * src image to the format implied by the @p dst image,
 * overwriting the current destination image data.
 * The source and destination must have the same
 * width, height, and depth.  When the source and destination
 * are already the same format, a simple copy is done.  Otherwise,
 * when the destination has the same bits-per-pixel/scanline-unit
 * as the source, an optimized copy routine (thanks to Keith Packard)
 * is used for the conversion.  Otherwise, the copy is done the
 * slow, slow way with @ref xcb_image_get_pixel() and
 * @ref xcb_image_put_pixel() calls.
 * @ingroup xcb__image_t
 */
xcb_image_t *
xcb_image_convert (xcb_image_t *  src,
		   xcb_image_t *  dst);


/**
 * Extract a subimage of an image.
 * @param image Source image.
 * @param x X coordinate of subimage.
 * @param y Y coordinate of subimage.
 * @param width Width of subimage.
 * @param height Height of subimage.
 * @param base Base of memory allocation.
 * @param bytes Size of base allocation.
 * @param data Memory allocation.
 * @return The subimage, or null on error.
 *
 * Given an image, this function extracts the subimage at the
 * given coordinates.  The requested subimage must be entirely
 * contained in the source @p image.  The resulting image will have the same
 * general image parameters as the source image.  The @p base, @p bytes,
 * and @p data arguments are passed to @ref xcb_create_image() unaltered
 * to create the destination image---see its documentation for details.
 *
 * @ingroup xcb__image_t
 */
xcb_image_t *
xcb_image_subimage(xcb_image_t *  image,
		   uint       x,
		   uint       y,
		   uint       width,
		   uint       height,
		   void *         base,
		   uint       bytes,
		   ubyte *      data);


/*
 * Shm stuff
 */

/**
 * Put the data of an xcb_image_t onto a drawable using the MIT Shm
 * Extension.
 * @param conn The connection to the X server.
 * @param draw The draw you get the image from.
 * @param gc The graphic context.
 * @param image The image you want to combine with the rectangle.
 * @param shminfo A @ref xcb_shm_segment_info_t structure.
 * @param src_x The offset in x from the left edge of the image
 * defined by the xcb_image_t structure.
 * @param src_y The offset in y from the left edge of the image
 * defined by the xcb_image_t structure.
 * @param dest_x The x coordinate, which is relative to the origin of the
 * drawable and defines the x coordinate of the upper-left corner of the
 * rectangle.
 * @param dest_y The y coordinate, which is relative to the origin of the
 * drawable and defines the x coordinate of the upper-left corner of
 * the rectangle.
 * @param src_width The width of the subimage, in pixels.
 * @param src_height The height of the subimage, in pixels.
 * @param send_event Indicates whether or not a completion event
 * should occur when the image write is complete.
 * @return a pointer to the source image if no problem occurs, otherwise 0.
 *
 * This function combines an image in memory with a shape of the
 * specified drawable. The section of the image defined by the @p x, @p y,
 * @p width, and @p height arguments is drawn on the specified part of
 * the drawable. If XYBitmap format is used, the depth must be
 * one, or a``BadMatch'' error results. The foreground pixel in the
 * Graphic Context @p gc defines the source for the one bits in the
 * image, and the background pixel defines the source for the zero
 * bits. For XYPixmap and ZPixmap, the depth must match the depth of
 * the drawable, or a ``BadMatch'' error results.
 *
 * @ingroup xcb__image_t
 */
xcb_image_t *
xcb_image_shm_put (xcb_connection_t *      conn,
		   xcb_drawable_t          draw,
		   xcb_gcontext_t          gc,
		   xcb_image_t *           image,
		   xcb_shm_segment_info_t  shminfo,
		   short                 src_x,
		   short                 src_y,
		   short                 dest_x,
		   short                 dest_y,
		   ushort                src_width,
		   ushort                src_height,
		   ubyte                 send_event);


/**
 * Read image data into a shared memory xcb_image_t.
 * @param conn The connection to the X server.
 * @param draw The draw you get the image from.
 * @param image The image you want to combine with the rectangle.
 * @param shminfo A @ref xcb_shm_segment_info_t structure.
 * @param x The x coordinate, which are relative to the origin of the
 * drawable and define the upper-left corner of the rectangle.
 * @param y The y coordinate, which are relative to the origin of the
 * drawable and define the upper-left corner of the rectangle.
 * @param plane_mask The plane mask.
 * @return The subimage of @p draw defined by @p x, @p y, @p w, @p h.
 *
 * This function reads image data into a shared memory xcb_image_t where
 * @p conn is the connection to the X server, @p draw is the source
 * drawable, @p image is the destination xcb_image_t, @p x and @p y are offsets
 * within the drawable, and @p plane_mask defines which planes are to be
 * read.
 *
 * If a problem occurs, the function returns @c 0. It returns 1
 * otherwise.
 * @ingroup xcb__image_t
 */
int xcb_image_shm_get (xcb_connection_t *      conn,
		       xcb_drawable_t          draw,
		       xcb_image_t *           image,
		       xcb_shm_segment_info_t  shminfo,
		       short                 x,
		       short                 y,
		       uint                plane_mask);


/**
 * Create an image from user-supplied bitmap data.
 * @param data Image data in packed bitmap format.
 * @param width Width in bits of image data.
 * @param height Height in bits of image data.
 * @return The image constructed from the image data, or 0 on error.
 *
 * This function creates an image from the user-supplied
 * bitmap @p data.  The bitmap data is assumed to be in
 * xbm format (i.e., 8-bit scanline unit, LSB-first, 8-bit pad).
 * @ingroup xcb__image_t
 */
xcb_image_t *
xcb_image_create_from_bitmap_data (ubyte *           data,
				   uint            width,
				   uint            height);

/**
 * Create a pixmap from user-supplied bitmap data.
 * @param display The connection to the X server.
 * @param d The parent drawable for the pixmap.
 * @param data Image data in packed bitmap format.
 * @param width Width in bits of image data.
 * @param height Height in bits of image data.
 * @param depth Depth of the desired pixmap.
 * @param fg Pixel for one-bits of pixmaps with depth larger than one.
 * @param bg Pixel for zero-bits of pixmaps with depth larger than one.
 * @param gcp If this pointer is non-null, the GC created to
 * fill in the pixmap is stored here; it will have its foreground
 * and background set to the supplied value.  Otherwise, the GC
 * will be freed.
 * @return The pixmap constructed from the image data, or 0 on error.
 *
 * This function creates a pixmap from the user-supplied
 * bitmap @p data.  The bitmap data is assumed to be in
 * xbm format (i.e., 8-bit scanline unit, LSB-first, 8-bit pad).
 * If @p depth is greater than 1, the
 * bitmap will be expanded to a pixmap using the given
 * foreground and background pixels @p fg and @p bg.
 * @ingroup xcb__image_t
 */
xcb_pixmap_t
xcb_create_pixmap_from_bitmap_data (xcb_connection_t *  display,
				    xcb_drawable_t      d,
				    ubyte *           data,
				    uint            width,
				    uint            height,
				    uint            depth,
				    uint            fg,
				    uint            bg,
				    xcb_gcontext_t *    gcp);
