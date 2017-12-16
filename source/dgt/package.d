///
module dgt;

import derelict.opengl3.gl3 : DerelictGL3;
import dgt.font;
import std.experimental.logger;

void initializeSubsystems() {
    trace("initializing subsystems");
    DerelictGL3.load();
    initializeFontSubsystem();
}

void finalizeSubsystems() {
    finalizeFontSubsystem();
    trace("finalized subsystems");
}
