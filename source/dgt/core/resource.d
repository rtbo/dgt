
module dgt.core.resource;

import core.sync.mutex;

import std.regex;
import std.uri;


/// Exception thrown when attempting to obtain a resource with a wrong identifier.
class UnavailableResourceException : Exception {
    private this (string uri) {
        import std.format : format;
        super(format(`Resource "%s" is not available`, uri));
        _uri = uri;
    }

    /// the identifier that raised the exception
    @property string uri() {
        return _uri;
    }

    private string _uri;
}

/// Exception thrown when a resource is requested over an protocol that is not supported
class UnsupportedProtocolException : Exception
{
    private this (string protocol, string uri) {
        import std.format : format;
        super(format(`Protocol "%s" is not supported during fetch of "%s"`, protocol, uri));
    }

    /// the unsupported protocol
    @property string protocol() {
        return _protocol;
    }

    /// the uri that was attempted to be fetched
    @property string uri() {
        return _uri;
    }

    private string _protocol;
    private string _uri;
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

    /// Retrieve a resource from the registry.
    /// Throws:
    ///     UnavailableResourceException if the resource is not found.
    static Resource get (string name) {
        mutex.lock();
        scope(exit) mutex.unlock();

        auto rp = name in registry;
        if (rp) return *rp;

        throw new UnavailableResourceException("dr://"~name);
    }

    /// Retrieve a resource from the registry.
    /// Returns: the resource, or null if it couldn't be fetched.
    static Resource tryGet (string name) {
        mutex.lock();
        scope(exit) mutex.unlock();

        auto rp = name in registry;
        if (rp) return *rp;

        return null;
    }

    /// Remove a resource from the registry.
    /// Returns: whether a resource was removed or not.
    static bool prune (string name) {
        mutex.lock();
        scope(exit) mutex.unlock();

        return registry.remove(name);
    }
}

/// Retrieve a resource specified by uri.
/// Different protocol are supported in the usual form of "protocol://resource".
/// If no protocol is specified, "file://" is assumed.
/// To obtain a value from `Registry`, "dr://" protocol should be used.
/// Supported protocols:
///     - dr://
///     - file://
/// If the URI is requested over a network, it is encoded beforehand, so uri
/// passed to this function should not be encoded.
Resource retrieveResource(in string uri)
{
    auto regex = ctRegex!(uriRegex);
    const m = matchFirst(uri, regex);

    string protocol = "file";
    string resId = uri;

    if (m.length >= 3) {
        protocol = m[1];
        resId = m[2];
    }

    switch (protocol) {
    case "file":
        import std.exception : assumeUnique;
        import std.file : exists, read;
        if (!exists(resId)) {
            throw new UnavailableResourceException(uri);
        }
        return assumeUnique(cast(ubyte[])read(resId));
    case "dr":
        return Registry.get(resId);
    default:
        throw new UnsupportedProtocolException(protocol, uri);
    }

}


private:

Mutex mutex;

enum uriRegex = `^(\w+)://(.+)`;

unittest {
    auto regex = ctRegex!(uriRegex);

    string testUri = "http://this.uri/is.awesome";
    auto m = matchFirst(testUri, regex);
    assert(m);
    assert(m.length == 3);
    assert(m[0] == testUri);
    assert(m[1] == "http");
    assert(m[2] == "this.uri/is.awesome");
}

__gshared Resource[string] registry;


shared static this() {
    mutex = new Mutex;
}
