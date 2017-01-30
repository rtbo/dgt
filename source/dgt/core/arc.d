/// Reference counting of Disposable resources
module dgt.core.arc;

import dgt.core.resource : Disposable;

import std.typecons : Flag, Yes, No;


alias Rc(T) = GenRc!(T, No.atomic).Rc;
alias Weak(T) = GenRc!(T, No.atomic).Weak;
alias Arc(T) = GenRc!(T, Yes.atomic).Rc;
alias Aweak(T) = GenRc!(T, Yes.atomic).Weak;


private:

template GenRc(T, Flag!"atomic" atomic)
if (is(T : Disposable))
{
    alias SC = SharedCount!(atomic);

    struct Rc
    {
        private T _obj;
        private SC _sc;

        invariant()
        {
            assert((_obj is null) == (_sc is null));
        }

        private this(T obj, SC sc)
        {
            _obj = obj;
            _sc = sc;
        }

        static GenRc make(Args...)(Args args)
        {
            alias ThisSC = SharedCountEmplace!(T, atomic);
            auto sc = new ThisSC(args);
            sc.retain();
            return Rc(sc._obj, sc);
        }

        this (U)(U obj)
        if (is(U : T))
        {
            if (obj)
            {
                alias ThisSC = SharedCountRef!(U, atomic);
                _obj = obj;
                _sc = new ThisSC(obj);
                _sc.retain();
            }
        }

        this(this)
        {
            if (_sc) _sc.retain();
        }

        ~this()
        {
            if (_sc && _sc.release())
            {
                _obj = null;
                _sc = null;
            }
        }

        void opAssign(U)(U obj)
        if (is(U : T))
        {
            reset(obj);
        }

        void opAssign(U)(GenRc!(U, atomic).Rc rc)
        if (is(U : T))
        {
            reset();
            if (rc)
            {
                _obj = rc._obj;
                _sc = rc._sc;
                _sc.retain();
            }
        }

        bool opCast(T : bool)() const
        {
            return (_sc !is null);
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

        void reset(U)(U obj)
        if (is(U : T))
        {
            reset();

            if (obj)
            {
                alias ThisSC = SharedCountRef!(U, atomic);
                _obj = obj;
                _sc = new ThisSC(obj);
                _sc.retain();
            }
        }

        @property inout(T) obj() inout
        {
            return _obj;
        }

        alias obj this;
    }


    struct Weak
    {
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

        this(U)(GenRc!(U, atomic).Rc rc)
        if (is(U : T))
        {
            _obj = rc._obj;
            _sc = rc._sc;
        }

        this(U)(GenRc!(U, atomic).Weak weak)
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

        void opAssign(U)(GenRc!(U, atomic).Rc rc)
        if (is(U : T))
        {
            _obj = rc._obj;
            _sc = rc._sc;
        }

        void opAssign(U)(GenRc!(U, atomic).Weak weak)
        if (is(U : T))
        {
            _obj = rc._obj;
            _sc = rc._sc;
        }

        Rc lock()
        {
            Rc rc;
            rc._sc = _sc ? _sc.lock() : _sc;
            if (rc._sc)
            {
                rc._obj = obj;
            }
            return rc;
        }

        void reset()
        {
            _obj = null;
            _sc = null;
        }
    }
}



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

class SharedCountRef(T, Flag!"atomic" atomic)
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
    }
}


class SharedCountEmplace(T, Flag!"atomic" atomic)
if (is(T : Disposable))
{
    void[_traits(classInstanceSize, T)] _buf;
    T _obj;

    this(Args...)(Args args)
    {
        import std.conv : emplace;
        _obj = emplace!T(_buf[], args);
    }

    protected override void onZero()
    {
        _obj.dispose();
    }
}
