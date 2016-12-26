module dgt.text.bidi;

import dgt.text.bidi.tables;

import std.uni;

enum BidiClass
{
    AL,
    AN,
    B,
    BN,
    CS,
    EN,
    ES,
    ET,
    FSI,
    L,
    LRE,
    LRI,
    LRO,
    NSM,
    ON,
    PDF,
    PDI,
    R,
    RLE,
    RLI,
    RLO,
    S,
    WS,
}

BidiClass bidiClass(in dchar c) pure @safe nothrow
{
    return cast(BidiClass)bidiClassTrie[c];
}

unittest
{
    assert(bidiClass(0x006E) == BidiClass.L);
    assert(bidiClass(0x060B) == BidiClass.AL);
    assert(bidiClass(0x202C) == BidiClass.PDF);
}

private:

@safe pure nothrow auto asTrie(T...)(in TrieEntry!T e)
{
    return const(CodepointTrie!T)(e.offsets, e.sizes, e.data);
}

@safe pure nothrow auto bidiClassTrie()
{
    static immutable res = asTrie(bidiClassTrieEntries);
    return res;
}
