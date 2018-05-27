module dgt.render.preparation;

package:

import gfx.graal.device : Device, PhysicalDevice;
import gfx.graal.format : Format;
import gfx.graal.presentation : Surface;
import gfx.graal.queue : QueueCap, QueueFamily;

/// Get the compatibility score for a device
/// Call this function on all available devices to choose the right one.
/// This also gives the queue indices for graphics and presentation (will often be the same one)
int deviceScore(PhysicalDevice dev,  Surface surface, out uint graphicsQueue, out uint presentQueue)
{
    int score;

    static struct Aspect {
        int score;
        uint queueIndex=uint.max;
    }

    Aspect graphicsAspect;
    Aspect presentAspect;

    foreach (uint i, qf; dev.queueFamilies)
    {
        int qs=1;
        const graphics = qf.cap & QueueCap.graphics;
        const present = dev.supportsSurface(i, surface);

        // if a queue has both graphics and present capabilities, choose it.
        if (graphics && present) {
            qs *= 10;
        }

        if (qs > score) {
            score = qs;
            if (graphics) graphicsAspect = Aspect(qs, i);
            if (present) presentAspect = Aspect(qs, i);
        }
        else if (graphics && graphicsAspect.queueIndex == uint.max) {
            graphicsAspect = Aspect(qs, i);
        }
        else if (present && presentAspect.queueIndex == uint.max) {
            presentAspect = Aspect(qs, i);
        }
    }

    if (!dev.softwareRendering) {
        score *= 1000;
    }

    graphicsQueue = graphicsAspect.queueIndex;
    presentQueue = presentAspect.queueIndex;

    return score;
}

/// Return a format suitable for the surface.
///  - if supported by the surface Format.rgba8_uNorm
///  - otherwise the first format with uNorm numeric format
///  - otherwise the first format
Format chooseFormat(PhysicalDevice pd, Surface surface)
{
    import gfx.graal.format : formatDesc, NumFormat;
    import std.exception : enforce;

    const formats = pd.surfaceFormats(surface);
    enforce(formats.length, "Could not get surface formats");

    // the surface supports all kinds of formats
    if (formats.length == 1 && formats[0] == Format.undefined) {
        return Format.rgba8_uNorm;
    }

    foreach(f; formats) {
        if (f == Format.rgba8_uNorm) {
            return f;
        }
    }
    foreach(f; formats) {
        if (f.formatDesc.numFormat == NumFormat.uNorm) {
            return f;
        }
    }
    return formats[0];
}