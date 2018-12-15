module dgt.render;

import gfx.core.log : LogTag;

enum dgtRenderLogMask = 0x0020_0000;
package immutable dgtRenderLog = LogTag("DGT-RENDER", dgtRenderLogMask);
