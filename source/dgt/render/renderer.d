module dgt.render.renderer;

import dgt.core.rc : Disposable;
import dgt.render : dgtRenderTag;
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
            import gfx.core.log : warningf;
            warningf(dgtRenderTag, "Failed to create %s backend: %s", backend, e.msg);
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

class RenderContext
{
    import dgt.render.cache : RenderCache;
    import gfx.graal.device : Device;
    import gfx.math : FMat4;

    RenderCache cache;
    FMat4 viewProj;


    this (RenderCache cache, in FMat4 viewProj)
    {
        this.cache = cache;
        this.viewProj = viewProj;
    }
}

/// Renderer for a type of node
interface FGNodeRenderer : Disposable
{
    import dgt.render.framegraph : FGType;
    import dgt.render.services : RenderServices;
    import gfx.decl.engine : DeclarativeEngine;
    import gfx.graal.device : Device;
    import gfx.graal.cmd : CommandBuffer;
    import gfx.graal.pipeline : DescriptorPool;
    import gfx.memalloc : Allocator;
    import gfx.math : FMat4;

    FGType type() const;

    /// called once during preparation step
    void prepare(RenderServices services, DeclarativeEngine declEng, CommandBuffer cmd);
    /// called during prerender step for each node that fits type
    void prerender(immutable(FGNode) node);
    /// called once per frame to finalize the prerender step
    void prerenderEnd(CommandBuffer cmd);
    /// perform actual rendering
    void render(immutable(FGNode) node, RenderContext ctx, in FMat4 model, CommandBuffer cmd);
    /// called once per frame after rendering all nodes
    void postrender();
}


private:


class RendererBase : Renderer
{
    import dgt.render.cache :       RenderCache;
    import dgt.render.rect :        RectRenderer;
    import dgt.render.services :    RenderServices;
    import dgt.render.text :        TextRenderer;
    import gfx.core.rc :            Rc;
    import gfx.decl.engine :        DeclarativeEngine;
    import gfx.graal :              Instance;
    import gfx.graal.cmd :          CommandBuffer, CommandPool;
    import gfx.graal.device :       Device, PhysicalDevice;
    import gfx.graal.pipeline :     DescriptorPool;
    import gfx.graal.presentation : Surface;
    import gfx.graal.queue :        Queue;
    import gfx.graal.renderpass :   RenderPass;
    import gfx.graal.sync :         Fence;
    import gfx.math.mat :           FMat4;
    import gfx.memalloc :           Allocator, BufferAlloc;

    private Rc!Instance instance;
    private PhysicalDevice physicalDevice;
    private Rc!Device device;
    private uint graphicsQueueInd;
    private uint presentQueueInd;
    private Queue graphicsQueue;
    private Queue presentQueue;
    private DeclarativeEngine declEng;
    private Rc!Allocator allocator;
    private Rc!RenderServices services;

    private Rc!RenderPass renderPass;
    private Rc!CommandPool prerenderPool;
    private Rc!CommandPool graphicsPool;
    private Rc!CommandPool presentPool;
    private CommandBuffer[] prerenderCmds;
    private Fence[] prerenderFences;
    private size_t prerenderCmdInd;

    private SwapchainProps swapchainProps;
    private WindowContext[] windows;

    private RenderCache cache;
    private Rc!DescriptorPool descPool;
    private FGNodeRenderer[] dgtRenderers;
    private FGNodeRenderer[] userRenderers;
    private bool initialized;

    this(Instance instance)
    {
        this.instance = instance;
        this.cache = new RenderCache;
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
        prepareRenderers();

        debug {
            import gfx.graal : Severity;
            instance.setDebugCallback((Severity sev, string msg) {
                import gfx.core.log : errorf, warningf;
                import std.stdio : writefln;

                if (sev == Severity.warning) {
                    warningf(dgtRenderTag, "Gfx backend message: %s", msg);
                }
                else if (sev == Severity.error) {
                    errorf(dgtRenderTag, "Gfx backend message: %s", msg);
                    // debug break;
                    asm { int 0x03; }
                }
            });
        }
    }

