module dgt.rc;

/// A resource that can be disposed
interface Disposable
{
    /// Dispose the underlying resource
    void dispose();
}

/// A reference counted resource
interface RefCounted : Disposable
{
    /// The number of active references
    @property size_t refCount() const;

    /// Increment the reference count
    void retain();

    /// Decrement the reference count and dispose if it reaches zero
    void release()
    in { assert(refCount > 0); }

    override void dispose()
    in { assert(refCount == 0); } // add additional contract condition
}

/// A string that can be mixed-in a class declaration to implement RefCounted.
/// Disposable implementation is not given.
enum rcCode = buildRcCode();

/// Helper that build a new instance of T and returns it within a Rc!T
template makeRc(T) if (is(T : RefCounted))
{
    Rc!T makeRc(Args...)(Args args)
    {
        return Rc!T(new T(args));
    }
}

/// Helper that places an instance of T within a Rc!T
template rc(T) if (is(T : RefCounted))
{
    Rc!T rc(T obj)
    {
        return Rc!T(obj);
    }
}

/// Helper struct that manages the reference count of an object using RAII.
template Rc(T) if (is(T:RefCounted))
{
    struct Rc
    {
        private T _obj;

        this(T obj)
        {
            assert(obj !is null);
            _obj = obj;
            _obj.retain();
        }

        this(this)
        {
            if (_obj) _obj.retain();
        }

        ~this()
        {
            if(_obj) _obj.release();
        }

        void opAssign(T obj)
        {
            if(_obj) _obj.release();
            _obj = obj;
            if(_obj) _obj.retain();
        }

        bool opCast(T : bool)() const
        {
            return loaded;
        }

        @property bool loaded() const
        {
            return _obj !is null;
        }

        void unload()
        {
            if(_obj)
            {
                _obj.release();
                _obj = null;
            }
        }

        @property inout(T) obj() inout { return _obj; }

        alias obj this;
    }
}



private string buildRcCode()
{
    version(rcAtomic)
    {
        return q{
            private shared size_t _refCount=0;

            public override @property size_t refCount() const
            {
                import core.atomic : atomicLoad;
                return atomicLoad(_refCount);
            }

            public override void retain()
            {
                import core.atomic : cas;
                int oldRc = void;
                do
                {
                    oldRc = _refCount;
                }
                while(!cas(&_refCount, oldRc, oldRc+1));
                version(rcDebug) {
                    import std.experimental.logger : logf;
                    logf("retain %s: %s", typeof(this).stringof, oldRc+1);
                }
            }

            public override void release()
            {
                import core.atomic : cas;
                int oldRc = void;
                do
                {
                    oldRc = _refCount;
                }
                while(!cas(&_refCount, oldRc, oldRc-1));
                version(rcDebug)
                {
                    import std.experimental.logger : logf;
                    logf("release %s: %s", typeof(this).stringof, oldRc-1);
                }
                if (oldRc == 1)
                {
                    version(rcDebug)
                    {
                        import std.experimental.logger : logf;
                        logf("dispose %s", typeof(this).stringof);
                    }
                    dispose();
                }
            }
        };
    }
    else
    {
        return q{
            private size_t _refCount=0;

            public override @property size_t refCount() const { return _refCount; }

            public override void retain()
            {
                _refCount += 1;
                version(rcDebug)
                {
                    import std.experimental.logger : logf;
                    logf("retain %s: %s", typeof(this).stringof, refCount);
                }
            }

            public override void release()
            {
                _refCount -= 1;
                version(rcDebug)
                {
                    import std.experimental.logger : logf;
                    logf("release %s: %s", typeof(this).stringof, refCount);
                }
                if (!refCount)
                {
                    version(rcDebug)
                    {
                        import std.experimental.logger : logf;
                        logf("dispose %s", typeof(this).stringof);
                    }
                    dispose();
                }
            }
        };
    }
}


version(unittest)
{
    import std.stdio : writeln;

    int rcCount = 0;
    int structCount = 0;

    class RcClass : RefCounted
    {
        mixin(rcCode);

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
            auto arr = RcArrStruct([makeRc!RcClass(), makeRc!RcClass()]);
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
            auto obj = makeRc!RcClass();
            assert(rcCount == 1);
        }
        assert(rcCount == 0);
    }

    unittest
    {
        {
            auto obj = RcStruct(makeRc!RcClass());
            assert(rcCount == 1);
        }
        assert(rcCount == 0);
    }
}


template isRuntimeRc(T)
{
    enum isRuntimeRc = is(T : RefCounted);
}

static assert(isRuntimeRc!RefCounted);
