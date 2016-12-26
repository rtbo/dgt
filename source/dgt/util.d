/// The obligatory junk module with unsortable and essential utilities.
module dgt.util;

import std.meta : AliasSeq;
import std.traits : Unqual, hasIndirections;

/// Integer range that is known at compile time and that unrolls foreach loops.
template StaticRange(int from, int to, int step = 1)
        if (((step > 0 && from <= to) || (step < 0 && from >= to)) && ((to - from) % step == 0))
{
    static if (from == to)
    {
        alias StaticRange = AliasSeq!();
    }
    else
    {
        alias StaticRange = AliasSeq!(from, StaticRange!(from + step, to, step));
    }
}

unittest
{
    int[] vals;
    foreach (v; StaticRange!(0, 18, 3))
    {
        enum vv = v;
        vals ~= vv;
    }
    assert(vals == [0, 3, 6, 9, 12, 15]);

    vals = [];
    foreach (v; StaticRange!(4, 8))
    {
        enum vv = v;
        vals ~= vv;
    }
    assert(vals == [4, 5, 6, 7]);

    vals = [];
    foreach (v; StaticRange!(8, 4, -1))
    {
        enum vv = v;
        vals ~= vv;
    }
    assert(vals == [8, 7, 6, 5]);

    // test rejection because of unfitting step
    static assert(!__traits(compiles, StaticRange!(0, 11, 3)));
}

// some traits

template isRefType(T)
{
    enum isRefType = is(T == interface) || is(T == class);
}

template isConcrete(T)
{
    enum isConstructible = !is(T == interface) && !__traits(isAbstractClass, T);
}

