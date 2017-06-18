module dgt.sg.paint;

import dgt.color;
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

    @property Color color()
    {
        return _color;
    }
    @property void color(in Color color)
    {
        _color = color;
    }

    private Color _color;
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
