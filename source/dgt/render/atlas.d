/// module that produce atlases of packed images.
module dgt.render.atlas;


class AtlasNode
{
    import dgt.core.geometry : IRect;
    import dgt.core.image : Image;
    import std.typecons : Rebindable;

    private Atlas _atlas;
    private Rebindable!(immutable(Image)) _image;
    private IRect _rect;
    private AtlasNode prev;
    private AtlasNode next;

    private this (Atlas atlas, immutable(Image) image, in IRect rect)
    {
        _atlas = atlas;
        _image = image;
        _rect = rect;
    }

    @property Atlas atlas() {
        return _atlas;
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


class Atlas
{
    import dgt.core.geometry : ISize;
    import dgt.core.image : Image, ImageFormat;
    import dgt.render.binpack : BinPack, BinPackFactory;
    import gfx.math : IVec2;

    /// the rectangle bin packing algorithm
    private BinPack _binPack;

    /// the format of the bin image
    private ImageFormat _format;

    /// the side size if the bin
    /// always a power of 2
    private uint _binSize;

    /// whether some nodes have been freed
    /// this indicates that the atlas should repack itself if it can't pack
    /// a new node
    private bool _hasFreedNodes;

    /// The first node of this atlas
    private AtlasNode _first;
    /// The last node of this atlas
    private AtlasNode _last;

    /// The image built from the set of nodes.
    /// This member is set to null each time the image must be reconstructed
    private Image _image;

    /// Margin around images
    private int _margin;

    /// The bin side size at the start
    enum startSize = 128;
    /// The max side size the bin can be extended to
    enum maxSize = 512;

    this (BinPackFactory factory, in ImageFormat format, int margin=0)
    {
        _binPack = factory(ISize(startSize, startSize), true);
        _binSize = startSize;
        _format = format;
        _margin = margin;
    }

    @property IVec2 textureSize() const {
        import gfx.math : ivec;
        return ivec(_binSize, _binSize);
    }

    /// Packs an image into the atlas.
    /// Returns: whether the pack was successful.
    AtlasNode pack (immutable(Image) image)
    {
        import dgt.core.geometry : IMargins, IRect;

        const sz = image.size + IMargins(_margin);
        IRect rect;
        bool packed = _binPack.pack(sz, rect);
        if (!packed && _hasFreedNodes) {
            _image = null;
            repack();
            packed = _binPack.pack(sz, rect);
        }
        if (!packed && _binSize != maxSize && _binPack.extensible) {
            _image = null;
            _binSize *= 2;
            _binPack.extend( ISize(_binSize, _binSize) );
            packed = _binPack.pack(sz, rect);
        }
        if (!packed) {
            return null;
        }

        _image = null;

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

    /// Realizes the assembly into a single image.
    /// If the image was not already realized, or if data has changed, returns true.
    /// Otherwise (same data as previous call returned) returns false.
    bool realize(out Image img)
    {
        import dgt.core.image : alignedStrideForWidth;
        import gfx.math : ivec;

        if (_image) {
            img = _image;
            return false;
        }

        const bs = ISize(_binSize, _binSize);

        if (!_image || _image.size != bs) {
            _image = new Image(
                ImageFormat.a8, bs,
                alignedStrideForWidth(ImageFormat.a8, bs.width)
            );
        }
        /// uint ok also for 1 byte format as we have power of 2 sizes
        _image.clear!uint(0);

        AtlasNode n = _first;
        while (n) {
            const nr = n.rect;
            _image.blitFrom(n.image, ivec(0, 0), nr.point, nr.size);
            n = n.next;
        }

        import std.format;
        static int num = 1;
        _image.saveToFile(format("atlas%s.png", num++));

        img = _image;
        return true;
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
        _binPack.reset(ISize(_binSize, _binSize));
        auto n = _first;
        while (n) {
            assert(n.image);
            const packed = _binPack.pack(n.image.size, n._rect);
            assert(packed);
            n = n.next;
        }
    }
}
