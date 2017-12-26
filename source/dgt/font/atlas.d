/// module that implement font atlas generation
/// see: https://straypixels.net/texture-packing-for-fonts/
/// An alternative would also be the freetype-gl atlas implementation.
module dgt.font.atlas;

import dgt.math.vec : IVec2;

// binary tree representation of a texture space

class Glyph{}

final class AtlasNode {
    this (in IVec2 origin, in IVec2 size) {
        this.origin = origin;
        this.size = size;
    }

    private IVec2 origin;
    private IVec2 size;
    private AtlasNode left;
    private AtlasNode right;
    private Glyph glyph;
}

final class Atlas
{
    this (in IVec2 startSize, in IVec2 maxSize, in int margin=0) {
        this.textureSize = startSize;
        this.maxSize = maxSize;
        this.margin = margin;
        root = new AtlasNode(IVec2(margin, margin), maxSize - 2*IVec2(margin, margin));
    }

    /// Recursively scan the tree from node to find a space for the given size.
    /// Returns: a new node if space was found, null otherwise.
    private AtlasNode pack (AtlasNode node, in IVec2 size)
    in {
        assert(node);
    }
    body {
        if (node.glyph) {
            // that one is filled, can't pack anything here.
            return null;
        }
        else if (node.left && node.right) {
            // not a leaf, we try to insert on the left, then on the right.
            auto n = pack(node.left, size);
            if (!n) pack(node.right, size);
            return n;
        }
        else {
            // this is an unfilled leaf. let's see if it can be filled.
            auto realSize = node.size;
            if (node.origin.x + node.size.x == maxSize.x - margin) {
                realSize.x = textureSize.x - node.origin.x - margin;
            }
            if (node.origin.y + node.size.y == maxSize.y - margin) {
                realSize.y = textureSize.y - node.origin.y - margin;
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
                    node.left = new AtlasNode(node.origin, IVec2(node.size.x, size.y));
                    node.right = new AtlasNode(IVec2(node.origin.x, node.origin.y+size.y),
                                               IVec2(node.size.x, node.size.y-size.y));
                }
                else {
                    node.left = new AtlasNode(node.origin, IVec2(size.x, node.size.y));
                    node.right = new AtlasNode(IVec2(node.origin.x+size.x, node.origin.y),
                                               IVec2(node.size.x-size.x, node.size.y));
                }
                return pack(node.left, size);
            }
        }
    }

    private AtlasNode root;
    private IVec2 textureSize;
    private IVec2 maxSize;
    private int margin;
}
