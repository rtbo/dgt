module dgt.vg;

public import dgt.vg.context;
public import dgt.vg.paint;
public import dgt.vg.path;
import dgt.core.resource;
import dgt.geometry;

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
}

/// Create a graphics context associated with a surface.
/// It basically calls $(D_CODE surf.backend.createContext(surf))
VgContext createContext(VgSurface surf)
{
    return surf.backend.createContext(surf);
}
