module dgt.font.typeface;

import gfx.foundation.rc;

abstract class Typeface : RefCounted {
    mixin(rcCode);
    abstract void dispose();
}
