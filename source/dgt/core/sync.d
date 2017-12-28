module dgt.core.sync;

void synchronize(alias F, T)(shared(T) obj) {
    synchronized(obj) {
        F(cast(T)obj);
    }
}
