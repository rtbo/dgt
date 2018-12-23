/// module that produce atlases of packed images.
module dgt.render.atlas;

import gfx.core.rc : AtomicRefCounted;

struct AtlasSizeRange
{
    import dgt.gfx.geometry : ISize;

    /// A delegate that define the step taken to extent current towards max.
    /// It is called with current and must return the new value for current.
    alias Stepper = ISize delegate (in ISize sz);

    ISize current;
    ISize max;
    Stepper stepper;

    /// The size is fixed to a single dimension
    this (in ISize fixed)
    {
        this(fixed, fixed);
    }

    /// The size starts at start and can extend to max in a single step
    this (in ISize start, in ISize max)
    {
        this (start, max, cast(Stepper) sz => max);
    }

    /// The size starts at start and can extend to max by successive application of stepper
    this (in ISize start, in ISize max, Stepper stepper)
    in {
        assert(max.width >= start.width);
        assert(max.height >= start.height);
        assert(max.width == start.width || stepper(start).width > start.width);
        assert(max.height == start.height || stepper(start).height > start.height);
    }
    body {
        this.current = start;
        this.max = max;
        this.stepper = stepper;
    }

    /// initialize a square size range
    this (in uint fixed)
    {
        this(ISize(fixed, fixed));
    }

    /// ditto
    this (in uint start, in uint max)
    {
        this(ISize(start, start), ISize(max, max));
    }

    /// ditto
    this (in uint start, in uint max, Stepper stepper)
    {
        this(ISize(start, start), ISize(max, max), stepper);
    }

    @property bool canExtend() const
    {
        return current != max;
    }

    void extend()
    {
        import std.algorithm : min;

        const nextSz = stepper(current);

        current = ISize(
            min(nextSz.width, max.width),
            min(nextSz.height, max.height),
        );
    }
}

class AtlasNode
{
    import dgt.gfx.geometry : IRect;
    import dgt.gfx.image : Image;
    import std.typecons : Rebindable;

    private Atlas _atlas;
    private size_t _atlasInd;
    private Rebindable!(immutable(Image)) _image;
    private IRect _rect;
    private AtlasNode prev;
    private AtlasNode next;
    private bool written;

    private this (Atlas atlas, immutable(Image) image, in IRect rect)
    {
        _atlas = atlas;
        _atlasInd = atlas._atlasInd;
        _image = image;
        _rect = rect;
    }

    @property Atlas atlas() {
        return _atlas;
    }

    @property size_t atlasInd() {
        return _atlasInd;
    }

    @property immutable(Image) image() {
        return _image;
    }

    @property IRect rect() const {
        return _rect;
    }

    void setFree() {
        _image = null;
        _atlas.setFree(this);
    }

    @property bool isFree() const {
        return _image is null;
    }
}


class Atlas : AtomicRefCounted
{
    import dgt.gfx.geometry : ISize;
    import dgt.gfx.image : Image, ImageFormat;
    import dgt.render.binpack : BinPack, BinPackFactory;
    import dgt.render.services : RenderServices;
    import gfx.core.rc : Rc;
    import gfx.graal.cmd : CommandBuffer;
    import gfx.graal.format : Format;
    import gfx.graal.image : ImageView, Swizzle;
    import gfx.memalloc : ImageAlloc;

    /// Define the invalidation state of the atlas image
    private enum Invalidation {
        /// the image view is up-to-date
        upToDate,
        /// the previous state is still valid, but new nodes were added and must
        /// be rendered, and the image uploaded again into graphics memory
        update,
        /// same as update, but the image was also extended
        extended,
        /// the image must be entirely rebuilt
        rebuild,
    }
    /// The invalidation state
    private Invalidation _invalidation = Invalidation.rebuild;

    /// the rectangle bin packing algorithm
    private BinPack _binPack;

    /// the format of the bin image
    private ImageFormat _format;

    /// the size range of the bin
    private AtlasSizeRange _sizeRange;

    /// Margin around images
    private int _margin;

    /// whether some nodes have been freed
    /// this indicates that the atlas should repack itself if it can't pack
    /// a new node
    private bool _hasFreedNodes;

    /// The first node of this atlas
    private AtlasNode _first;
    /// The last node of this atlas
    private AtlasNode _last;

    /// The image built from the set of nodes.
    private Image _image;

    /// The image in graphics memory
    private Rc!ImageAlloc _imgAlloc;

    /// The image view
    private Rc!ImageView _imgView;

    /// The index of the atlas within its collection.
    /// Only passed verbatim to nodes.
    private size_t _atlasInd;

    /// build a new Atlas
    /// Params:
    ///     factory = a factory to build a bin pack for this atlas
    ///     atlasInd = the index of this atlas within its collection.
    ///                This is only passed verbatim to the nodes and not used otherwise
    ///     sizeRange = the size range that sizes the atlas and define how to extend it
    ///     format = the image format to build the atlas
    ///     margin = the margin around each node
    this (BinPackFactory factory, in size_t atlasInd, in AtlasSizeRange sizeRange, in ImageFormat format, int margin=0)
    {
        _sizeRange = sizeRange;
        _binPack = factory(_sizeRange.current);
        _atlasInd = atlasInd;
        _format = format;
        _margin = margin;
    }

    override void dispose()
    {
        _imgAlloc.unload();
        _imgView.unload();
    }

    @property ISize binSize() const {
        return _sizeRange.current;
    }

    @property ImageFormat format() const {
        return _format;
    }

