module dgt.bindings;

/// Brings enumerants into global scope to mimic C visibility.
/// Generated code must be mixed-in in the module the enum is defined.
@property string globalEnumsAliasesCode(Enums...)()
{
    import std.traits : EnumMembers;
    import std.meta : NoDuplicates;
    import std.conv : to;

    string code;
    foreach(Enum; Enums)
    {
        foreach(immutable memb; NoDuplicates!(EnumMembers!Enum))
        {
            auto name = memb.to!string;
            code ~= "alias "~name~" = "~Enum.stringof~"."~name~";\n";
        }
        code ~= "\n";
    }
    return code;
}

///
version(unittest)
{
    extern(C) enum some_c_enum_t
    {
        SOME_C_ENUM_VAL1 = 2,
        SOME_C_ENUM_VAL2 = 4,
        SOME_C_ENUM_VAL3 = 12,
    }
    extern(C) enum another_c_enum_t
    {
        ANOTHER_C_ENUM_VAL1 = 42,
        ANOTHER_C_ENUM_VAL2 = 53,
    }
    mixin(globalEnumsAliasesCode!(
        some_c_enum_t, another_c_enum_t
    ));

    static assert(some_c_enum_t.SOME_C_ENUM_VAL1 == SOME_C_ENUM_VAL1);
    static assert(SOME_C_ENUM_VAL3 == 12);

    static assert(another_c_enum_t.ANOTHER_C_ENUM_VAL1 == ANOTHER_C_ENUM_VAL1);
    static assert(ANOTHER_C_ENUM_VAL2 == 53);
}


// Dynamic bindings facility


/// A handle to a shared library
alias SharedLib = void*;
/// A handle to a shared library symbol
alias SharedSym = void*;

/// Opens a shared library.
/// Return null in case of failure.
SharedLib openSharedLib(string name);

/// Load a symbol from a shared library.
/// Return null in case of failure.
SharedSym loadSharedSym(SharedLib lib, string name);

/// Close a shared library
void closeSharedLib(SharedLib lib);



version(Posix)
{
    import std.string : toStringz;
    import core.sys.posix.dlfcn;

    SharedLib openSharedLib(string name)
    {
        return dlopen(toStringz(name), RTLD_LAZY);
    }

    SharedSym loadSharedSym(SharedLib lib, string name)
    {
        return dlsym(lib, toStringz(name));
    }

    void closeSharedLib(SharedLib lib)
    {
        dlclose(lib);
    }
}
version(Windows)
{
    import std.string : toStringz;
    import core.sys.windows.winbase;

    SharedLib openSharedLib(string name)
    {
        return LoadLibraryA(toStringz(name));
    }

    SharedSym loadSharedSym(SharedLib lib, string name)
    {
        return GetProcAddress(lib, toStringz(name));
    }

    void closeSharedLib(SharedLib lib)
    {
        FreeLibrary(lib);
    }
}

// SymbolLoader class works, but eat several tons of RAM megabytes during build
// process. Too bad, have to give up clean unloading. Replaced now by
// SharedLibLoader, very similar to derelict

/// Utility that keeps track at compile time of a list of symbols to load and unload.
/// Each symbol can be associated (at compile time) with a Flag!"optional" parameter.
/// If the flag is provided (and set to Yes), the load function will pass over symbols
/// that are not found in the shared object. Otherwise an exception is thrown.
class SymbolLoader(SymbolSpecs...)
{
    import std.meta : AliasSeq;
    import std.traits : isFunctionPointer;
    import std.typecons : Flag, Yes, No;


    private enum defaultSpec = No.optional;

    private template SymSpec(alias s, Flag!"optional" o)
    {
        alias symbol = s;
        enum optional = o;
        static assert(isFunctionPointer!symbol);
        //alias Fn = typeof(symbol);
    }

    private alias SymSpecs = parseSpecs!SymbolSpecs;

