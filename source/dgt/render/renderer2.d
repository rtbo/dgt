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
    void render(immutable(FGFrame)[] frames)
    in {
        assert(frames.length);
    }
    void finalize(size_t windowHandle);
}

private:

import gfx.core.rc : Rc;
import gfx.decl.engine;
import gfx.graal.device;
import gfx.graal.pipeline;
import gfx.graal.presentation;
import gfx.graal.queue;
import gfx.graal.renderpass;
import gfx.graal.presentation;


class WindowContext
{
    size_t windowHandle;
    private Rc!Surface surface;
    private Rc!Swapchain swapchain;
    private Rc!Device device;

    this (size_t windowHandle, Rc!Device device)
    {
        this.windowHandle = windowHandle;
        this.device = device;
    }
}


class RendererBase : Renderer
{
    private Rc!Instance instance;
    private Rc!PhysicalDevice physicalDevice;
    private Rc!Device device;
    private uint graphicsQueueInd;
    private uint presentQueueInd;
    private Queue graphicsQueue;
    private Queue presentQueue;
    private Surface[size_t] surfaces;
    private DeclarativeEngine declEng;

    private bool initialized;

    this(Instance instance)
    {
        this.instance = instance;
    }

    override @property Backend backend()
    {
        return this.instance.backend;
    }

    private void initialize(Surface surf)
    {
        prepareDevice(surf);
    }

    override void finalize(size_t windowHandle)
    {
        import gfx.core.rc : disposeObject, releaseArray;

        disposeObject(declEng);
        releaseArray(surfaces);
        this.device.unload();
        this.instance.unload();
    }

    abstract Surface makeSurface(size_t windowHandle);

    private Surface getSurface(size_t windowHandle)
    {
        auto s = windowHandle in surfaces;
        if (s) return *s;
        auto surf = makeSurface(windowHandle);
        surf.retain();
        surfaces[windowHandle] = surf;
        return surf;
    }

    override void render(immutable(FGFrame)[] frames)
    {
        if (!initialized) {
            initialize(getSurface(frames[0].windowHandle));
            initialized = true;
        }
    }

    private void prepareDevice(Surface surf)
    {
        import dgt.render.preparation : deviceScore;
        PhysicalDevice chosen;
        int score;
        uint gq, pq;
        foreach (pd; instance.devices) {
            const s = deviceScore(pd, surf, gq, pq);
            if (s > score) {
                score = s;
                chosen = pd;
            }
        }
        physicalDevice = vitalEnforce(
            chosen, "Could not find a suitable graphics device"
        );
        const qr = (gq == pq) ?
                [ QueueRequest(gq, [ 0.5f ]) ] :
                [ QueueRequest(gq, [ 0.5f ]), QueueRequest(pq, [ 0.5f ]) ];
        device = vitalEnforce(
            chosen.open( qr ), "Could not open a suitable graphics device"
        );
        graphicsQueueInd = gq;
        graphicsQueue = device.getQueue(gq, 0);
        presentQueueInd = pq;
        presentQueue = device.getQueue(pq, 0);
    }

    static void frameError(Args...)(string msg, Args args)
    {
        import std.format : format;
        throw new Exception(format(msg, args));
    }

    static void fatalError(Args...)(string msg, Args args)
    {
        import std.format : format;
        throw new Error(format(msg, args));
    }

    static T vitalEnforce(T, Args...)(T expr, string msg, Args args)
    {
        if (!expr) {
            import std.format : format;
            throw new Error(format(msg, args));
        }
        return expr;
    }
}

class VulkanRenderer : RendererBase
{
    this(Instance instance)
    {
        super(instance);
    }

    override Surface makeSurface(size_t windowHandle)
    {
        assert(false, "unimplemented");
    }
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

    override Surface makeSurface(size_t windowHandle)
    {
        import gfx.gl3.swapchain : GlSurface;
        return new GlSurface(windowHandle);
    }

    override void render(immutable(FGFrame)[] frames)
    {
        // At the moment, only make sure that at least the context is current.
        // It can be current on any window, the swapchain dispatches to the correct
        // window during presentation.
        // This is likely to change in the future.
        _context.makeCurrent(frames[0].windowHandle);
        super.render(frames);
    }
}