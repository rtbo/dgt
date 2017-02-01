/// Reference counting of Disposable resources
module dgt.core.arc;

import dgt.core.resource : Disposable;

import std.typecons : Flag, Yes, No;


alias Rc(T) = GenRc!(T, No.atomic);
alias Weak(T) = GenWeak!(T, No.atomic);
alias Arc(T) = GenRc!(T, Yes.atomic);
alias Aweak(T) = GenWeak!(T, Yes.atomic);


struct SelfRcSeal(T, Flag!"atomic" atomic)
{
    private GenWeak!(T, atomic) _selfWeak;

    public @property GenRc!(T, atomic) selfRc()
    {
        return _selfWeak.lock;
    }
}

mixin template SelfRc(T)
if (is(T : Disposable))
{
    private SelfRcSeal!(T, No.atomic) _selfRcSeal;

    public @property ref SelfRcSeal!(T, No.atomic) selfRcSeal()
    {
        return _selfRcSeal;
    }

    public @property Rc!T selfRc()
    {
        return _selfRcSeal.selfRc;
    }
}

mixin template SelfArc(T)
if (is(T : Disposable))
{
    private SelfRcSeal!(T, Yes.atomic) _selfRcSeal;

    public @property ref SelfRcSeal!(T, Yes.atomic) selfRcSeal()
    {
        return _selfRcSeal;
    }

    public @property Rc!T selfArc()
    {
        return _selfRcSeal.selfRc;
    }
}


version(unittest)
{
    import std.stdio : writeln;

    int rcCount = 0;
    int structCount = 0;

    class RcClass : Disposable
    {
        this()
        {
            rcCount += 1;
        }

        override void dispose()
        {
            rcCount -= 1;
        }
    }

    struct RcStruct
    {
        Rc!RcClass obj;
    }

    struct RcArrStruct
    {
        Rc!RcClass[] objs;

        ~this()
        {
            foreach(ref o; objs)
            {
                o = Rc!RcClass.init;
            }
        }
    }

    struct RcArrIndStruct
    {
        RcStruct[] objs;

        ~this()
        {
            foreach(ref o; objs)
            {
                o = RcStruct.init;
            }
        }
    }

    unittest
    {
        {
            auto arr = RcArrStruct([Rc!RcClass.make(), Rc!RcClass.make()]);
            assert(rcCount == 2);
            foreach(obj; arr.objs)
            {
                assert(rcCount == 2);
            }
            assert(rcCount == 2);
        }
        assert(rcCount == 0);
    }


    unittest
    {
        {
            auto obj = Rc!RcClass.make();
            assert(rcCount == 1);
        }
        assert(rcCount == 0);
    }

    unittest
    {
        {
            auto obj = Rc!RcClass(new RcClass);
            assert(rcCount == 1);
        }
        assert(rcCount == 0);
    }

    unittest
    {
        {
            auto obj = RcStruct(Rc!RcClass.make());
            assert(rcCount == 1);
        }
        assert(rcCount == 0);
    }
}


// general principle is same as libcxx memory, although weak count is not
// tracked as actual memory is GC managed.

struct GenRc(T, Flag!"atomic" atomic)
if (is(T : Disposable))
{
    alias Rc = GenRc!(T, atomic);
    alias Weak = GenWeak!(T, atomic);
    private alias SC = SharedCount!(atomic);

    private T _obj;
    private SC _sc;

    invariant()
    {
        assert((_obj is null) == (_sc is null));
    }

    static Rc make(Args...)(Args args)
    {
        alias ThisSC = SharedCountEmplace!(T, atomic);
        auto sc = new ThisSC(args);
        sc.retain();
        auto rc = Rc(sc._obj, sc);
        static if (__traits(compiles, _obj.selfRcSeal))
        {
            rc._obj.selfRcSeal._selfWeak = GenWeak!(T, atomic)(rc);
        }
        return rc;
    }

    this(this)
    {
        if (_sc) _sc.retain();
    }

    ~this()
    {
        if (_sc)
        {
            _sc.release();
            _obj = null;
            _sc = null;
        }
    }

    void opAssign(Rc rc)
    {
        import std.algorithm : swap;
        swap(rc, this);
    }

    void opAssign(U)(GenRc!(U, atomic) rc)
    if (is(U : T))
    {
        reset();
        if (rc)
        {
            _obj = rc._obj;
            _sc = rc._sc;
        }
    }

    bool opCast(T : bool)() const
    {
        return (_sc !is null);
    }

    U opCast(U : GenRc!(V, atomic), V)()
    if (is(typeof(cast(V)T.init)))
    {
        if (_sc)
        {
            _sc.retain();
            return U(cast(V)_obj, _sc);
        }
        else
        {
            return U.init;
        }
    }

    void reset()
    {
        if(_sc)
        {
            _sc.release();
            _obj = null;
            _sc = null;
        }
    }

    @property inout(T) obj() inout
    {
        return _obj;
    }

    alias obj this;
}