    private template parseSpecs(Specs...)
    {
        static if (Specs.length == 0)
        {
            alias parseSpecs = AliasSeq!();
        }
        else static if (Specs.length == 1)
        {
            alias parseSpecs = AliasSeq!(SymSpec!(Specs[0], defaultSpec));
        }
        else static if (is(typeof(Specs[1]) == Flag!"optional"))
        {
            alias parseSpecs = AliasSeq!(
                SymSpec!(Specs[0], Specs[1]),
                parseSpecs!(Specs[2 .. $])
            );
        }
        else
        {
            alias parseSpecs = AliasSeq!(
                SymSpec!(Specs[0], defaultSpec),
                parseSpecs!(Specs[1 .. $])
            );
        }
    }

    private SharedLib _lib;
    private string _libName;


    /// Open the shared library using the provided name list.
    /// The first name in the list that results to a succesful shared object
    /// opening is used and retained in the libName @property.
    /// All others are discareded.
    /// After successful opening, all symbols provided in SymbolSpecs are bound
    /// to symbols loaded in the shared library. Symbols marked as optional are
    /// bound only if they could be found in the library.
    void load(string[] libNames)
    {
        foreach (ln; libNames)
        {
            _lib = openSharedLib(ln);
            if (_lib)
            {
                _libName = ln;
                break;
            }
        }
        if (!_lib)
        {
            import std.conv : to;
            throw new Exception(
                "Cannot load one of shared libs " ~ libNames.to!string
            );
        }
        scope(failure)
        {
            unload();
        }
        foreach(ss; SymSpecs)
        {
            auto name = ss.symbol.stringof;
            if (ss.symbol !is null)
            {
                throw new Exception("Tentative to bind already bound symbol "~ name);
            }
            auto sym = loadSharedSym(_lib, name);
            if (!sym && !ss.optional)
            {
                throw new Exception("Cannot load symbol "~name~" from "~_libName~".");
            }
            ss.symbol = cast(typeof(ss.symbol)) sym;
        }
    }


    /// Returns whether the shared library is open.
    public @property bool loaded() const
    {
        return _lib !is null;
    }

    /// Returns the name of the shared library that was open.
    /// Empty string if not loaded.
    public @property string libName() const
    {
        return _libName;
    }

    /// Unload
    public void unload()
    {
        if (!loaded) return;

        foreach(ss; SymSpecs)
        {
            ss.symbol = null;
        }
        closeSharedLib(_lib);
        _lib = null;
        _libName = [];
    }

}

/// Utility that open a shared library and load symbols from it.
class SharedLibLoader
{
    import std.typecons : Flag, Yes, No;
    private SharedLib _lib;
    private string _libName;

    /// Load the shared libraries and call bindSymbols if succesful.
    void load (string[] libNames)
    {
        foreach (ln; libNames)
        {
            _lib = openSharedLib(ln);
            if (_lib)
            {
                _libName = ln;
                break;
            }
        }
        if (!_lib)
        {
            import std.conv : to;
            throw new Exception(
                "Cannot load one of shared libs " ~ libNames.to!string
            );
        }
        bindSymbols();
    }

    /// Direct handle access
    public @property SharedLib handle()
    {
        return _lib;
    }

    /// Returns whether the shared library is open.
    public @property bool loaded() const
    {
        return _lib !is null;
    }

    /// Returns the name of the shared library that was open.
    /// Empty string if not loaded.
    public @property string libName() const
    {
        return _libName;
    }

    /// Bind a symbol, using the function pointer symbol name.
    void bind(alias f)(Flag!"optional" optional = No.optional)
    {
        immutable name = f.stringof;
        if (f !is null)
        {
            throw new Exception("Tentative to bind already bound symbol "~ name);
        }
        auto sym = loadSharedSym(_lib, name);
        if (!sym && !optional)
        {
            throw new Exception("Cannot load symbol "~name~" from "~_libName~".");
        }
        f = cast(typeof(f)) sym;
    }

    /// Subclasses can override this to bind all the necessary symbols.
    /// Default implementation does nothing.
    void bindSymbols()
    {}
}
