/// module that implement font atlas generation
/// see: https://straypixels.net/texture-packing-for-fonts/
/// An alternative would also be the freetype-gl atlas implementation.
module dgt.render.atlas;

import gfx.core.rc : AtomicRefCounted;
import gfx.math.vec : IVec2;

// binary tree representation of a texture space

final class AtlasNode
{
    import dgt.font.typeface : Glyph;
    import gfx.core.rc : Weak;
    import gfx.math.vec : IVec2;

    this (GlyphAtlas atlas, in IVec2 origin, in IVec2 size) {
        this.atlas = atlas;
        _origin = origin;
        _size = size;
    }

    @property IVec2 origin() const {
        return _origin;
    }

    @property IVec2 size() const {
        return _size;
    }

    GlyphAtlas atlas;
    Glyph glyph;

    private IVec2 _origin;
    private IVec2 _size;
    private AtlasNode left;
    private AtlasNode right;
}

final class GlyphAtlas
{
    import dgt.core.image : Image;
    import dgt.font.typeface : Glyph;

    private AtlasNode root;
    private Image _image;
    private IVec2 _textureSize;
    private IVec2 _maxSize;
    private int _margin;
    private IVec2 lastFailedSize=IVec2(int.max, int.max);
    private size_t numNodes;
    private bool _realized;


    this (in IVec2 startSize, in IVec2 maxSize, in int margin=0) {
        _textureSize = startSize;
        _maxSize = maxSize;
        _margin = margin;
        root = new AtlasNode(this, IVec2(margin, margin), maxSize - 2*IVec2(margin, margin));
    }

    @property IVec2 textureSize() {
        return _textureSize;
    }

    AtlasNode pack(in IVec2 size, Glyph glyph) {
        auto node = pack(root, size);
        while (!node && (_textureSize.x < _maxSize.x || _textureSize.y < _maxSize.y)) {
            import std.algorithm : min;
            _textureSize.x = min(_textureSize.x*2, _maxSize.x);
            _textureSize.y = min(_textureSize.y*2, _maxSize.y);
            node = pack(root, size);
        }
        if (node) {
            node.glyph = glyph;
            ++numNodes;
            _realized = false;
        }
        else {
            import std.algorithm : min;
            lastFailedSize.x = min(lastFailedSize.x, size.x);
            lastFailedSize.y = min(lastFailedSize.y, size.y);
        }
        return node;
    }

    bool couldPack(in IVec2 size) {
        return size.x < lastFailedSize.x || size.y < lastFailedSize.y;
    }

    /// Realize the atlas, that is render all collected glyphs in an image.
    /// Returns: true if the image was updated, false otherwise
    bool realize()
    {
        import dgt.core.geometry : ISize;
        import dgt.core.image : alignedStrideForWidth, Image, ImageFormat;
        import gfx.math : ivec;

        if (_realized) return false;

        scope(success) _realized = true;

        const sz = ISize(_textureSize.x, _textureSize.y);
        if (!_image || _image.size != sz) {
            _image = new Image(ImageFormat.a8, sz, alignedStrideForWidth(ImageFormat.a8, sz.width));
        }
        _image.clear!uint(0);

        void browse(AtlasNode node) {
            if (node.glyph) {
                _image.blitFrom(node.glyph.img, ivec(0, 0), node.origin, node.glyph.img.size);
            }
            if (node.left) {
                browse(node.left);
            }
            if (node.right) {
                browse(node.right);
            }
        }

        browse(root);

        import std.format;
        static int num = 1;
        _image.saveToFile(format("atlas%s.png", num++));

        return true;
    }

    /// Get the realized image of the Atlas. It has format ImageFormat.a8.
    @property Image image() {
        return _image;
    }


    /// Recursively scan the tree from node to find a space for the given size.
    /// Returns: a new node if space was found, null otherwise.
    private AtlasNode pack (AtlasNode node, in IVec2 size)
    in {
        assert(node, "Node is null");
    }
    body {
        if (node.glyph) {
            // that one is filled, can't pack anything here.
            return null;
        }
        else if (node.left && node.right) {
            // not a leaf, we try to insert on the left, then on the right.
            auto n = pack(node.left, size);
            if (!n) {
                n = pack(node.right, size);
            }
            return n;
        }
        else {
            // this is an unfilled leaf. let's see if it can be filled.
            auto realSize = node.size;
            if (node.origin.x + node.size.x == _maxSize.x - _margin) {
                realSize.x = _textureSize.x - node.origin.x - _margin;
            }
            if (node.origin.y + node.size.y == _maxSize.y - _margin) {
                realSize.y = _textureSize.y - node.origin.y - _margin;
            }

            if (node.size.x == size.x && node.size.y == size.y) {
                // perfect fit, let's pack it here
                return node;
            }
            else if (realSize.x < size.x || realSize.y < size.y) {
                // not enough space here
                return null;
            }
            else {
                // large enough, let's divide space for the given size
                const remain = realSize - size;
                assert(remain.x >= 0 && remain.y >= 0);
                auto vertical = remain.x < remain.y;
                if (remain.x == 0 && remain.y == 0) {
                    // edge case, we hit the border exactly
                    vertical = node.size.y >= node.size.x;
                }
                assert(!node.left && !node.right, "always assign both left and right together");
                if (vertical) {
                    node.left = new AtlasNode(this, node.origin, IVec2(node.size.x, size.y));
                    node.right = new AtlasNode(this, IVec2(node.origin.x, node.origin.y+size.y),
                                               IVec2(node.size.x, node.size.y-size.y));
                }
                else {
                    node.left = new AtlasNode(this, node.origin, IVec2(size.x, node.size.y));
                    node.right = new AtlasNode(this, IVec2(node.origin.x+size.x, node.origin.y),
                                               IVec2(node.size.x-size.x, node.size.y));
                }
                return pack(node.left, size);
            }
        }
    }
}
