///
module dgt;

import core.sync.mutex : Mutex;
import gfx.core.log : LogTag;

enum dgtLogMask = 0x0FE0_0000;
enum dgtStyleLogMask = 0x0080_0000;
enum dgtLayoutLogMask = 0x0080_0000;
enum dgtFrameLogMask = 0x0080_0000;

package immutable dgtLog = LogTag("DGT", dgtLogMask);
package immutable dgtStyleLog = LogTag("DGT-STYLE", dgtStyleLogMask);
package immutable dgtLayoutLog = LogTag("DGT-LAYOUT", dgtLayoutLogMask);
package immutable dgtFrameLog = LogTag("DGT-FRAME", dgtFrameLogMask);

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
    import std.algorithm : each, filter, sort;

    gMut.lock();
    scope(exit) gMut.unlock();

    dgtLog.trace("loading dynamic bindings");
    loadBindings();

    dgtLog.trace("initializing subsystems");

    auto ss = gSubsystems.dup;
    ss.sort!"a.priority > b.priority"();
    foreach (s; ss.filter!(s => !s.running)) {
        dgtLog.trace("Initialize subsystem "~s.name);
        s.initialize();
    }
}

void finalizeSubsystems()
{
    import std.algorithm : each, filter, sort;

    gMut.lock();
    scope(exit) gMut.unlock();

    auto ss = gSubsystems.dup;
    ss.sort!"a.priority < b.priority"();
    foreach (s; ss.filter!(s => s.running)) {
        dgtLog.trace("Finalize subsystem "~s.name);
        s.finalize();
    }
    gSubsystems = [];

    dgtLog.trace("finalized subsystems");
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