    /// Packs an image into the atlas.
    /// Returns: whether the pack was successful.
    AtlasNode pack (immutable(Image) image)
    in {
        assert(image && image.format == _format);
    }
    body {
        import dgt.gfx.geometry : IMargins, IRect;
        import std.algorithm : max;

        const sz = image.size + IMargins(_margin);
        IRect rect;
        bool packed = _binPack.pack(sz, rect);
        if (!packed && _hasFreedNodes) {
            invalidate(Invalidation.rebuild);
            repack();
            packed = _binPack.pack(sz, rect);
            _hasFreedNodes = false;
        }
        // checking whether bin can be extended
        // try to extend only once
        if (!packed && _sizeRange.canExtend && _binPack.extensible) {
            invalidate(Invalidation.extended);
            _sizeRange.extend();
            _binPack.extend( _sizeRange.current );
            packed = _binPack.pack(sz, rect);
        }
        if (!packed) {
            return null;
        }

        invalidate(Invalidation.update);

        auto n = new AtlasNode(this, image, rect - IMargins(_margin));
        if (!_last) {
            assert(!_first);
            _first = n;
            _last = n;
        }
        else {
            assert(!_last.next);
            _last.next = n;
            n.prev = _last;
            _last = n;
        }
        return n;
    }

    /// Realizes the assembly into a single image and get the gfx view to this image.
    /// If the view is not the same as the previous one, true is returned.
    /// Otherwise returns false.
    bool realize(RenderServices services, CommandBuffer cmd)
    {
        import core.thread : Thread;
        import dgt.gfx.image : alignedStrideForWidth;
        import gfx.graal.image : ImageAspect, ImageInfo, ImageLayout,
                                 ImageSubresourceRange, ImageTiling, ImageType,
                                 ImageUsage;
        import gfx.math : ivec;
        import gfx.memalloc : AllocFlags, AllocOptions, MemoryUsage;

        if (!_image || !_imgAlloc || !_imgView) {
            _invalidation = Invalidation.rebuild;
        }

        if (_invalidation == Invalidation.upToDate) {
            return false;
        }

        const makeNewImg = (cast(int)_invalidation >= cast(int)Invalidation.extended);
        const bs = binSize;

        void buildImage() {
            auto prevImg = _image;

            if (makeNewImg) {
                _image = new Image(_format, bs, alignedStrideForWidth(_format, bs.width));
                // data is uninitialized, but valid areas are always written so it can stay so
            }

            if (_invalidation == Invalidation.extended && prevImg) {
                _image.blitFrom(prevImg, ivec(0, 0), ivec(0, 0), prevImg.size);
            }

            AtlasNode n = _first;
            while (n) {
                if (!n.written || _invalidation == Invalidation.rebuild) {
                    const nr = n.rect;
                    _image.blitFrom(n.image, ivec(0, 0), nr.point, nr.size);
                    n.written = true;
                }
                n = n.next;
            }
        }

        if (makeNewImg) {
            auto th = new Thread(&buildImage);
            th.start();

            Swizzle swizzle;
            const format = convertFormat(_format, swizzle);

            if (_imgAlloc) services.gc(_imgAlloc.obj);
            if (_imgView) services.gc(_imgView.obj);

            _imgAlloc = services.allocator.allocateImage
            (
                ImageInfo.d2(bs.width, bs.height)
                    .withFormat(format)
                    .withUsage(ImageUsage.sampled | ImageUsage.transferDst)
                    .withTiling(ImageTiling.optimal),

                AllocOptions.forUsage(MemoryUsage.gpuOnly)
                    .withFlags(AllocFlags.dedicated)
            );

            _imgView = _imgAlloc.image.createView(
                ImageType.d2, ImageSubresourceRange(ImageAspect.color), swizzle
            );

            th.join();
        }
        else {
            buildImage();
        }

        static if (false) {
            import std.format : format;
            static int num = 1;
            _image.saveToFile(format("atlas%s.png", num++));
        }

        services.stageDataToImage(
            cmd, _imgAlloc.image, ImageAspect.color, ImageLayout.undefined, _image.data
        );

        _invalidation = Invalidation.upToDate;

        return makeNewImg;
    }

    /// The view to image in graphics memory for this atlas
    @property ImageView imgView()
    {
        return _imgView;
    }

    private void setFree(AtlasNode node)
    {
        if (node is _first) {
            _first = node.next;
        }
        if (node is _last) {
            _last = node.prev;
        }
        if (node.prev) {
            node.prev.next = node.next;
        }
        if (node.next) {
            node.next.prev = node.prev;
        }
        _hasFreedNodes = true;
    }

    private void repack() {
        _binPack.reset(binSize);
        auto n = _first;
        while (n) {
            assert(n.image);
            const packed = _binPack.pack(n.image.size, n._rect);
            assert(packed);
            n = n.next;
        }
    }

    private void invalidate(Invalidation invalidation)
    {
        if (cast(int)invalidation > cast(int)_invalidation) {
            _invalidation = invalidation;
        }
    }

    private static Format convertFormat(in ImageFormat fmt, out Swizzle swizzle)
    {
        final switch (fmt) {
        case ImageFormat.a1: assert(false, "ImageFormat.a1 is not supported");
        case ImageFormat.a8:
            swizzle = Swizzle.identity;
            return Format.r8_uNorm;
        case ImageFormat.xrgb:
        case ImageFormat.argb:
        case ImageFormat.argbPremult:
            // argb swizzling
            version(LittleEndian) {
                swizzle = Swizzle.bgra;
            }
            else {
                swizzle = Swizzle.argb;
            }
            // alpha specificity to be handled by shader
            return Format.rgba8_uNorm;
        }
    }
}
