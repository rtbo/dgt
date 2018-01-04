
module dgt.core.resource;

import core.sync.mutex;

/// Exception thrown by the registry when attempting to obtain a resource with
/// a wrong identifier
class UnavailableResourceException : Exception {
    private this (string resName) {
        import std.format : format;
        super(format(`Resource "%s" is not available in the registry`, resName));
        _resName = resName;
    }

    /// the identifier that raised the exception
    @property string resName() {
        return _resName;
    }

    private string _resName;
}

/// A binary blob that can be registered and retrieved in the registry
alias Resource = immutable(ubyte)[];

/// The registry is a facility that allow to retrieve at runtime resources
/// that were registered either at compile time, or sooner at runtime.
/// It only register raw data as binary blobs.
struct Registry {

    /// Register compile time resources from the "views" folder or any folder
    /// specified with the "-J" compiler switch.
    /// Each compile-time name must yield to a valid resource that can be optained by `import(name)`.
    /// It can be retrieved later by using the same identifier
    static void registerImport(names...)() {
        mutex.lock();
        scope(exit) mutex.unlock();

        foreach (n; names) {
            static assert (is(typeof({ string s = n; })),
                "only string can be passed as identifier to Registry.registerImport"
            );
            registry[n] = cast(Resource)import(n);
        }
    }

    /// Register a resource at run time
    static void register(in string name, Resource resource) {
        mutex.lock();
        scope(exit) mutex.unlock();

        registry[name] = resource;
    }

    /// Register resources that are held in a associative array
    static void registerDict(in Resource[string] dict) {
        mutex.lock();
        scope(exit) mutex.unlock();

        foreach (k, v; dict) {
            registry[k] = v;
        }
    }

    /// Retrieve a resource from the registry
    static Resource get (string name) {
        mutex.lock();
        scope(exit) mutex.unlock();

        auto rp = name in registry;
        if (rp) return *rp;
        else {
            throw new UnavailableResourceException(name);
        }
    }
}

private:

Mutex mutex;

__gshared Resource[string] registry;


shared static this() {
    mutex = new Mutex;
}
