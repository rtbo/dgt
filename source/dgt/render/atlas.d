/// module that implement font atlas generation
/// see: https://straypixels.net/texture-packing-for-fonts/
/// An alternative would also be the freetype-gl atlas implementation.
module dgt.render.atlas;

version(none):

import dgt.core.geometry;
import dgt.core.image;
import dgt.core.rc;
import dgt.font.typeface : Glyph;
import dgt.render.defs : Alpha8;
import gfx.math.vec : IVec2;

// binary tree representation of a texture space

final class AtlasNode
{
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

    Weak!GlyphAtlas atlas;

    Glyph glyph;

    private IVec2 _origin;
    private IVec2 _size;
    private AtlasNode left;
    private AtlasNode right;
}

final class GlyphAtlas : RefCounted
{
    mixin(rcCode);

    this (in IVec2 startSize, in IVec2 maxSize, in int margin=0) {
        _textureSize = startSize;
        _maxSize = maxSize;
        _margin = margin;
        root = new AtlasNode(this, IVec2(margin, margin), maxSize - 2*IVec2(margin, margin));
    }

    override void dispose() {
        _srv.unload();
        _sampler.unload();
        root = null;
    }

    @property IVec2 textureSize() {
        return _textureSize;
    }

    @property Sampler sampler() {
        return _sampler.obj;
    }

    @property ShaderResourceView!Alpha8 srv() {
        return _srv.obj;
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

    void realize() {
        if (_realized) return;

        scope(success) _realized = true;

        auto img = new Image(ImageFormat.a8, ISize(_textureSize.x, _textureSize.y),
                    alignedStrideForWidth(ImageFormat.a8, _textureSize.x));

        void browse(AtlasNode node) {
            if (node.glyph) {
                img.blitFrom(node.glyph.img, ivec(0, 0), node.origin, node.glyph.img.size);
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
        img.saveToFile(format("atlas%s.png", num++));

        const pixels = img.data;
        TexUsageFlags usage = TextureUsage.shaderResource;
        auto tex = new Texture2D!Alpha8(
            usage, 1, cast(ushort)img.width, cast(ushort)img.height, [pixels]
        ).rc();
        _srv = tex.viewAsShaderResource(0, 0, newSwizzle());
        // FilterMethod.scale maps to GL_NEAREST
        // no need to filter what is already filtered
        _sampler = new Sampler(
            srv, SamplerInfo(FilterMethod.scale, WrapMode.init)
        );
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

    private AtlasNode root;
    private IVec2 _textureSize;
    private IVec2 _maxSize;
    private int _margin;
    private Rc!(ShaderResourceView!Alpha8) _srv;
    private Rc!Sampler _sampler;
    private IVec2 lastFailedSize=IVec2(int.max, int.max);
    private size_t numNodes;
    private bool _realized;
}
