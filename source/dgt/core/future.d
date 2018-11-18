/// Provides Future/Promise synchronization
module dgt.core.future;

import std.traits : isCallable, Parameters, ReturnType;

/// Status flag for Promise
private enum Status : ubyte
{
    /// Value or Exception was not set
    notDone,
    /// Value or Exception was set
    done,
}

/// Wait policy for Promise
enum WaitPolicy
{
    /// Wait is done by spinning on the CPU. Should be used for short time scale
    /// tasks, i.e. shorter than a context switch.
    spin,
    /// Wait by blocking on a condition variable
    block,
}

/// Future is an object that can resolve to a value or exception set in a
/// different thread, or the same thread, possibly in a different frame
/// (the value or exception are stored until resolve is called)
struct Future(T)
{
    private shared(SharedState!T) state;

    /// Check if it is valid to call resolve
    @property bool valid()
    {
        return state && state.valid;
    }

    /// Resolve the value or exception.
    /// This can involve to wait for a task to finish in a different thread.
    T resolve()
    in (valid, "Future must be valid when resolve is called")
    {
        return state.resolve();
    }
}

/// Spawns func in a different thread, passing it args, and return a Future
/// object whose resolve method will wait for func completion and return its value
/// or throw an exception that was not catched in func.
/// Returns: A valid future to resolve the given func
auto async(alias func, Args...)(Args args)
if (is(typeof(func(args))))
{
    Task!func t;
    auto f = t.future;
    t.callAsync(args);
    return f;
}

/// ditto
auto async(F, Args...)(F func, Args args)
if (is(typeof(func(args))))
{
    Task!(run, F) t = { callable : func };
    auto f = t.future;
    t.callAsync(args);
    return f;
}


/// Build a Task that encapsulate func
auto task(alias func)()
{
    Task!func t;
    return t;
}

/// ditto
auto task(F)(F func)
if (isCallable!F)
{
    Task!(run, F) t = { callable : func };
    return t;
}


/// Encapsulate a function whose result (return value or exception) is to be retrieved
/// with a Future, possibly in a different thread than the thread executing the function.
struct Task(alias func, F=void)
if (is(F == void) || (isCallable!F && __traits(isSame, func, run)))
{
    static if (is(F == void)) {
        private alias T = ReturnType!func;
    }
    else {
        private alias T = ReturnType!F;
        private F callable;
    }

    private alias SS = TaskSharedState!T;

    private shared(SS) state;

    /// Get the future for this task.
    /// The future will be valid only when this task will start execution.
    @property Future!T future()
    {
        if (!state) state = new SS;
        return Future!T(state);
    }

    /// Spawn a thread into which the function is called with args as parameters
    void callAsync(Args...)(Args args)
    {
        import core.thread : Thread;

        if (!state) state = new SS;

        static if (!is(F == void)) {
            // push callable on the stack to make frame on the heap
            // due to thread delegate
            auto fp = callable;
        }
        synchronized(state) {
            auto s = cast(SS)state;
            s.valid = true;
            s.th = new Thread(() {
                static if (is(F == void)) {
                    privCall(args);
                }
                else {
                    privCall(fp, args);
                }
            });
            s.th.start();
        }
    }

    /// Call function with args as parameters. The returned value is stored in the
    /// state shared with the Future
    void call(Args...)(Args args)
    {
        if (!state) state = new SS;
        auto s = cast(SS)state;
        try {
            s.valid = true;
            static if (is(F == void)) {
                privCall(args);
            }
            else {
                privCall(callable, args);
            }
        }
        catch(Throwable ex) {
            s.ex = ex;
        }
    }

    /// ditto
    void opCall(Args...)(Args args)
    {
        call(args);
    }

    private void privCall(Args...)(Args args)
    {
        static if (is(T == void)) {
            func(args);
        }
        else {
            auto s = cast(SS)state;
            s.val = func(args);
        }
    }
}


/// A Promise is represent the result of a task that is in a thread, and retrieved
/// through a future in another thread.
struct Promise(WaitPolicy policy, T)
if (!is(T == void))
{
    private enum spin = policy == WaitPolicy.spin;
    private enum block = policy == WaitPolicy.block;
    static assert(spin || block);

    private alias SS = PromiseSharedState!(policy, T);
    private shared(SS) _sharedState;

    /// Get the future of this promise.
    /// The future is already valid. future.resolve will wait that the value or
    /// exception is set in this promise.
    @property Future!T future()
    {
        if (!_sharedState) _sharedState = new SS;
        return Future!T(_sharedState);
    }

    /// Set the value and fulfill this promise.
    /// The future will be notified
    @property void value(T val)
    {
        import core.atomic : atomicLoad, atomicStore;

        if (!_sharedState) _sharedState = new SS;

        assert(atomicLoad(_sharedState.status) != Status.done, "cannot set a promise value or exception twice");

        static if (spin) {
            _sharedState.val = val;
            atomicStore(_sharedState.status, Status.done);
        }
        else {
            _sharedState.mutex.lock();
            scope(exit) _sharedState.mutex.unlock();

            _sharedState.val = val;
            atomicStore(_sharedState.status, Status.done);

            _sharedState.condition.notifyAll();
        }
    }

    /// Set the exception that will be thrown by future.resolve.
    @property void exception(Throwable ex)
    {
        import core.atomic : atomicLoad, atomicStore;

        if (!_sharedState) _sharedState = new SS;

        assert(atomicLoad(_sharedState.status) != Status.done, "cannot set a promise value or exception twice");

        static if (spin) {
            _sharedState.ex = ex;
            atomicStore(_sharedState.status, Status.done);
        }
        else {
            _sharedState.mutex.lock();
            scope(exit) _sharedState.mutex.unlock();

            _sharedState.ex = ex;
            _sharedState.condition.notifyAll();
        }
    }
}


private:

/// make task work with delegate
ReturnType!F run(F, Args...)(F fpOrDelegate, ref Args args)
{
    return fpOrDelegate(args);
}

abstract class SharedState(T)
{
    private Throwable ex;
    static if (!is(T == void)) {
        private T val;
    }

    bool valid;

    shared abstract T resolve();
}

class TaskSharedState(T) : SharedState!T
{
    import core.thread : Thread;

    private Thread th;

    shared override T resolve()
    {
        synchronized(this) {
            auto ss = cast(TaskSharedState!T)this;
            if (ss.th) {
                ss.th.join(true); // throws
            }
            else if (ss.ex) {
                throw ss.ex;
            }
            static if (!is(T == void)) {
                return ss.val;
            }
        }
    }
}

class PromiseSharedState(WaitPolicy policy, T) : SharedState!T
{
    private enum spin = policy == WaitPolicy.spin;
    private enum block = policy == WaitPolicy.block;

    static if (block)
    {
        import core.sync.condition : Condition;
        import core.sync.mutex : Mutex;

        private Mutex mutex;
        private Condition condition;
    }

    private Status status;

    this()
    {
        valid = true;
        static if (block) {
            mutex = new Mutex;
            condition = new Condition(mutex);
        }
    }

    shared override T resolve ()
    {
        static if (spin) {
            import core.atomic : atomicLoad;
            while (atomicLoad(status) != Status.done) {}
        }
        else {
            while (atomicLoad(status) != Status.done) {
                mutex.lock();
                scope(exit) mutex.unlock();

                condition.wait();
            }
        }

        if (ex) {
            throw ex;
        }
        static if (!is(T == void)) {
            return val;
        }
    }
}
