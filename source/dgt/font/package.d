module dgt.font;

package(dgt):

void initializeFontSubsystem() {
    version (linux) {
        import dgt.font.port.ft : initializeFreetype;
        initializeFreetype();
    }
}

void finalizeFontSubsystem() {
    version (linux) {
        import dgt.font.port.ft : finalizeFreetype;
        finalizeFreetype();
    }
}
