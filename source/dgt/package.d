///
module dgt;

import core.sync.mutex : Mutex;

package immutable string dgtTag = "DGT";
package immutable string dgtStyleTag = "DGT-STYLE";
package immutable string dgtLayoutTag = "DGT-LAYOUT";
package immutable string dgtFrameTag = "DGT-FRAME";

interface Subsystem
{
    @property string name() const;
    /// Order of priority in intialization and finalization.
    /// Subsystems of higher priority are initialized first and finalized last.
    /// Use this to enable ensure dependency correctness between subsystems.
    @property int priority() const;

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
    import std.algorithm : each, filter, sort;

    gMut.lock();
    scope(exit) gMut.unlock();

    trace(dgtTag, "loading dynamic bindings");
    loadBindings();

    trace(dgtTag, "initializing subsystems");

    auto ss = gSubsystems.dup;
    ss.sort!"a.priority > b.priority"();
    foreach (s; ss.filter!(s => !s.running)) {
        trace(dgtTag, "Initialize subsystem "~s.name);
        s.initialize();
    }
}

void finalizeSubsystems()
{
    import std.algorithm : each, filter, sort;
    import gfx.core.log : trace;

    gMut.lock();
    scope(exit) gMut.unlock();

    auto ss = gSubsystems.dup;
    ss.sort!"a.priority < b.priority"();
    foreach (s; ss.filter!(s => s.running)) {
        trace(dgtTag, "Finalize subsystem "~s.name);
        s.finalize();
    }
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
