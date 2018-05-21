module dgt.render.preparation;

package:

import gfx.graal.device : Device, PhysicalDevice;
import gfx.graal.presentation : Surface;
import gfx.graal.queue : QueueCap, QueueFamily;

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
