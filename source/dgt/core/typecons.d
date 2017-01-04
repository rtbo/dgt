module dgt.core.typecons;

import std.meta : AliasSeq;

/// Integer range that is known at compile time and that unrolls foreach loops.
template staticRange(int from, int to, int step = 1)
        if (((step > 0 && from <= to) || (step < 0 && from >= to)) && ((to - from) % step == 0))
{
    static if (from == to)
    {
        alias staticRange = AliasSeq!();
    }
    else
    {
        alias staticRange = AliasSeq!(from, staticRange!(from + step, to, step));
    }
}

unittest
{
    int[] vals;
    foreach (v; staticRange!(0, 18, 3))
    {
        enum vv = v;
        vals ~= vv;
    }
    assert(vals == [0, 3, 6, 9, 12, 15]);

    vals = [];
    foreach (v; staticRange!(4, 8))
    {
        enum vv = v;
        vals ~= vv;
    }
    assert(vals == [4, 5, 6, 7]);

    vals = [];
    foreach (v; staticRange!(8, 4, -1))
    {
        enum vv = v;
        vals ~= vv;
    }
    assert(vals == [8, 7, 6, 5]);

    // test rejection because of unfitting step
    static assert(!__traits(compiles, staticRange!(0, 11, 3)));
}

/// Computes a string hash at compile time.
template hash(string s, size_t sofar=0)
{
    static if (s.length == 0)
        enum hash = sofar;
    else
        enum hash = hash!(s[1 .. $], sofar * 11 + s[0]);
}

/// stack container inspired from GrowableCircularQueue hereunder
struct GrowableStack(T)
{
    import std.traits : Unqual;

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

/// queue container from http://rosettacode.org/wiki/Queue/Usage#Faster_Version
struct GrowableCircularQueue(T)
{
    import std.traits : hasIndirections;

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
