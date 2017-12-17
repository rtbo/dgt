///
module dgt;

import core.sync.mutex : Mutex;
import std.experimental.logger;

interface Subsystem
{
    @property bool running() const;

    void initialize()
    in {
        assert(!running);
    }
    out {
        assert(running);
    }

    void finalize()
    in {
        assert(running);
    }
    out {
        assert(!running);
    }
}

void registerSubsystem(Subsystem ss) {
    gMut.lock();
    scope(exit) gMut.unlock();
    gSubsystems ~= ss;
}

void initializeSubsystems() {
    import std.algorithm : each, filter;
    import derelict.opengl3.gl3 : DerelictGL3;

    gMut.lock();
    scope(exit) gMut.unlock();

    trace("initializing subsystems");

    DerelictGL3.load();
    gSubsystems.filter!(ss => !ss.running)
        .each!(ss => ss.initialize());
}

void finalizeSubsystems() {
    import std.algorithm : each, filter;

    gMut.lock();
    scope(exit) gMut.unlock();

    gSubsystems.filter!(ss => ss.running)
        .each!(ss => ss.finalize());
    gSubsystems = [];

    trace("finalized subsystems");
}

private:

shared static this() {
    gMut = new Mutex();
}

__gshared Subsystem[] gSubsystems;
__gshared Mutex gMut;
