module dgt.bindings.cairo;

public import dgt.bindings.cairo.enums;
public import dgt.bindings.cairo.types;
public import dgt.bindings.cairo.png;
public import dgt.bindings.cairo.symbols;
version(linux)
{
    public import dgt.bindings.cairo.xcb;
}
version(Windows)
{
    public import dgt.bindings.cairo.win32;
}
