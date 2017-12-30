module dgt.core.sync;

import std.traits : isCallable;

void synchronize(alias F, T)(shared(T) obj)
if (isCallable!F && is(typeof(F(cast(T)obj))))
{
    synchronized(obj) {
        F(cast(T)obj);
    }
}