struct GenWeak(T, Flag!"atomic" atomic)
if (is(T : Disposable))
{
    alias Rc = GenRc!(T, atomic);
    alias Weak = GenWeak!(T, atomic);
    private alias SC = SharedCount!(atomic);

    private T _obj;
    private SC _sc;

    invariant()
    {
        assert((_obj is null) == (_sc is null));
    }

    this(Rc rc)
    {
        _obj = rc._obj;
        _sc = rc._sc;
    }

    this(U)(GenRc!(U, atomic) rc)
    if (is(U : T))
    {
        _obj = rc._obj;
        _sc = rc._sc;
    }

    this(U)(GenWeak!(U, atomic) weak)
    if (is(U : T))
    {
        _obj = rc._obj;
        _sc = rc._sc;
    }

    void opAssign(Rc rc)
    {
        _obj = rc._obj;
        _sc = rc._sc;
    }

    void opAssign(U)(GenRc!(U, atomic) rc)
    if (is(U : T))
    {
        _obj = rc._obj;
        _sc = rc._sc;
    }

    void opAssign(U)(GenWeak!(U, atomic) weak)
    if (is(U : T))
    {
        _obj = weak._obj;
        _sc = weak._sc;
    }

    Rc lock()
    {
        Rc rc;
        rc._sc = _sc ? _sc.lock() : _sc;
        if (rc._sc)
        {
            rc._obj = _obj;
        }
        else
        {
            _obj = null;
            _sc = null;
        }
        return rc;
    }

    void reset()
    {
        _obj = null;
        _sc = null;
    }
}




private:

import core.atomic;

abstract class SharedCount(Flag!"atomic" atomic)
{
    static if (atomic)
    {
        shared size_t _count;
        debug shared bool _disposed;

        @property size_t count() const
        {
            return atomicLoad(_count);
        }

        debug @property bool disposed() const
        {
            return atomicLoad(_disposed);
        }

        void retain()
        {
            assert(!disposed);

            atomicOp!"+="(_count, 1);
        }

        void release()
        {
            assert(!disposed);
            assert(count > 0);

            if (atomicOp!"-="(_count, 1) == 0)
            {
                debug { atomicStore(_disposed, true); }
                onZero();
                return true;
            }
            return false;
        }

        // for weak only
        SharedCount!(Yes.atomic) lock()
        {
            while (1)
            {
                immutable c = atomicLoad(_count);

                if (c == 0) return null;
                if (cas(&_count, c, c+1)) return this;
            }
        }
    }
    else
    {
        size_t _count;
        debug bool _disposed;

        @property size_t count() const
        {
            return _count;
        }

        debug @property bool disposed() const
        {
            return _disposed;
        }

        void retain()
        {
            assert(!disposed);
            ++_count;
        }

        bool release()
        {
            assert(!disposed);
            assert(count > 0);

            if ((--_count) == 0)
            {
                debug { _disposed = true; }
                onZero();
                return true;
            }
            return false;
        }

        // for weak only
        SharedCount!(No.atomic) lock()
        {
            if (_count)
            {
                ++_count;
                return this;
            }
            else
            {
                return null;
            }
        }
    }

    protected abstract void onZero();
}

class SharedCountRef(T, Flag!"atomic" atomic) : SharedCount!atomic
if (is(T : Disposable))
{
    T _obj;

    this(T obj)
    {
        assert(obj);
        _obj = obj;
    }

    protected override void onZero()
    {
        _obj.dispose();
        _obj = null;
    }
}


class SharedCountEmplace(T, Flag!"atomic" atomic) : SharedCount!atomic
if (is(T : Disposable))
{
    void[__traits(classInstanceSize, T)] _buf;
    T _obj;

    this(Args...)(Args args)
    {
        import std.conv : emplace;
        _obj = emplace!T(_buf[], args);
    }

    protected override void onZero()
    {
        _obj.dispose();
        destroy(_obj);
        _buf = typeof(_buf).init;
    }
}
