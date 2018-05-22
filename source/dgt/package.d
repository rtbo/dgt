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

    gMut.lock();
    scope(exit) gMut.unlock();

    trace("loading dynamic bindings");
    loadBindings();

    trace("initializing subsystems");

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

void loadBindings()
{
    import derelict.freetype.ft : DerelictFT;
    import dgt.bindings.harfbuzz.load : loadHarfbuzzSymbols;
    import dgt.bindings.libpng.load : loadLibPngSymbols;
    import dgt.bindings.turbojpeg.load : loadTurboJpegSymbols;

    DerelictFT.load();
    loadHarfbuzzSymbols();
    loadLibPngSymbols();
    loadTurboJpegSymbols();

    version(linux) {
        import dgt.bindings.fontconfig.load : loadFontconfigSymbols;
        loadFontconfigSymbols();
    }
}
