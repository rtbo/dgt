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

struct SwapchainProps
{
    import gfx.graal.format : Format;

    Format format;
}


final class WindowContext : Disposable
{
    import gfx.core.rc :            Rc;
    import gfx.graal.cmd :          CommandBuffer, CommandPool;
    import gfx.graal.device :       Device;
    import gfx.graal.image :        ImageAspect, ImageBase,
                                    ImageSubresourceRange, ImageType, ImageView,
                                    Swizzle;
    import gfx.graal.presentation : CompositeAlpha, Surface, Swapchain;
    import gfx.graal.queue :        Queue;
    import gfx.graal.renderpass :   Framebuffer, RenderPass;
    import gfx.graal.sync :         Fence, Semaphore;

    private size_t windowHandle;
    private Rc!Surface surface;
    private Rc!Device device;
    private Rc!RenderPass renderPass;
    private Rc!CommandPool pool;
    private Rc!Swapchain swapchain;
    private SwapchainProps scProps;
    private uint[2] size;
    private bool mustRebuildSwapchain;

    private Semaphore imageAvailableSem;
    private Semaphore renderingFinishSem;

    private static struct PerImage
    {
        ImageBase img;
        ImageView view;
        Framebuffer framebuffer;

        this(Device device, RenderPass rp, ImageBase img) {
            const info = img.info;
            this.img = img;
            this.view = img.createView(
                ImageType.d2, ImageSubresourceRange(ImageAspect.color), Swizzle.identity
            );
            this.framebuffer = device.createFramebuffer(rp, [ view ], info.dims.width, info.dims.height, info.layers);
        }
    }
    private PerImage[] images;
    private Fence[] fences;
    private CommandBuffer[] cmdBufs;

    this (size_t windowHandle, Surface surface, Device device,
            RenderPass renderPass, CommandPool cmdPool, SwapchainProps scProps)
    {
        import gfx.core.rc : retainObj;

        this.windowHandle = windowHandle;
        this.surface = surface;
        this.device = device;
        this.pool = cmdPool;
        this.renderPass = renderPass;
        this.scProps = scProps;
        this.imageAvailableSem = retainObj(device.createSemaphore());
        this.renderingFinishSem = retainObj(device.createSemaphore());
    }

    override void dispose()
    {
        import gfx.core.rc : releaseArr, releaseObj;

        assert(fences.length == images.length);
        foreach (i, ref img; images) {
            import gfx.core.rc : releaseObj;
            // img might might still be used in command buffer from previous frame
            fences[i].wait();
            releaseObj(img.view);
            releaseObj(img.framebuffer);
        }
        releaseObj(imageAvailableSem);
        releaseObj(renderingFinishSem);
        releaseArr(fences);
        if (cmdBufs.length) pool.free(cmdBufs);
        pool.unload();
        renderPass.unload();
        surface.unload();
        swapchain.unload();
        device.unload();
    }

