module dgt.text;

import gfx.core.log : LogTag;

enum dgtTextLogMask = 0x0040_0000;
package(dgt) immutable dgtTextLog = LogTag("DGT-TEXT", dgtTextLogMask);
