module dgt.context;

import dgt.screen : Screen;
import dgt.window : Window, WindowFlags;

public import gfx.gl3.context;

GlContext createGlContext(GlAttribs attribs,
                                  GlContext sharedCtx=null,
                                  Screen screen=null)
{
    return createGlContext(
        attribs, null, sharedCtx, screen
    );
}

GlContext createGlContext(Window window=null,
                                  GlContext sharedCtx=null,
                                  Screen screen=null)
{
    return createGlContext(
        window ? window.attribs : GlAttribs.init,
        window, sharedCtx, screen
    );
}


private:

GlContext createGlContext(GlAttribs attribs, Window window,
                                  GlContext sharedCtx, Screen screen)
{
    Window dummy;
    if (!window) {
        window = new Window("Dummy!", WindowFlags.dummy);
        window.hide();
        dummy = window;
    }
    scope(exit) {
        if (dummy) dummy.close();
    }

    import dgt.application : Application;
    import std.exception : enforce;

    return enforce(Application.platform.createGlContext (
        attribs, window.platformWindow, sharedCtx, screen
    ));
}
