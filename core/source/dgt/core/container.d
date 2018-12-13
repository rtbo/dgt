/// Generic containers module
module dgt.core.container;

/// stack container inspired from GrowableCircularQueue hereunder
struct GrowableStack(T)
{
    import std.traits : Unqual;

    private
    {
        enum defaultInitCap = 4;

        alias StoredT = Unqual!T;

        size_t _length;
        StoredT[] arr;
    }

    this(T[] items...)
    {
        push(items);
    }

    @property bool empty() const pure nothrow @safe @nogc
    {
        return _length == 0;
    }

    @property size_t length() const nothrow @safe @nogc
    {
        return _length;
    }

    void reserve(in size_t num)
    {
        const ns = _length + num;
        if (arr.length < ns) arr.length = ns;
    }

    void push(T[] items...)
    {
        ensureLen(_length + items.length);
        arr[_length .. _length+items.length] = items;
        _length += items.length;
    }

    void push(T item)
    {
        ensureLen(_length + 1);
        arr[_length] = cast(StoredT) item;
        ++_length;
    }

    @property ref inout(T) peek() inout
    {
        assert(!empty);
        return arr[_length - 1];
    }

    T pop()
    {
        assert(!empty);
        _length--;
        T item = cast(T) arr[_length];
        arr[_length] = StoredT.init;
        return item;
    }

    ref inout(T) opIndex(in size_t index) inout
    {
        assert(index < _length);
        return cast(inout(T)) arr[index];
    }

    int opDollar() const pure nothrow @safe @nogc
    {
        return cast(int) length;
    }

    void clear()
    {
        foreach (i; 0 .. _length) {
            arr[i] = T.init;
        }
        _length = 0;
    }

    private void ensureLen(in size_t len)
    out (; arr.length >= len)
    {
        if (len <= arr.length) return;
        if (arr.length == 0) {
            size_t l = defaultInitCap;
            while (l < len) l *= 2;
            arr.length = l;
        }
        else {
            size_t l = arr.length;
            while (l < len) l *= 2;
            arr.length = l;
        }
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

/// Queue container that can be used in a producer/consumer pattern.
/// It can work with multiple producers and/or multiple consumers.
class ThreadSafeQueue(T)
{
    import core.sync.condition : Condition;
    import core.sync.mutex : Mutex;
    import std.container.dlist : DList;

    this()
    {
        _mutex = new Mutex;
        _cond = new Condition(_mutex);
    }

    this(Stuff)(Stuff stuff)
    {
        this();
        insertBack(stuff);
    }

    @property bool empty()
    {
        _mutex.lock();
        scope(exit) _mutex.unlock();
        return _items.empty;
    }

    @property T front()
    {
        _mutex.lock();
        scope(exit) _mutex.unlock();
        return _items.front;
    }

    void popFront()
    {
        _mutex.lock();
        scope(exit) _mutex.unlock();
        _items.removeFront();
    }

    size_t insertBack(Stuff)(Stuff stuff)
    if (is(typeof(_items.insertBack(stuff))))
    {
        enum Notify {
            none, one, all
        }
        Notify notify = void;
        size_t res = void;
        {
            _mutex.lock();
            scope(exit) _mutex.unlock();
            immutable wasEmpty = _items.empty;
            res = _items.insertBack(stuff);
            if (!wasEmpty)
                notify = Notify.none;
            else if (res == 1)
                notify = Notify.one;
            else
                notify = Notify.all;
        }
        if (notify == Notify.one) _cond.notify();
        else if (notify == Notify.all) _cond.notifyAll();
        return res;
    }

    void waitForData()
    {
        _mutex.lock();
        scope(exit) _mutex.unlock();
        while(_items.empty) {
            _cond.wait();
        }
    }

    T waitAndPop()
    {
        _mutex.lock();
        scope(exit) _mutex.unlock();
        while(_items.empty) {
            _cond.wait();
        }
        auto res = _items.front();
        _items.removeFront();
        return res;
    }

    bool tryPop(out T value)
    {
        _mutex.lock();
        scope(exit) _mutex.unlock();
        if (_items.empty) return false;
        value = _items.front();
        _items.removeFront();
        return true;
    }

    private DList!T _items;
    private Mutex _mutex;
    private Condition _cond;
}
