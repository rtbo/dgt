/// Handler and Signal definition module
module dgt.event.handler;

import dgt.event.event : Event;

/// A slot type
alias Slot(P...) = void delegate(P);

/// Simple handler type (one slot can be assigned)
final class Handler(P...)
{
    alias ParamsType = P;
    alias SlotType = Slot!P;

    private SlotType _slot;

    void opAssign(SlotType slot)
    {
        _slot = slot;
    }

    void set(SlotType slot)
    {
        _slot = slot;
    }

    void clear()
    {
        _slot = null;
    }

    @property bool engaged()
    {
        return _slot !is null;
    }

    void fire(ParamsType params)
    {
        if (!engaged) return;
        else _slot(params);
    }
}


/// Signal type (multiple slots)
abstract class Signal(P...)
{
    alias ParamsType = P;
    alias SlotType = Slot!P;

    private SlotType[] _slots;

    final void opOpAssign(string op : "+")(SlotType slot)
    {
        add(slot);
    }

    final void add (SlotType slot)
    {
        _slots ~= slot;
    }

    final bool opOpAssign(string op : "-")(SlotType slot)
    {
        remove(slot);
    }

    final bool remove (SlotType slot)
    {
        import std.algorithm : find, remove;
        auto found = _slots.find(slot);
        if (!found.length)
            return false;
        _slots = _slots.remove(_slots.length - found.length);
        return true;
    }

    final void clear()
    {
        _slots = null;
    }

    final @property bool engaged() const
    {
        return _slots.length != 0;
    }

}

/// A signal that can be fired.:w
final class FireableSignal(P...) : Signal!(P)
{
    void fire(ParamsType params)
    {
        foreach (slot; _slots)
        {
            slot(params);
            static if(is(ParamsType : Event)) {
                if (params.consumed) break;
            }
        }
    }
}
