module dgt.signal;

import dgt.event : Event;

// SMI stands for Single Method Interface
// concept similar to functional interface in Java 8

// SmiSignal and Signal classes are inspired from dlangui.core.signals module:
// Copyright: Vadim Lopatin, 2014
// License:   Boost License 1.0
// Authors:   Vadim Lopatin, coolreader.org@gmail.com

// here I split SmiSignal from Signal to disambiguate case when interface obj
// should be passed as argument of the delegate

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

template smiMethodName(Iface) if (isSmi!Iface)
{
    enum smiMethodName = __traits(allMembers, Iface)[0];
}

template smiRetType(Iface) if (isSmi!Iface)
{
    import std.traits : ReturnType;

    alias smiRetType = ReturnType!(__traits(getMember, Iface, smiMethodName!Iface));
}

template smiParamsType(Iface) if (isSmi!Iface)
{
    import std.traits : Parameters;

    alias smiParamsType = Parameters!(__traits(getMember, Iface, smiMethodName!Iface));
}

template isEventHandler(Iface)
{
    static if (isSmi!Iface)
    {
        enum bool isEventHandler = smiParamsType!(Iface).length == 1
                && is(smiParamsType!(Iface)[0] : Event);
    }
    else
    {
        enum bool isEventHandler = false;
    }
}

template HandlerEventType(Iface) if (isEventHandler!Iface)
{

    alias HandlerEventType = smiParamsType!(Iface)[0];

}

private
{
    import dgt.event : WindowCloseEvent;
    import std.meta : AliasSeq;

    interface SmiTestIface
    {
        void method(string arg1, int arg2);
    }

    interface EventHandlerTestIface
    {
        void method(Event ev);
    }

    interface CloseEventHandlerTestIface
    {
        void onClose(WindowCloseEvent ev);
    }

    static assert(isSmi!(SmiTestIface));
    static assert(isSmi!(EventHandlerTestIface));
    static assert(smiMethodName!(SmiTestIface) == "method");
    static assert(is(smiRetType!(SmiTestIface) == void));
    static assert((smiParamsType!(SmiTestIface)).length == 2);
    static assert(is(smiParamsType!(SmiTestIface) == AliasSeq!(string, int)));
    static assert(!isEventHandler!SmiTestIface);
    static assert(isEventHandler!EventHandlerTestIface);
    static assert(is(HandlerEventType!CloseEventHandlerTestIface == WindowCloseEvent));
}

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

abstract class EventHandlerSignal(HandlerT) if (isEventHandler!HandlerT)
{
    alias RetType = void;
    alias EventType = HandlerEventType!HandlerT;
    alias SlotType = void delegate(EventType ev);

    static assert(is(EventType : Event));

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

final class FireableEventHandlerSignal(HandlerT) if (isEventHandler!HandlerT)
    : EventHandlerSignal!HandlerT
{

    void fire(EventType event)
    {
        foreach (slot; _slots)
        {
            slot(event);
            if (event.consumed)
                break;
        }
    }

}
