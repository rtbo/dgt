module dgt.vg;

public import dgt.vg.context;
public import dgt.vg.paint;
public import dgt.vg.path;
import dgt.core.resource;
import dgt.geometry;
import dgt.image;

/// A surface to render vector graphics on.
interface VgSurface : RefCounted
{
    /// Vector graphics backend associated with this surface.
    @property VgBackend backend();

    /// The surface size
    @property ISize size() const;

    /// Finalize pending operations before returning.
    void flush();
}

/// A texture contains image data that can be painted onto surfaces.
interface VgTexture : RefCounted
{
    /// The pixel format of the texture
    @property ImageFormat format() const;
    /// Resets the pixels of the texture.
    /// After the call, the texture will have the same size as the image.
    void setPixels(Image pixels);
    /// Update a part of the pixels. The texture size is not updated.
    /// An exception is thrown if one of the size is not compatible.
    void updatePixels(Image pixels, in IRect fromArea, in IRect toArea);
    /// Get a surface to paint into this texture.
    /// Surface.flush must be called to ensure that graphics are transferred
    /// on the texture.
    @property VgSurface surface();
}

/// A vector graphics backend.
/// Has responsibility to instanciate context for a particular surface.
/// There can be several vg backends in use in a living application.
interface VgBackend : Disposable
{
    /// Unique identifier of this backend.
    size_t uid() const;

    /// Human readable name of this backend. Mainly for debugging purpose.
    string name() const;

    /// Check whether the backend uses hardware acceleration.
    bool hardwareAccelerated() const;

    /// Create a context associated with the provided surface.
    /// If the backend do not support the surface, an exception is thrown.
    /// Surface.backend is guaranteed to support the surface it is issued from,
    /// though there could be other backends supporting it.
    VgContext createContext(VgSurface surf);

    /// Create a texture from the provided image.
    /// In case of a software renderer (hardwareAccelerated == false),
    /// the image needs to have same constraints than for Image.makeVgSurface.
    VgTexture createTexture(Image image);
}

/// Create a graphics context associated with a surface.
/// It basically calls $(D_CODE surf.backend.createContext(surf)).
VgContext createContext(VgSurface surf)
{
    return surf.backend.createContext(surf);
}

/// Create a texture to be used on a surface.
/// Shortcut for $(D_CODE surf.backend.createTexture(image)).
VgTexture createTexture(VgSurface surf, Image image)
{
    return surf.backend.createTexture(image);
}
