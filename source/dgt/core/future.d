/// Provides Future/Promise synchronization
module dgt.core.future;

private enum Status : ubyte
{
    notStarted,
    inProgress,
    done,
}

enum WaitPolicy {
    spin,
    block,
}

struct Future(T)
{
    @disable this();
    @disable this(this);

    private shared(SharedState) state;

    T resolve() {
        return state.resolve();
    }
}

final class Task(WaitPolicy policy, alias fun, Args...)
{
    private enum spin = policy == WaitPolicy.spin;
    private enum block = policy == WaitPolicy.block;
    static assert(spin || block);


}

final class Promise(WaitPolicy policy, T)
if (!is(T == void))
{
    private enum spin = policy == WaitPolicy.spin;
    private enum block = policy == WaitPolicy.block;
    static assert(spin || block);

    private alias SS = PromiseSharedState!(policy, T);
    private shared(SS) _sharedState;

    this() {
    }

    @property Future!T future()
    {
        if (!_sharedState) _sharedState = new SS;
        return Future!T(_sharedState);
    }

    @property void value(T val)
    {
        import core.atomic : atomicLoad, atomicStore;
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

    @property void exception(Throwable ex)
    {
        import core.atomic : atomicLoad, atomicStore;
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

abstract class SharedState(T)
{
    shared abstract T resolve();
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

    private Throwable ex;
    private T val;
    private Status status;


    static if (block) {
        this() {
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
