module dgt.bindings;

/// A handle to a shared library
alias SharedLib = void*;
/// A handle to a shared library symbol
alias SharedSym = void*;

/// Opens a shared library
SharedLib openSharedLib(string name);

/// Load a symbol from a shared library
SharedSym loadSharedSym(SharedLib lib, string name);

/// Close a shared library
void closeSharedLib(SharedLib lib);


/// Foreign function symbol in a shared library.
/// Unsuitable to extern symbols that are not functions (i.e. extern global variables)
/// This struct has knowledge on the type signature, but no knowledge on the
/// symbol name. Typically, symbol name is known at compile time by using aliases to instance
/// of the struct.
struct Symbol(RetT, Args...)
{
    /// Alias to the foreign function type
    public alias Fn = extern(C) RetT function (Args) nothrow @nogc;
    private Fn fn_;

    /// Bind the symbol to the loaded function
    public void bind(SharedSym sym)
    in
    {
        assert(!bound, "rebinding of already bound symbol");
    }
    body
    {
        fn_ = cast(Fn) sym;
    }

    /// Unbind the symbol
    public void unbind()
    {
        fn_ = null;
    }

    /// Check weither the symbol is already bound.
    public @property bool bound()
    {
        return fn_ !is null;
    }

    /// Call the symbol with the provided args.
    public RetT opCall(Args...)(Args args)
    in
    {
        assert(bound, "call to unbound function pointer");
    }
    body
    {
        return fn_(args);
    }
}


unittest
{
    static extern(C) int symbolTestMul2(int p) nothrow @nogc
    {
        return 2*p;
    }

    Symbol!(int, int) mul2;
    static assert(is(mul2.Fn == typeof(&symbolTestMul2)));
    mul2.set(&symbolTestMul2);
    assert(mul2(42) == 84);
}

/// Utility that keeps track at compile time of a list of symbols to load and unload.
/// Each symbol can be associated (at compile time) with a Flag!"optional" parameter.
/// If the flag is provided (and set to Yes), the load function will pass over symbols
/// that are not found in the shared object. Otherwise an exception is thrown.
struct SymbolLoader(SymbolSpecs...)
{
    import std.meta : AliasSeq;
    import std.traits : isInstanceOf;
    import std.typecons : Flag, Yes, No;

    private SharedLib lib_;
    private string libName_;

    private enum defaultSpec = No.optional;

    private template SymSpec(alias s, Flag!"optional" o)
    {
        static assert(isInstanceOf!(Symbol, typeof(symbol)));
        alias symbol = s;
        enum optional = o;
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

    /// Open the shared library using the provided name list.
    /// The first name in the list that results to a succesful shared object
    /// opening is used and retained in the libName @property.
    /// All others are discareded.
    /// After successful opening, all symbols provided in SymbolSpecs are bound
    /// to symbols loaded in the shared library.
    public void load(string[] libNames)
    in
    {
        assert(!loaded);
    }
    body
    {
        foreach(n; libNames)
        {
            lib_ = openSharedLib(n);
            libName_ = n;
            break;
        }
        if (!lib_)
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
            if (ss.symbol.bound)
            {
                throw new Exception("Tentative to bind already bound symbol "~ name);
            }
            auto sym = loadSharedSym(lib_, name);
            if (!sym && !ss.optional)
            {
                throw new Exception("Cannot load symbol "~name~" from "~libName_~".");
            }
            ss.symbol.bind(cast(ss.symbol.Fn) sym);
        }
    }

    /// Returns weither the shared library is open.
    public @property bool loaded() const
    {
        return lib_ !is null;
    }

    /// Returns the name of the shared library that was open.
    /// Empty string if not loaded.
    public @property string libName() const
    {
        return libName_;
    }

    /// Unload
    public void unload()
    {
        if (!loaded) return;

        foreach(sd; SymSpecs)
        {
            sd.symbol.unbind();
        }
        closeSharedLib(lib_);
        lib_ = null;
        libName_ = [];
    }

}



/// Brings enumerants into global scope to mimic C visibility.
/// Generated code must be mixed-in in the module the enum is defined.
@property string globalEnumsAliasesCode(Enums...)()
{
    import std.traits : EnumMembers;
    import std.conv : to;

    string code;
    foreach(Enum; Enums)
    {
        foreach(immutable memb; EnumMembers!Enum)
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
