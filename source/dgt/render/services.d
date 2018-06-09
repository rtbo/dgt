/// Rendering services module
/// Set of utilities to help rendering
module dgt.render.services;

import gfx.core.rc : AtomicRefCounted;
import gfx.core.typecons : Trans;
import gfx.graal.buffer : Buffer;
import gfx.graal.cmd : Access, CommandBuffer, PipelineStage;
import gfx.graal.image : Image, ImageAspect, ImageLayout, ImageSubresourceRange;
import gfx.memalloc : BufferAlloc;

/// General services helper for the rendering of framegraph nodes. Provides:
///     - reference to device, graphics queue and allocator
///     - a garbage collector that keep the collected resources around for
///       a predefined number of frames.
///     - a staging buffer service for optimal images.
///     - a RAII command buffer service
final class RenderServices : AtomicRefCounted
{
    import gfx.core.rc : atomicRcCode;
    import gfx.graal.cmd : CommandPool;
    import gfx.graal.device : Device;
    import gfx.graal.queue : Queue;
    import gfx.memalloc : Allocator;

    mixin(atomicRcCode);

    private Device _device;
    private Queue _queue;
    private CommandPool _pool;
    private Allocator _allocator;

    private size_t _frameNum;
    private size_t _maxGcAge = 2;
    private Garbage _gcFirst;
    private Garbage _gcLast;

    this (Queue queue, CommandPool pool, Allocator allocator)
    {
        import gfx.core.rc : retainObj;

        _device = retainObj(queue.device);
        _queue = queue;
        _pool = retainObj(pool);
        _allocator = retainObj(allocator);
    }

    override void dispose()
    {
        import gfx.core.rc : releaseObj;

        while(_gcFirst) {
            releaseObj(_gcFirst.obj);
            _gcFirst = _gcFirst.next;
        }

        releaseObj(_allocator);
        releaseObj(_pool);
        releaseObj(_device);
    }

    /// The device associated to services
    @property Device device() {
        return _device;
    }

    /// A memory allocator
    @property Allocator allocator() {
        return _allocator;
    }

    /// The graphics queue
    @property Queue queue() {
        return _queue;
    }

    /// Returns a RAII command buffer that will be submitted to a queue when it
    /// goes out of scope
    auto autoCmd()
    {
        return AutoCmdBuf(_queue, _pool);
    }

    /// Stage the provided data to an image
    /// Use this to fill data to images with optimal layout, or residing in device local memory.
    /// image layout will be set to transferDstOptimal if currentLayout is not transferDstOptimal.
    void stageDataToImage(CommandBuffer cmd, Image image, ImageAspect aspect,
                          ImageLayout currentLayout, const(void)[] data)
    {
        import gfx.core.rc : rc;
        import gfx.graal.buffer : BufferUsage;
        import gfx.graal.cmd : BufferImageCopy;
        import gfx.memalloc : AllocOptions, MemoryUsage;

        if (currentLayout != ImageLayout.transferDstOptimal) {
            setImageLayout(
                cmd, image, aspect, currentLayout, ImageLayout.transferDstOptimal
            );
        }

        auto stagBuf = _allocator.allocateBuffer(
            BufferUsage.transferSrc, data.length,
            AllocOptions.forUsage(MemoryUsage.cpuToGpu)
        ).rc;

        {
            auto map = stagBuf.map();
            map[] = data;
        }

        const info = image.info;

        BufferImageCopy region;
        region.extent = [info.dims.width, info.dims.height, info.dims.depth];

        cmd.copyBufferToImage(
            stagBuf.buffer, image, ImageLayout.transferDstOptimal,
            (&region)[0 .. 1]
        );

        gc(stagBuf.obj);
    }