package template EmplaceSize(T) if (isConstructible!T)
{
    static if (is(T == class))
    {
        enum EmplaceSize = __traits(classInstanceSize, T);
    }
    else
    {
        enum EmplaceSize = T.sizeof;
    }
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
mixin template ReadOnlyValueProperty(string __name, T, T defaultVal = T.init)
{
    mixin("private T _" ~ __name ~ " = defaultVal;");

    mixin("public @property T " ~ __name ~ "() const { return _" ~ __name ~ "; }");
}

/// the expression:
///
/// mixin SignalValueProperty!("title", string);
///
/// will generate the following declarations:
///
/// private string _title;
/// private FireableSignal!string _onTitleChange = new FireableSignal!string;
///
/// public @property string title() const { return _title; }
/// public @property void title(string value) {
///     if (value != _title) {
///         _title = value;
///         onTitleChange_.fire(value);
///     }
/// }
/// public @property Signal!string onTitleChange() { return onTitleChange_; }
///
mixin template SignalValueProperty(string __name, T, T defaultVal = T.init)
{
    import dgt.signal;
    import std.traits;

    // the present value type definition is "type without aliasing"
    static assert(!hasAliasing!(T));

    mixin("private T _" ~ __name ~ " = defaultVal;");
    mixin("private FireableSignal!T _" ~ onChangeSigName(__name) ~ " = new FireableSignal!T;");

    mixin("public @property T " ~ __name ~ "() const { return _" ~ __name ~ "; }");
    mixin("public @property void " ~ __name ~ "(T value) {\n" ~ "    if (value != _" ~ __name ~ ") {\n" ~ //"        writeln(\"writing "~__name~":\", value);\n" ~
            "        _" ~ __name
            ~ " = value;\n" ~ "        _" ~ onChangeSigName(
                __name) ~ ".fire(value);\n" ~ "    }\n" ~ "}");
    mixin("public @property Signal!T " ~ onChangeSigName(
            __name) ~ "() {\n" ~ "    return _" ~ onChangeSigName(__name) ~ ";\n" ~ "}");

}

mixin template SmiSignalMixin(string __name, Iface)
{
    import dgt.signal;

    static assert(isSmi!Iface, "SmiSignalMixin must be used with 'Single Method Interface's");

    mixin("private FireableSmiSignal!Iface _" ~ __name ~ " = new FireableSmiSignal!Iface;");

    mixin("public @property SmiSignal!Iface " ~ __name ~ "() { return _" ~ __name ~ "; }");
}

mixin template SignalMixin(string __name, T...)
{
    import dgt.signal;

    mixin("private FireableSignal!T _" ~ __name ~ " = new FireableSignal!T;");

    mixin("public @property Signal!T " ~ __name ~ "() { return _" ~ __name ~ "; }");
}

mixin template EventHandlerSignalMixin(string __name, HandlerT)
{
    import dgt.signal;

    mixin("private FireableEventHandlerSignal!HandlerT _" ~ __name ~ " =\n"
            ~ "    new FireableEventHandlerSignal!HandlerT;");

    mixin("public @property EventHandlerSignal!HandlerT " ~ __name ~ "() { return _" ~ __name
            ~ "; }");
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

// stack container inspired from GrowableCircularQueue hereunder
struct GrowableStack(T)
{

    private
    {

        alias StoredT = Unqual!T;

        static if (is(T == class) || is(T == interface))
        {
            alias RefT = T;
        }
        else
        {
            alias RefT = ref T;
        }

        size_t length_;
        StoredT[] arr = [StoredT.init];

    }

    this(T[] items...)
    {
        push(items);
    }

    @property bool empty() const pure nothrow @safe @nogc
    {
        return length_ == 0;
    }

    @property size_t length() const nothrow @safe @nogc
    {
        return length_;
    }

    void push(T[] items...)
    {
        foreach (item; items)
            push(item);
    }

    void push(T item)
    {
        if (length_ >= arr.length)
        {
            arr.length *= 2;
        }
        arr[length_] = cast(StoredT) item;
        ++length_;
    }

    @property inout(RefT) peek() inout
    {
        assert(!empty);
        return arr[length_ - 1];
    }

    T pop()
    {
        assert(!empty);
        length_--;
        T item = cast(T) arr[length_];
        arr[length_] = StoredT.init;
        return item;
    }

    inout(RefT) opIndex(in size_t index) inout
    {
        assert(index < length_);
        return cast(inout(RefT)) arr[index];
    }

    int opDollar() const pure nothrow @safe @nogc
    {
        return cast(int) length;
    }

}

unittest
{
    GrowableStack!int s;
    s.push(12, 24, 36);
    assert(s.length == 3);
    assert(s[0] == 12);
    assert(s[$ - 1] == 36);
    assert(s[$ - 2] == s[1]);
    assert(s.peek == 36);
    assert(s.pop() == 36);
    assert(s.pop() == 24);
    assert(s.pop() == 12);
    assert(s.empty);
}

// queue container from http://rosettacode.org/wiki/Queue/Usage#Faster_Version

struct GrowableCircularQueue(T)
{
    public size_t length;
    private size_t first, last;
    private T[] A = [T.init];

    this(T[] items...) pure nothrow @safe
    {
        foreach (x; items)
            push(x);
    }

    @property bool empty() const pure nothrow @safe @nogc
    {
        return length == 0;
    }

    @property T front() pure nothrow @safe @nogc
    {
        assert(length != 0);
        return A[first];
    }

    T opIndex(in size_t i) pure nothrow @safe @nogc
    {
        assert(i < length);
        return A[(first + i) & (A.length - 1)];
    }

    void push(T item) pure nothrow @safe
    {
        if (length >= A.length)
        { // Double the queue.
            immutable oldALen = A.length;
            A.length *= 2;
            if (last < first)
            {
                A[oldALen .. oldALen + last + 1] = A[0 .. last + 1];
                static if (hasIndirections!T)
                    A[0 .. last + 1] = T.init; // Help for the GC.
                last += oldALen;
            }
        }
        last = (last + 1) & (A.length - 1);
        A[last] = item;
        length++;
    }

    @property T pop() pure nothrow @safe @nogc
    {
        assert(length != 0);
        auto saved = A[first];
        static if (hasIndirections!T)
            A[first] = T.init; // Help for the GC.
        first = (first + 1) & (A.length - 1);
        length--;
        return saved;
    }
}

unittest
{

    GrowableCircularQueue!int q;
    q.push(10);
    q.push(20);
    q.push(30);
    assert(q.pop == 10);
    assert(q.pop == 20);
    assert(q.pop == 30);
    assert(q.empty);

}
