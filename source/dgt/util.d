/// The obligatory junk module with unsortable and essential utilities.
module dgt.util;

import std.traits : Unqual, hasIndirections;

/// Computes a string hash at compile time.
template hash(string s, size_t sofar=0)
{
    static if (s.length == 0)
        enum hash = sofar;
    else
        enum hash = hash!(s[1 .. $], sofar * 11 + s[0]);
}

// GC utilities

void hideFromGC(void* location)
{
    import core.memory : GC;

    GC.addRoot(location);
    GC.setAttr(location, GC.BlkAttr.NO_MOVE);
}

void exposeToGC(void* location)
{
    import core.memory : GC;

    GC.removeRoot(location);
    GC.clrAttr(location, GC.BlkAttr.NO_MOVE);
}

// productivity mixin utils

mixin template ValueProperty(string __name, T, T defaultVal = T.init)
{
    mixin("private T _" ~ __name ~ " = defaultVal;");

    mixin("public @property T " ~ __name ~ "() const { return _" ~ __name ~ "; }");
    mixin("public @property void " ~ __name ~ "(T value) { _" ~ __name ~ " = value; }");
}
mixin template ReadOnlyValueProperty(T, string __name, T defaultVal = T.init)
{
    mixin("private T _" ~ __name ~ " = defaultVal;");

    mixin("public @property T " ~ __name ~ "() const { return _" ~ __name ~ "; }");
}


// some utility to compose mixin templates

/// capitalize first letter and leave others untouched
string capitalizeFst(string input)
in
{
    assert(input.length > 0);
}
body
{
    import std.uni;
    import std.conv;

    return ([toUpper(input[0].to!dchar)] ~ input[1 .. $].to!dstring).to!string;
}

/// turns "title" into "onTitleChange"
string onChangeSigName(string name)
{
    return "on" ~ name.capitalizeFst() ~ "Change";
}

// checking compile-time functionality
static assert(capitalizeFst("name") == "Name");
static assert(onChangeSigName("name") == "onNameChange");

/// Check whether T is a reference type, that is class, interface or pointer.
template isReference(T)
{
    import std.traits : isPointer;
    enum isReference = is(T == class) || is(T == interface) || isPointer!T;
}

version (unittest)
{
    static assert(isReference!Object);
    static assert(isReference!Exception);
    static assert(!isReference!int);
    static assert(isReference!(const(char)*));
}

/// Generate a unique filename based on provided model.
/// Every '%' in model will be replaced by a random hexa char (from 0 to f).
/// The function checks that the proposed filename does not exist.
string getUniqueTempFile(string model)
{
    import std.file : tempDir, exists, isDir;
    import std.path : chainPath;
    import std.conv : to;
    import std.random : uniform;
    import std.experimental.logger : error;

    string result;
    immutable td = tempDir();
    enum maxAttempts = 32;
    int attempts = 0;
    do
    {
        auto fn = model.dup;
        foreach (ref c; fn)
        {
            if (c == '%') c = "0123456789abcdef"[uniform(0, 15)];
        }
        result = chainPath(td, fn).to!string;
        ++attempts;
    }
    while(attempts < maxAttempts && (!exists(result) || isDir(result)));

    if (attempts >= maxAttempts)
        error("Cannot generate a unique file name");

    return result;
}