    void resizeIfNeeded(in uint[2] newSize)
    {
        import gfx.graal.image : ImageUsage;
        import gfx.graal.presentation : PresentMode;
        import std.algorithm : clamp, map, max;
        import std.array : array;
        import std.exception : enforce;
        import std.experimental.logger : tracef;

        if (swapchain && newSize == size && !mustRebuildSwapchain) return;

        const surfCaps = device.physicalDevice.surfaceCaps(surface);

        CompositeAlpha ca;
        if (surfCaps.supportedAlpha & CompositeAlpha.preMultiplied) {
            ca = CompositeAlpha.preMultiplied;
        }
        else if (surfCaps.supportedAlpha & CompositeAlpha.inherit) {
            ca = CompositeAlpha.inherit;
        }
        else if (surfCaps.supportedAlpha & CompositeAlpha.postMultiplied) {
            ca = CompositeAlpha.postMultiplied;
        }
        else {
            ca = CompositeAlpha.opaque;
        }

        enforce(surfCaps.usage & ImageUsage.transferDst, "TransferDst not supported by surface");
        const numImages = max(2, surfCaps.minImages);
        enforce(surfCaps.maxImages == 0 || surfCaps.maxImages >= numImages);

        uint[2] sz = void;
        static foreach (i; 0..2) {
            sz[i] = clamp(newSize[i], surfCaps.minSize[i], surfCaps.maxSize[i]);
        }

        tracef("creating swapchain for size %s", sz);

        const usage = ImageUsage.colorAttachment;
        const pm = PresentMode.fifo;
        auto sc = device.createSwapchain(surface, pm, numImages, scProps.format, sz, usage, ca, swapchain.obj);

        auto imgs = sc.images
                .map!(ib => PerImage(device, renderPass, ib))
                .array();

        // releasing previous framebuffer (if any)
        assert(fences.length == images.length);
        foreach (i, ref img; images) {
            import gfx.core.rc : releaseObj;
            // img might might still be used in command buffer from previous frame
            fences[i].wait();
            releaseObj(img.view);
            releaseObj(img.framebuffer);
        }
        // building new fences and command buffers if image count is different
        // (also for first use)
        assert(fences.length == cmdBufs.length);
        if (fences.length != imgs.length) {
            import gfx.core.rc : releaseArr, retainArr;
            import std.range : iota;
            import std.typecons : Yes;

            releaseArr(fences);
            fences = iota(imgs.length).map!(i => device.createFence(Yes.signaled)).array();
            retainArr(fences);
            if (cmdBufs.length) pool.free(cmdBufs);
            cmdBufs = pool.allocate(imgs.length);
        }

        foreach (ref img; imgs) {
            import gfx.core.rc : retainObj;
            retainObj(img.view);
            retainObj(img.framebuffer);
        }

        swapchain = sc;
        images = imgs;
        size = sz;
        mustRebuildSwapchain = false;

    }

    uint acquireNextImage() {
        import core.time : dur;
        return swapchain.acquireNextImage(dur!"seconds"(-1), imageAvailableSem, mustRebuildSwapchain);
    }
}


class RendererBase : Renderer
{
    import gfx.core.rc :            Rc;
    import gfx.decl.engine :        DeclarativeEngine;
    import gfx.graal :              Instance;
    import gfx.graal.cmd :          CommandPool;
    import gfx.graal.device :       Device, PhysicalDevice;
    import gfx.graal.presentation : Surface;
    import gfx.graal.queue :        Queue;
    import gfx.graal.renderpass :   RenderPass;
    import gfx.memalloc :           Allocator;

    private Rc!Instance instance;
    private PhysicalDevice physicalDevice;
    private Rc!Device device;
    private uint graphicsQueueInd;
    private uint presentQueueInd;
    private Queue graphicsQueue;
    private Queue presentQueue;
    private DeclarativeEngine declEng;
    private Rc!Allocator allocator;

    private Rc!RenderPass renderPass;
    private Rc!CommandPool graphicsPool;
    private Rc!CommandPool presentPool;

