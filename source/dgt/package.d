///
module dgt;

import core.sync.mutex : Mutex;

package immutable string dgtTag = "DGT";

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

void registerSubsystem(Subsystem ss)
{
    gMut.lock();
    scope(exit) gMut.unlock();
    gSubsystems ~= ss;
}

void initializeSubsystems()
{
    import gfx.core.log : trace;
    import std.algorithm : each, filter;

    gMut.lock();
    scope(exit) gMut.unlock();

    trace(dgtTag, "loading dynamic bindings");
    loadBindings();

    trace(dgtTag, "initializing subsystems");

    gSubsystems.filter!(ss => !ss.running)
        .each!(ss => ss.initialize());
}

void finalizeSubsystems()
{
    import std.algorithm : each, filter;
    import gfx.core.log : trace;

    gMut.lock();
    scope(exit) gMut.unlock();

    gSubsystems.filter!(ss => ss.running)
        .each!(ss => ss.finalize());
    gSubsystems = [];

    trace(dgtTag, "finalized subsystems");
}

private:

shared static this()
{
    gMut = new Mutex();
}

__gshared Subsystem[] gSubsystems;
__gshared Mutex gMut;

void loadBindings()
{
    import dgt.bindings.harfbuzz.load : loadHarfbuzzSymbols;

    loadHarfbuzzSymbols();

    version(linux) {
        import dgt.bindings.fontconfig.load : loadFontconfigSymbols;
        loadFontconfigSymbols();
    }
}
