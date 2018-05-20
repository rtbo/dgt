module dgt.render.renderer2;

import gfx.gl3.context : GlContext;
import gfx.graal : Instance, Backend;

/// Creates a renderer with the list of backends supplied.
/// Returns: the first renderer that could be created
/// Params:
///     tryOrder =      The list of backend to try to instantiate
///     appName =       The name of the application (interests Vulkan backend)
///     appVersion =    The version of the application (interests Vulkan backend)
///     context =       A context for the OpenGl backend.
///                     The context is moved to the renderer and should not be
///                     accessed from application afterwards
Renderer createRenderer(Backend[] tryOrder, lazy string appName,
                        lazy uint[3] appVersion, lazy GlContext context)
{
    Exception ex;
    foreach (backend; tryOrder)
    {
        try {
            if (backend == Backend.vulkan) {
                return createVulkanRenderer(appName, appVersion);
            }
            else if (backend == Backend.gl3) {
                return createOpenGLRenderer(context);
            }
            else {
                assert(false);
            }
        }
        catch(Exception e) {
            ex = e;
        }
    }
    throw ex;
}

/// Creates a Vulkan backed renderer
Renderer createVulkanRenderer(string appName, uint[3] appVersion)
{
    import gfx.vulkan : createVulkanInstance, VulkanVersion;
    return new VulkanRenderer(createVulkanInstance(
        appName, VulkanVersion(appVersion[0], appVersion[1], appVersion[2])
    ));
}

/// Creates an OpenGL backed renderer
/// The context is moved to the renderer and should not be accessed by the
/// application afterwards.
Renderer createOpenGLRenderer(GlContext context)
{
    import gfx.gl3 : GlInstance;
    return new OpenGLRenderer(new GlInstance(context));
}

interface Renderer
{}

private:

class VulkanRenderer : Renderer
{
    private Instance _instance;

    this(Instance instance)
    {
        _instance = instance;
    }
}

class OpenGLRenderer : Renderer
{
    private Instance _instance;

    this(Instance instance)
    {
        _instance = instance;
    }
}
