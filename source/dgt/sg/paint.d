module dgt.sg.paint;

import dgt.math.vec;

import gfx.foundation.rc;
import gfx.pipeline.pso : ConstantBlockDesc;


abstract class SGPaintEffect : RefCounted
{
    mixin(rcCode);

    override void dispose() {}

    abstract @property string pxShaderGLSL();
}

class SGSolidPaint : SGPaintEffect
{
    this() {}

    override @property string pxShaderGLSL()
    {
        return solidPxShader;
    }

    @property FVec4 color()
    {
        return _color;
    }
    @property void color(in FVec4 color)
    {
        _color = color;
    }

    private FVec4 _color;
}


enum solidPxShader = `
    #version 330

    uniform Color {
        vec4 u_matColor;
    };

    out vec4 o_Color;

    void main() {
        o_Color = u_matColor;
    }
`;
