/// Signal definition module
///
/// SMI stands for Single Method Interface
/// concept similar to functional interface in Java 8
module dgt.signal;

import dgt.event : Event;


// SmiSignal and Signal classes are inspired from dlangui.core.signals module:
// Copyright: Vadim Lopatin, 2014
// License:   Boost License 1.0
// Authors:   Vadim Lopatin, coolreader.org@gmail.com

// here I split SmiSignal from Signal to disambiguate case when interface obj
// should be passed as argument of the delegate

// TODO: think how necessary it is to split Signal and Fireable signal

/// Checks whether $(D Iface) is a SMI.
template isSmi(Iface)
{
    static if (is(Iface == interface))
    {
        enum isSmi = (__traits(allMembers, Iface).length == 1);
    }
    else
    {
        enum isSmi = false;
    }
}

/// Get the method name of a SMI.
template smiMethodName(Iface) if (isSmi!Iface)
{
    enum smiMethodName = __traits(allMembers, Iface)[0];
}

/// Get the return type of a SMI method.
template smiRetType(Iface) if (isSmi!Iface)
{
    import std.traits : ReturnType;

    alias smiRetType = ReturnType!(__traits(getMember, Iface, smiMethodName!Iface));
}

/// Get the parameters types of a SMI method.
/// It aliases to a $(D AliasSeq) of the parameters types.
template smiParamsType(Iface) if (isSmi!Iface)
{
    import std.traits : Parameters;

    alias smiParamsType = Parameters!(__traits(getMember, Iface, smiMethodName!Iface));
}

version(unittest)
{
    import std.meta : AliasSeq;

    interface SmiTestIface
    {
        void method(string arg1, int arg2);
    }

    static assert(isSmi!(SmiTestIface));
    static assert(smiMethodName!(SmiTestIface) == "method");
    static assert(is(smiRetType!(SmiTestIface) == void));
    static assert((smiParamsType!(SmiTestIface)).length == 2);
    static assert(is(smiParamsType!(SmiTestIface) == AliasSeq!(string, int)));
}

/// SMI signal
/// A signal type that is defined by help of a SMI.
/// Slots can be instance of the SMI, or delegate with same signature of the SMI
/// method.
abstract class SmiSignal(Iface) if (isSmi!Iface && is(smiRetType!Iface == void))
{
    alias RetType = void;
    alias ParamsType = smiParamsType!Iface;
    alias SlotType = void delegate(ParamsType);

    private SlotType[] _slots;

    void opOpAssign(string op : "+")(SlotType slot)
    {
        _slots ~= slot;
    }

    bool opOpAssign(string op : "-")(SlotType slot)
    {
        import std.algorithm : countUntil, remove;

        auto index = _slots.countUntil(slot);
        if (index == -1)
            return false;
        _slots = _slots.remove(index);
        return true;
    }

    void opOpAssign(string op : "+")(Iface slotObj)
    {
        _slots ~= &(__traits(getMember, slotObj, theMethod));
    }

    bool opOpAssign(string op : "-")(Iface slotObj)
    {
        auto slot = &(__traits(getMember, slotObj, theMethod));
        return opOpAssign!("-")(slot);
    }

    @property bool engaged() const
    {
        return _slots.length != 0;
    }

}

/// A signal that can be fired.
/// The utility of it is that a type can have a FireableSmiSignal has member
/// and only exposes the $(D SmiSignal) superclass as public $(D @property)
/// Requirement is that the method return type is void.
final class FireableSmiSignal(Iface) if (isSmi!Iface && is(smiRetType!Iface == void))
    : SmiSignal!(Iface)
{
    void fire(ParamsType params)
    {
        foreach (slot; _slots)
        {
            slot(params);
        }
    }
}

private
{
    interface NoSmi
    {
        void m1();
        void m2();
    }

    interface NonVoidSmi
    {
        int m();
    }

    interface VoidSmi
    {
        void m();
    }

    static assert(!__traits(compiles, new FireableSmiSignal!NoSmi));
    static assert(!__traits(compiles, new FireableSmiSignal!NonVoidSmi));
    static assert(__traits(compiles, new FireableSmiSignal!VoidSmi));
}

unittest
{
    interface I1
    {
        void m(int p);
    }

    int val = 0;
    void f(int p)
    {
        val = p;
    }

    auto s = new FireableSmiSignal!I1;
    s += &f;

    s.fire(4);
    assert(val == 4);

    // testing signal manipulation as rvalue
    class C
    {
        auto _s = new FireableSmiSignal!I1;

        void fireSig(int v)
        {
            _s.fire(v);
        }

        @property SmiSignal!I1 s()
        {
            return _s;
        }
    }

    auto c = new C;
    c.s += &f;
    c.fireSig(18);
    assert(val == 18);
    c.s -= &f;

    // testing with delegate
    c.s += delegate void(int p) { val = p; };
    c.fireSig(14);
    assert(val == 14);
}

/// Signal defined by the types that are passed to handled method.
abstract class Signal(P...)
{
    alias RetType = void;
    alias ParamsType = P;
    alias SlotType = void delegate(ParamsType);

    private SlotType[] _slots;

    void opOpAssign(string op : "+")(SlotType slot)
    {
        _slots ~= slot;
    }

    bool opOpAssign(string op : "-")(SlotType slot)
    {
        auto found = _slots.find(slot);
        if (found.empty)
            return false;
        _slots = _slots.remove(_slots.length - found.length);
        return true;
    }

    @property bool engaged() const
    {
        return _slots.length != 0;
    }

}

/// A signal that can be fired.
final class FireableSignal(P...) : Signal!(P)
{
    void fire(ParamsType params)
    {
        foreach (slot; _slots)
        {
            slot(params);
        }
    }
}