    override void finalize(size_t windowHandle)
    {
        import gfx.core.rc : disposeObj, disposeArr, releaseArr;
        import gfx.core.log : trace;
        trace(dgtRenderTag, "finalizing renderer");

        device.waitIdle();

        disposeArr(dgtRenderers);
        disposeArr(userRenderers);
        descPool.unload();
        disposeObj(cache);
        disposeObj(declEng);
        disposeArr(windows);
        renderPass.unload();
        if (prerenderCmds.length) prerenderPool.free(prerenderCmds);
        releaseArr(prerenderFences);
        prerenderPool.unload();
        graphicsPool.unload();
        presentPool.unload();

        services.unload();
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

    void prerender(immutable(FGFrame)[] frames)
    {
        import gfx.graal.buffer : BufferUsage;
        import gfx.graal.queue : Submission;
        import gfx.memalloc : AllocOptions, MemoryUsage;
        import dgt.render.framegraph : breadthFirst, FGNode, FGTypeCat;
        import std.algorithm : each;
        import std.range : chain;
        import std.typecons : No, scoped, Yes;

        foreach (frame; frames) {
            foreach(immutable n; breadthFirst(frame.root))
            {
                enum userRender = FGTypeCat.render | FGTypeCat.user;
                enum dgtRender = FGTypeCat.render;
                const ind = n.type.index;

                if ((n.type.cat & userRender) == userRender) {
                    userRenderers[ind].prerender(n);
                }
                else if ((n.type.cat & dgtRender) == dgtRender) {
                    dgtRenderers[ind].prerender(n);
                }
            }
        }

        enum numPrerenderCmds = 4;

        prerenderCmdInd++;
        if (prerenderCmdInd == numPrerenderCmds) prerenderCmdInd = 0;

        if (!prerenderCmds.length) {
            import gfx.core.rc : retainArr;
            import std.algorithm : map;
            import std.array : array;
            import std.range : iota;
            prerenderCmds = prerenderPool.allocate(numPrerenderCmds);
            prerenderFences = iota(numPrerenderCmds).map!(i => device.createFence(Yes.signaled)).array();
            retainArr(prerenderFences);
            prerenderCmdInd = 0;
        }

        auto prerenderCmd = prerenderCmds[prerenderCmdInd];
        auto f = prerenderFences[prerenderCmdInd];
        f.wait();
        f.reset();

        prerenderCmd.begin(No.persistent);

        foreach (r; chain(dgtRenderers, userRenderers))
            r.prerenderEnd(prerenderCmd);

        prerenderCmd.end();

        graphicsQueue.submit([ Submission ( [], [],  [ prerenderCmd ] ) ], f );
    }

    // frames is one frame per window, not several frames of the same window at once
    override void render(immutable(FGFrame)[] frames)
    {
        import dgt.core.future;
        import dgt.core.geometry : FRect;
        import gfx.core.log : tracef;
        import gfx.graal.cmd : ClearColorValues, ClearValues, PipelineStage;
        import gfx.graal.error : OutOfDateException;
        import gfx.graal.queue : PresentRequest, Submission, StageWait;
        import gfx.graal.sync : Semaphore;
        import gfx.graal.types : Rect, Viewport;
        import gfx.math.vec : FVec4;
        import std.algorithm : map;
        import std.array : array;
        import std.range : chain;
        import std.typecons : No, scoped;

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

        scope(exit) {
            services.incrFrameNum();
        }

        tracef(dgtRenderTag, "rendering frame %s", services.frameNum);

        // TODO: retained mode for gl3 such as only queue submission
        // and presentation are required on the same thread
        Future!void prerenderFuture;

        if (backend == Backend.gl3) {
            auto t = task(&prerender);
            prerenderFuture = t.future;
            t.call(frames);
        }
        else {
            prerenderFuture = async(&prerender, frames);
        }

        Semaphore[] waitSems;
        PresentRequest[] prs;
        waitSems.reserve(frames.length);
        prs.reserve(frames.length);

        foreach (fi, frame; frames) {

            auto window = getWindow(frame.windowHandle);

            const vp = frame.viewport;
            const vpf = cast(FRect)vp;
            window.resizeIfNeeded([ vp.width, vp.height ]);

            uint imgInd;
            try {
                imgInd = window.acquireNextImage();
            }
            catch(OutOfDateException ex) {
                // being resized, and frame.viewport size is out of date
                // will render next one
                window.mustRebuildSwapchain = true;
                if (fi == 0) prerenderFuture.resolve();
                continue;
            }
            auto cmd = window.cmdBufs[imgInd];
            auto fence = window.fences[imgInd];
            auto img = window.images[imgInd];

            const wsz = window.size;

            fence.wait();
            fence.reset();

            ClearValues[] cvs = frame.clearColor
                    .map!(c => ClearValues.color(c.r, c.g, c.b, c.a))
                    .array();

            cmd.begin(No.persistent);

            cmd.setViewport(0, [ Viewport(0f, 0f, vpf.width, vpf.height) ]);
            cmd.setScissor(0, [ Rect(0, 0, vp.width, vp.height) ]);

            cmd.beginRenderPass(
                renderPass, img.framebuffer, Rect(0, 0, wsz[0], wsz[1]), cvs
            );

            if (fi == 0) prerenderFuture.resolve();

            if (frame.root) {
                import gfx.math.proj : ortho;
                const viewProj = ortho(vpf.left, vpf.right, vpf.bottom, vpf.top, 1, -1);
                auto ctx = scoped!RenderContext(cache, viewProj);
                renderNode(frame.root, ctx, FMat4.identity, cmd);
                foreach (r; chain(dgtRenderers, userRenderers))
                    r.postrender();
            }

            cmd.endRenderPass();

            cmd.end();


            graphicsQueue.submit([
                Submission (
                    [ StageWait(window.imageAvailableSem, PipelineStage.transfer) ],
                    [ window.renderingFinishSem ], [ cmd ]
                )
            ], fence );

            waitSems ~= window.renderingFinishSem;
            prs ~= PresentRequest(window.swapchain.obj, imgInd);
        }

        if (prs.length) presentQueue.present(waitSems, prs);
    }

    private void renderNode(immutable(FGNode) node, RenderContext ctx, in FMat4 model, CommandBuffer cmd)
    {
        import std.algorithm : each;

        if (node.type.cat == FGTypeCat.meta) {
            const t = node.type.asMeta;
            if (t == FGMetaType.group) {
                immutable gn = cast(immutable(FGGroupNode))node;
                gn.children.each!(n => renderNode(n, ctx, model, cmd));
            }
            else if (t == FGMetaType.transform) {
                immutable tn = cast(immutable(FGTransformNode))node;
                renderNode(tn.child, ctx, model*tn.transform, cmd);
            }
        }
        else {
            enum userRender = FGTypeCat.render | FGTypeCat.user;
            enum dgtRender = FGTypeCat.render;
            const ind = node.type.index;

            if ((node.type.cat & userRender) == userRender) {
                userRenderers[ind].render(node, ctx, model, cmd);
            }
            else if ((node.type.cat & dgtRender) == dgtRender) {
                dgtRenderers[ind].render(node, ctx, model, cmd);
            }
        }
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
        import dgt.render.defs : P2T2Vertex;

        declEng = new DeclarativeEngine(device);
        declEng.declareStruct!P2T2Vertex();
        declEng.store.store("sc_format", swapchainProps.format);

        declEng.parseSDLView!"renderpass.sdl"();

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
        prerenderPool = device.createCommandPool(graphicsQueueInd);
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

    void prepareRenderers()
    {
        import dgt.render.framegraph : FGRenderType;
        import gfx.graal.pipeline : DescriptorPoolSize, DescriptorType;
        import std.range : chain;
        import std.typecons : scoped;

        services = new RenderServices(graphicsQueue, graphicsPool, allocator);

        dgtRenderers = new FGNodeRenderer[FGRenderType.max + 1];

        void addRenderer(FGNodeRenderer nr) {
            dgtRenderers[nr.type.index] = nr;
        }
        addRenderer(new RectRenderer);
        addRenderer(new TextRenderer);

        auto autoCmd = services.autoCmd();

        foreach (nr; chain(dgtRenderers, userRenderers)) {
            nr.prepare(services, declEng, autoCmd.cmd);
        }
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
        import gfx.core.log : tracef;

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

        tracef(dgtRenderTag, "creating swapchain for size %s", sz);

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
