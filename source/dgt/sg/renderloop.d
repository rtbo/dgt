module dgt.sg.renderloop;

import dgt.context;
import dgt.window;

class SGRenderLoop
{
    static SGRenderLoop instance()
    {
        return g_instance;
    }

    void start(GlContext glCtx)
    {
        _glCtx = glCtx;
    }

    void stop()
    {
    }

    void update(Window w)
    {
    }

    package(dgt) static void initialize()
    {
        g_instance = new SGRenderLoop;
    }

    private this() {}


    GlContext _glCtx;
}

private:

__gshared SGRenderLoop g_instance;
