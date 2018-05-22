module dgt.render.rect2;

import gfx.math.vec;

struct RectColVertex
{
    FVec3 position;
    FVec3 edge;
}

struct RectImgVertex
{
    FVec3 position;
    FVec2 texCoord;
    FVec3 edge;
}
