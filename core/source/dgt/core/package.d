/// Super module for DGT-Core
module dgt.core;

import gfx.core.log : LogTag;

enum dgtCoreLogMask = 0x0800_0000;
package(dgt) immutable dgtCoreLog = LogTag("DGT-CORE", dgtCoreLogMask);
