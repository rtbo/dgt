module dgt.render.renderer2;

import dgt.core.rc : Disposable;
import dgt.render.framegraph;
import gfx.gl3.context : GlContext;
import gfx.graal : Instance, Backend;

/// Creates a renderer with the list of backends supplied.
/// Returns: the first renderer that could be created
/// Params:
///     tryOrder =      The list of backend to try to instantiate
///     appName =       The name of the application (interests Vulkan backend)
///     appVersion =    The version of the application (interests Vulkan backend)
///     context =       A context for the OpenGl backend.
///                     The context is moved to the renderer and should not be
///                     accessed from application afterwards
Renderer createRenderer(in Backend[] tryOrder, lazy string appName,
                        lazy uint[3] appVersion, lazy GlContext context)
{
    Exception ex;
    foreach (backend; tryOrder)
    {
        try {
            if (backend == Backend.vulkan) {
                return createVulkanRenderer(appName, appVersion);
            }
            else if (backend == Backend.gl3) {
                return createOpenGLRenderer(context);
            }
            else {
                assert(false);
            }
        }
        catch(Exception e) {
            ex = e;
        }
    }
    throw ex;
}

/// Creates a Vulkan backed renderer
Renderer createVulkanRenderer(string appName, uint[3] appVersion)
{
    import gfx.vulkan : createVulkanInstance, VulkanVersion;
    return new VulkanRenderer(createVulkanInstance(
        appName, VulkanVersion(appVersion[0], appVersion[1], appVersion[2])
    ));
}

/// Creates an OpenGL backed renderer
/// The context must be current to a window  during initialization time
/// (could be dummy destroyed right after this call).
/// The context is moved to the renderer and should not be accessed by the
/// application afterwards.
Renderer createOpenGLRenderer(GlContext context)
{
    import gfx.gl3 : GlInstance;
    import std.exception : enforce;

    enforce(context.current, "GlContext must be current during OpenGL instance creation");
    auto renderer = new OpenGLRenderer(new GlInstance(context), context);
    context.doneCurrent(); // will be made current again for actual rendering
    return renderer;
}


interface Renderer
{
    @property Backend backend();
    void render(immutable(FGFrame)[] frames);
    void finalize(size_t windowHandle);
}

private:

class VulkanRenderer : RendererBase
{
    this(Instance instance)
    {
        super(instance);
    }

    override void finalize(size_t windowHandle)
    {}
}

class OpenGLRenderer : RendererBase
{
    import dgt.core.rc : Rc;

    Rc!GlContext _context;

    this(Instance instance, GlContext context)
    {
        super(instance);
        _context = context;
    }

    override void finalize(size_t windowHandle)
    {
        _context.makeCurrent(windowHandle);
        super.finalize(windowHandle);
        _context.doneCurrent();
        _context.unload();
    }

    override void render(immutable(FGFrame)[] frames)
    {
        // At the moment, only make sure that at least the context is current.
        // It can be current on any window, the swapchain dispatches to the correct
        // window during presentation.
        // This is likely to change in the future.
        if (frames.length) {
            _context.makeCurrent(frames[0].windowHandle);
        }
        super.render(frames);
    }
}


class RendererBase : Renderer
{
    import dgt.core.rc : Rc;

    private Rc!Instance _instance;
    private bool _initialized;

    this(Instance instance)
    {
        _instance = instance;
    }

    override void finalize(size_t windowHandle)
    {
        _instance.unload();
    }

    override @property Backend backend()
    {
        return _instance.backend;
    }

    private void initialize()
    {

    }

    override void render(immutable(FGFrame)[] frames)
    {
        if (!_initialized) {
            initialize();
        }
    }
}
