module dgt.css;

import gfx.core.log : LogTag;

enum dgtCssLogMask = 0x0400_0000;
package(dgt) immutable dgtCssLog = LogTag("DGT-CSS", dgtCssLogMask);
