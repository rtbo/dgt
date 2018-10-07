import reggae;

enum buildType = userVars.get("buildType", "debug");

static if (buildType == "debug") {
    enum dflags = CompilerFlags("-g -debug");
}
else static if (buildType == "release") {
    enum dflags = CompilerFlags("-release");
}
else {
    static assert(false, "invalid buildType: "~buildType);
}

mixin build!(dubDefaultTarget!(dflags));
