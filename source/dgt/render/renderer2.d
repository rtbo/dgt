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
            import std.experimental.logger : warningf;
            warningf("Failed to create %s backend: %s", backend, e.msg);
            ex = e;
        }
    }
    throw ex;
}

/// Creates a Vulkan backed renderer
Renderer createVulkanRenderer(string appName, uint[3] appVersion)
{
    import dgt.application : Application;
    import gfx.vulkan : createVulkanInstance, lunarGValidationLayers, vulkanInit,
                        vulkanInstanceExtensions, vulkanInstanceLayers,
                        VulkanVersion;
    import std.algorithm : canFind, filter, map;
    import std.array : array;

    vulkanInit();

    // TODO: make this feasible without Application and Platform
    const necessaryExtensions = Application.platform.necessaryVulkanExtensions;

    debug {
        const wantedLayers = lunarGValidationLayers;
        const wantedExts = [ "VK_KHR_debug_report", "VK_EXT_debug_report" ];
    }
    else {
        const string[] wantedLayers = [];
        const string[] wantedExts = [];
    }

    const requestedLayers = vulkanInstanceLayers
            .map!(l => l.layerName)
            .filter!(l => wantedLayers.canFind(l))
            .array();
    const requestedExtensions = vulkanInstanceExtensions
            .map!(e => e.extensionName)
            .filter!(e => wantedExts.canFind(e))
            .array()
            ~ necessaryExtensions;

    const vv = VulkanVersion(appVersion[0], appVersion[1], appVersion[2]);

    return new VulkanRenderer(createVulkanInstance(
        requestedLayers, requestedExtensions, appName, vv
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


class WindowContext : Disposable
{
    private size_t windowHandle;
    private Rc!Surface surface;
    private Rc!Device device;
    private Rc!Swapchain swapchain;

    this (size_t windowHandle, Surface surface, Device device)
    {
        this.windowHandle = windowHandle;
        this.surface = surface;
        this.device = device;
    }

    override void dispose()
    {
        surface.unload();
        swapchain.unload();
        device.unload();
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
    private DeclarativeEngine declEng;

    private WindowContext[] windows;

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
        import gfx.core.rc : disposeObj, disposeArr;

        disposeObj(declEng);
        disposeArr(windows);
        device.unload();
        physicalDevice.unload();
        instance.unload();
    }

    abstract Surface makeSurface(size_t windowHandle);

    private WindowContext getWindow(size_t windowHandle)
    {
        foreach (w; windows) {
            if (w.windowHandle == windowHandle) return w;
        }
        auto w = new WindowContext(windowHandle, makeSurface(windowHandle), device);
        windows ~= w;
        return w;
    }

    override void render(immutable(FGFrame)[] frames)
    {
        if (!initialized) {
            import dgt.core.rc : rc;
            const wh = frames[0].windowHandle;
            auto s = makeSurface(wh).rc;
            initialize(s);
            initialized = true;
            windows ~= new WindowContext(wh, s, device);
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

    private void prepareDeclarative()
    {
        import dgt.render.rect2 : RectColVertex, RectImgVertex;
        import dgt.render.defs : P2T2Vertex;
        import std.array : join;
        import std.range : only;

        declEng = new DeclarativeEngine(device);
        declEng.addView!"rectcol_pipeline.sdl"();
        declEng.addView!"rectcol.vert.spv"();
        declEng.addView!"rectcol.frag.spv"();
        declEng.addView!"rectimg_pipeline.sdl"();
        declEng.addView!"rectimg.vert.spv"();
        declEng.addView!"rectimg.frag.spv"();
        declEng.addView!"text_pipeline.sdl"();
        declEng.addView!"text.vert.spv"();
        declEng.addView!"text.frag.spv"();
        declEng.declareStruct!RectColVertex();
        declEng.declareStruct!RectImgVertex();
        declEng.declareStruct!P2T2Vertex();

        const sdl = only(
            import("renderpass.sdl"),
            import("rectcol_pipeline.sdl"),
            import("rectimg_pipeline.sdl"),
            import("text_pipeline.sdl"),
        ).join("\n");

        declEng.parseSDLSource(sdl);
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
        // TODO: make this work without Application and Platform
        import dgt.application : Application;
        return Application.platform.createGraalSurface(instance, windowHandle);
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