    /// Stage the provided data to offset bytes from start of buffer.
    /// Buffer must be already bound to device local memory.
    /// The function setup the transfer via an intermediate stage buffer or directly
    /// whether the bound memory is host visible or not.
    void stageDataToBuffer(CommandBuffer cmd, BufferAlloc buffer, size_t offset, const(void)[] data)
    {
        import gfx.core.rc : rc;
        import gfx.core.typecons : trans;
        import gfx.graal.buffer : BufferUsage;
        import gfx.graal.cmd : CopyRegion;
        import gfx.graal.memory : MemProps;
        import gfx.memalloc : AllocOptions, MemoryUsage;

        if (buffer.mem.props & MemProps.hostVisible) {
            auto mm = buffer.map(offset, data.length);
            mm[] = data;
        }
        else {
            auto stagBuf = _allocator.allocateBuffer(
                BufferUsage.transferSrc, data.length,
                AllocOptions.forUsage(MemoryUsage.cpuToGpu)
            ).rc;

            {
                auto mm = stagBuf.map();
                mm[] = data;
            }

            const reg = CopyRegion(trans(0, offset), data.length);
            cmd.copyBuffer(trans(stagBuf.buffer, buffer.buffer), (&reg)[0..1]);

            gc(stagBuf.obj);
        }
    }

    /// Collect and retain obj into a garbage pool until it is eventually released
    /// a predefined number of frames later.
    /// Used mainly when you want to dispose a resource you just sent into a command buffer.
    void gc (AtomicRefCounted obj)
    {
        import gfx.core.rc : retainObj;

        auto g = new Garbage(_frameNum, retainObj(obj));
        if (!_gcLast) {
            assert(!_gcFirst);
            _gcFirst = g;
            _gcLast = g;
        }
        else {
            assert(!_gcLast.next);
            _gcLast.next = g;
            _gcLast = g;
        }
    }

    package void incrFrameNum()
    {
        import gfx.core.rc : releaseObj;

        ++_frameNum;

        if (_frameNum >= _maxGcAge) {

            const lastAllowed = _frameNum - _maxGcAge;

            while (_gcFirst && _gcFirst.frameNum < lastAllowed) {
                releaseObj(_gcFirst.obj);
                _gcFirst = _gcFirst.next;
            }
        }
    }
}

/// Checks whether the buffer should be re-allocated, considering
/// the needed size. The current rules are the following:
///   - if buffer is null, return true
///   - if buffer.size < neededSize, return true
///   - if buffer.size > 2*neededSize, return true
///   - otherwise, return false
bool mustReallocBuffer(Buffer buffer, in size_t neededSize)
{
    return !buffer ||
            buffer.size < neededSize ||
            buffer.size > 2*neededSize;
}

/// ditto
bool mustReallocBuffer(BufferAlloc buffer, in size_t neededSize)
{
    return !buffer ||
            buffer.size < neededSize ||
            buffer.size > 2*neededSize;
}

// from Sascha Willems' repo
/// Record a pipeline barrier command in cmd in order to switch img layout
/// from oldLayout to newLayout
void setImageLayout(CommandBuffer cmd, Image img, in ImageAspect aspect,
                    in ImageLayout oldLayout, in ImageLayout newLayout,
                    in PipelineStage srcStageMask=PipelineStage.allCommands,
                    in PipelineStage dstStageMask=PipelineStage.allCommands)
{
    setImageLayout(
        cmd, img, ImageSubresourceRange(aspect, 0, 1, 0, 1),
        oldLayout, newLayout, srcStageMask, dstStageMask
    );
}

// from Sascha Willems' repo
/// ditto
void setImageLayout(CommandBuffer cmd, Image img, in ImageSubresourceRange range,
                    in ImageLayout oldLayout, in ImageLayout newLayout,
                    in PipelineStage srcStageMask=PipelineStage.allCommands,
                    in PipelineStage dstStageMask=PipelineStage.allCommands)
{
    import gfx.core.typecons : trans;
    import gfx.graal.cmd : ImageMemoryBarrier, queueFamilyIgnored;

    Trans!ImageLayout layout = trans(oldLayout, newLayout);
    auto barrier = ImageMemoryBarrier(
        getLayoutAccess(layout), layout,
        trans(queueFamilyIgnored, queueFamilyIgnored),
        img, range
    );

    cmd.pipelineBarrier(
        trans(srcStageMask, dstStageMask), [], (&barrier)[0 .. 1]
    );
}


private:

struct AutoCmdBuf
{
    import gfx.core.rc : Rc;
    import gfx.graal.cmd : CommandPool;
    import gfx.graal.device : Device;
    import gfx.graal.queue : Queue;

    public CommandBuffer cmd;

    private Rc!Device device;
    private Queue queue;
    private Rc!CommandPool pool;

    this(Queue queue, CommandPool pool)
    {
        import std.typecons : No;

        this.pool = pool;
        this.queue = queue;
        this.device = queue.device;
        this.cmd = this.pool.allocate(1)[0];
        this.cmd.begin(No.persistent);
    }

    ~this()
    {
        import gfx.graal.queue : Submission;

        this.cmd.end();
        this.queue.submit([
            Submission([], [], [ this.cmd ])
        ], null);
        this.queue.waitIdle();
        this.pool.free([ this.cmd ]);
        this.cmd = null;
    }

    alias cmd this;
}

class Garbage
{
    import gfx.core.rc : AtomicRefCounted;

    size_t frameNum;
    AtomicRefCounted obj;
    Garbage next;

    this (size_t frameNum, AtomicRefCounted obj)
    {
        this.frameNum = frameNum;
        this.obj = obj;
    }
}


// part of Sascha Willems's setImageLayout refactored here
Trans!Access getLayoutAccess(in Trans!ImageLayout layout) pure
{
    Trans!Access access;

    // Source access mask controls actions that have to be finished on the old layout
    // before it will be transitioned to the new layout
    switch (layout.from)
    {
    case ImageLayout.undefined:
        // Image layout is undefined (or does not matter)
        // Only valid as initial layout
        // No flags required, listed only for completeness
        access.from = Access.none;
        break;

    case ImageLayout.preinitialized:
        // Image is preinitialized
        // Only valid as initial layout for linear images, preserves memory contents
        // Make sure host writes have been finished
        access.from = Access.hostWrite;
        break;

    case ImageLayout.colorAttachmentOptimal:
        // Image is a color attachment
        // Make sure any writes to the color buffer have been finished
        access.from = Access.colorAttachmentWrite;
        break;

    case ImageLayout.depthStencilAttachmentOptimal:
        // Image is a depth/stencil attachment
        // Make sure any writes to the depth/stencil buffer have been finished
        access.from = Access.depthStencilAttachmentWrite;
        break;

    case ImageLayout.transferSrcOptimal:
        // Image is a transfer source
        // Make sure any reads from the image have been finished
        access.from = Access.transferRead;
        break;

    case ImageLayout.transferDstOptimal:
        // Image is a transfer destination
        // Make sure any writes to the image have been finished
        access.from = Access.transferWrite;
        break;

    case ImageLayout.shaderReadOnlyOptimal:
        // Image is read by a shader
        // Make sure any shader reads from the image have been finished
        access.from = Access.shaderRead;
        break;

    default:
        // Other source layouts aren't handled (yet)
        break;
    }

    // Destination access mask controls the dependency for the new image layout
    switch (layout.to)
    {
    case ImageLayout.transferDstOptimal:
        // Image will be used as a transfer destination
        // Make sure any writes to the image have been finished
        access.to = Access.transferWrite;
        break;

    case ImageLayout.transferSrcOptimal:
        // Image will be used as a transfer source
        // Make sure any reads from the image have been finished
        access.to = Access.transferRead;
        break;

    case ImageLayout.colorAttachmentOptimal:
        // Image will be used as a color attachment
        // Make sure any writes to the color buffer have been finished
        access.to = Access.colorAttachmentWrite;
        break;

    case ImageLayout.depthStencilAttachmentOptimal:
        // Image layout will be used as a depth/stencil attachment
        // Make sure any writes to depth/stencil buffer have been finished
        access.to = Access.depthStencilAttachmentWrite;
        break;

    case ImageLayout.shaderReadOnlyOptimal:
        // Image will be read in a shader (sampler, input attachment)
        // Make sure any writes to the image have been finished
        if (access.from == Access.none) {
            access.from = Access.hostWrite | Access.transferWrite;
        }
        access.to = Access.shaderRead;
        break;

    default:
        // Other source layouts aren't handled (yet)
        break;
    }

    return access;
}