    private SwapchainProps swapchainProps;
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
        prepareSwapchain(surf);
        prepareCommandPools();
        prepareDeclarative();
        // This is just gui, no need for a lot of memory.
        // Lets start with 128kb per allocation.
        // TODO: scan 1st frame and adapt default block size
        prepareAllocator(128 * 1024);
    }

    override void finalize(size_t windowHandle)
    {
        import gfx.core.rc : disposeObj, disposeArr;

        device.waitIdle();

        disposeObj(declEng);
        disposeArr(windows);
        renderPass.unload();
        graphicsPool.unload();
        presentPool.unload();
        allocator.unload();
        device.unload();
        instance.unload();
    }

    abstract Surface makeSurface(size_t windowHandle);

    private WindowContext getWindow(size_t windowHandle)
    {
        foreach (w; windows) {
            if (w.windowHandle == windowHandle) return w;
        }
        auto w = new WindowContext(
            windowHandle, makeSurface(windowHandle), device, renderPass,
            graphicsPool, swapchainProps
        );
        windows ~= w;
        return w;
    }

    // frames is one frame per window, not several frames of the same window at once
    override void render(immutable(FGFrame)[] frames)
    {
        import gfx.core.types : Rect, Viewport;
        import gfx.graal.cmd : ClearColorValues, ClearValues, PipelineStage;
        import gfx.graal.error : OutOfDateException;
        import gfx.graal.queue : PresentRequest, Submission, StageWait;
        import gfx.graal.sync : Semaphore;
        import gfx.math.vec : FVec4;
        import std.algorithm : map;
        import std.array : array;
        import std.typecons : No;

        if (!initialized) {
            import dgt.core.rc : rc;
            const wh = frames[0].windowHandle;
            auto s = makeSurface(wh).rc;
            initialize(s);
            windows ~= new WindowContext(
                wh, s, device, renderPass, graphicsPool, swapchainProps
            );
            initialized = true;
        }

        Semaphore[] waitSems;
        PresentRequest[] prs;
        waitSems.reserve(frames.length);
        prs.reserve(frames.length);

        foreach (frame; frames) {
            auto window = getWindow(frame.windowHandle);
            const vp = frame.viewport;
            window.resizeIfNeeded([ vp.width, vp.height ]);

            uint imgInd;
            try {
                imgInd = window.acquireNextImage();
            }
            catch(OutOfDateException ex) {
                // being resized, and frame.viewport size is out of date
                // will render next one
                window.mustRebuildSwapchain = true;
                continue;
            }
            auto cmdBuf = window.cmdBufs[imgInd];
            auto fence = window.fences[imgInd];
            auto img = window.images[imgInd];

            const wsz = window.size;

            fence.wait();
            fence.reset();

            ClearValues[] cvs = frame.clearColor
                    .map!(c => ClearValues.color(c.r, c.g, c.b, c.a))
                    .array();

            cmdBuf.begin(No.persistent);

            cmdBuf.setViewport(0, [ Viewport(0f, 0f, cast(float)vp.width, cast(float)vp.height) ]);
            cmdBuf.setScissor(0, [ Rect(0, 0, vp.width, vp.height) ]);

            cmdBuf.beginRenderPass(
                renderPass, img.framebuffer, Rect(0, 0, wsz[0], wsz[1]), cvs
            );

            cmdBuf.endRenderPass();

            cmdBuf.end();


            graphicsQueue.submit([
                Submission (
                    [ StageWait(window.imageAvailableSem, PipelineStage.transfer) ],
                    [ window.renderingFinishSem ], [ cmdBuf ]
                )
            ], fence );

            waitSems ~= window.renderingFinishSem;
            prs ~= PresentRequest(window.swapchain.obj, imgInd);
        }

        if (prs.length) presentQueue.present(waitSems, prs);
    }

    private void prepareDevice(Surface surf)
    {
        import dgt.render.preparation : deviceScore;
        import gfx.graal.device : QueueRequest;

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
        declEng.addView!"rectcol.vert.spv"();
        declEng.addView!"rectcol.frag.spv"();
        declEng.addView!"rectimg.vert.spv"();
        declEng.addView!"rectimg.frag.spv"();
        declEng.addView!"text.vert.spv"();
        declEng.addView!"text.frag.spv"();
        declEng.declareStruct!RectColVertex();
        declEng.declareStruct!RectImgVertex();
        declEng.declareStruct!P2T2Vertex();
        declEng.store.store("sc_format", swapchainProps.format);

        const sdl = only(
            import("renderpass.sdl"),
            import("rectcol_pipeline.sdl"),
            import("rectimg_pipeline.sdl"),
            import("text_pipeline.sdl"),
        ).join("\n");

        declEng.parseSDLSource(sdl);

        renderPass = declEng.store.expect!RenderPass("renderPass");
    }

    void prepareCommandPools()
    {
        graphicsPool = device.createCommandPool(graphicsQueueInd);
        if (graphicsQueueInd == presentQueueInd) {
            presentPool = graphicsPool;
        }
        else {
            presentPool = device.createCommandPool(presentQueueInd);
        }
    }

    void prepareAllocator(in size_t blockSize)
    {
        import gfx.memalloc : AllocatorOptions, createAllocator, HeapOptions;
        import std.algorithm : map;
        import std.array : array;

        AllocatorOptions options;

        const memProps = physicalDevice.memoryProperties;
        options.heapOptions = memProps.heaps
                    .map!(h => HeapOptions(uint.max, blockSize))
                    .array();
        allocator = createAllocator(device.obj, options);
    }

    void prepareSwapchain(Surface surface)
    {
        import dgt.render.preparation : chooseFormat;

        const f = chooseFormat(physicalDevice, surface);

        swapchainProps = SwapchainProps(f);
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
    import gfx.graal.presentation : Surface;

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
    import gfx.graal.presentation : Surface;

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