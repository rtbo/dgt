/// Events delivered by the OS.
module dgt.event;

import dgt.signal;
import dgt.window : Window, WindowState;
import dgt.geometry : IPoint, ISize, IRect;
import dgt.enums;
import key = dgt.keys;


enum EventType
{
    appMask = 0x01000000,
    timer,

    windowMask = 0x02000000,
    show,
    hide,
    expose,
    resize,
    move,
    close,
    stateChange,
    focusIn,
    focusOut,
    mouseDown,
    mouseUp,
    mouseMove,
    mouseEnter,
    mouseLeave,
    keyDown,
    keyUp,

    userMask = 0x0400000,
}

bool isAppEventType(EventType type)
{
    return (type & EventType.appMask) != 0;
}

bool isAppEvent(in Event ev)
{
    return ev.type.isAppEventType();
}

bool isWindowEventType(EventType type)
{
    return (type & EventType.windowMask) != 0;
}

bool isWindowEvent(in Event ev)
{
    return ev.type.isWindowEventType();
}

bool isUserEventType(EventType type)
{
    return (type & EventType.userMask) != 0;
}

bool isUserEvent(in Event ev)
{
    return ev.type.isUserEventType;
}

unittest
{
    assert(isAppEventType(EventType.timer));
    assert(!isAppEventType(EventType.close));
    assert(isWindowEventType(EventType.close));
    assert(isWindowEventType(EventType.focusOut));
    assert(isWindowEventType(EventType.keyDown));
    assert(!isWindowEventType(EventType.timer));
}

abstract class Event
{
    this(EventType type)
    {
        _type = type;
    }

    @property EventType type() const
    {
        return _type;
    }

    @property bool consumed() const
    {
        return _consumed;
    }

    void consume()
    {
        _consumed = true;
    }

    override string toString()
    {
        import std.conv : to;

        return "Event [ type:" ~ _type.to!string ~ " ]";
    }

    private EventType _type;
    private bool _consumed;
}

abstract class AppEvent : Event
{
    this(EventType type)
    {
        super(type);
        assert(isAppEventType(type));
    }
}

class UserEvent : Event
{
    this(EventType type)
    {
        assert(isUserEventType(type));
        super(type);
    }
}

abstract class WindowEvent : Event
{
    this(EventType type, Window window)
    {
        super(type);
        assert(isWindowEventType(type));
        _window = window;
    }

    @property inout(Window) window() inout
    {
        return _window;
    }

    private Window _window;
}

class ShowEvent : WindowEvent
{
    this(Window window)
    {
        super(EventType.show, window);
    }
}

class HideEvent : WindowEvent
{
    this(Window window)
    {
        super(EventType.hide, window);
    }
}

class ExposeEvent : WindowEvent
{
    this(Window window, IRect exposedArea)
    {
        super(EventType.expose, window);
        _exposedArea = exposedArea;
    }

    @property IRect exposedArea() const
    {
        return _exposedArea;
    }

    private IRect _exposedArea;
}

class ResizeEvent : WindowEvent
{
    this(Window window, ISize size)
    {
        super(EventType.resize, window);
        _size = size;
    }

    @property ISize size() const
    {
        return _size;
    }

    private ISize _size;
}

class MoveEvent : WindowEvent
{
    this(Window window, IPoint point)
    {
        super(EventType.move, window);
    }

    @property IPoint point() const
    {
        return _point;
    }

    private IPoint _point;
}

class CloseEvent : WindowEvent
{
    this(Window window)
    {
        super(EventType.close, window);
    }

    @property bool declined() const
    {
        return _declined;
    }

    void decline()
    {
        _declined = true;
        consume();
    }

    private bool _declined;
}

class StateChangeEvent : WindowEvent
{
    this(Window window, WindowState state)
    {
        super(EventType.stateChange, window);
        _state = state;
    }

    @property WindowState state() const
    {
        return _state;
    }

    private WindowState _state;
}

class FocusEvent : WindowEvent
{
    this(EventType type, Window window, FocusMethod method)
    in
    {
        assert(type == EventType.focusIn || type == EventType.focusOut);
    }
    body
    {
        super(type, window);
        _method = method;
    }

    @property FocusMethod method() const
    {
        return _method;
    }

    private FocusMethod _method;
}

class MouseEvent : WindowEvent
{
    this(EventType type, Window window, IPoint point, MouseButton button,
            MouseState state, key.Mods modifiers)
    in
    {
        assert(type == EventType.mouseDown || type == EventType.mouseUp || type == EventType.mouseMove
                || type == EventType.mouseEnter || type == EventType.mouseLeave);
    }
    body
    {
        super(type, window);
        _point = point;
        _button = button;
        _state = state;
        _modifiers = modifiers;
    }

    @property IPoint point() const
    {
        return _point;
    }

    @property MouseButton button() const
    {
        return _button;
    }

    @property MouseState state() const
    {
        return _state;
    }

    @property key.Mods modifiers() const
    {
        return _modifiers;
    }

    private
    {
        IPoint _point;
        MouseButton _button;
        MouseState _state;
        key.Mods _modifiers;
    }
}

class KeyEvent : WindowEvent
{
    this(EventType type, Window window, key.Sym sym, key.Code code,
            key.Mods modifiers, string text, uint nativeCode, uint nativeSymbol,
            bool repeat = false, int repeatCount = 1)
    in
    {
        assert(type == EventType.keyDown || type == EventType.keyUp);
    }
    body
    {
        super(type, window);
        _sym = sym;
        _code = code;
        _modifiers = modifiers;
        _text = text;
        _nativeCode = nativeCode;
        _nativeSymbol = nativeSymbol;

        _repeat = repeat;
        _repeatCount = repeatCount;
    }

    @property key.Sym sym() const
    {
        return _sym;
    }

    @property key.Code code() const
    {
        return _code;
    }

    @property key.Mods modifiers() const
    {
        return _modifiers;
    }

    @property string text() const
    {
        return _text;
    }

    @property uint nativeCode() const
    {
        return _nativeCode;
    }

    @property uint nativeSymbol() const
    {
        return _nativeSymbol;
    }

    @property bool repeat() const
    {
        return _repeat;
    }

    @property int repeatCount() const
    {
        return _repeatCount;
    }

    private
    {
        key.Sym _sym;
        key.Code _code;
        key.Mods _modifiers;
        string _text;
        uint _nativeCode;
        uint _nativeSymbol;

        bool _repeat;
        int _repeatCount;
    }
}

/// Interface for handling generic events.
interface EventHandler
{
    /// Handles event $(D ev)
    void handleEvent(Event ev);
}

/// Checks whether the interface is a specialized event handler
/// That is a SMI with method that have one parameter that is convertible to Event.
/// The method can have any name.
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

/// Alias to the type of event a handler handles
template HandlerEventType(Iface) if (isEventHandler!Iface)
{
    alias HandlerEventType = smiParamsType!(Iface)[0];
}

version(unittest)
{
    interface EventHandlerTestIface
    {
        void method(Event ev);
    }

    interface CloseEventHandlerTestIface
    {
        void onClose(CloseEvent ev);
    }
    static assert(isSmi!(EventHandlerTestIface));
    static assert(!isEventHandler!SmiTestIface);
    static assert(isEventHandler!EventHandlerTestIface);
    static assert(is(HandlerEventType!CloseEventHandlerTestIface == CloseEvent));
}

/// Signal defined by a EventHander
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

/// Fireable signal that accept a EventHandler interface
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

/// Mixin template that defines a FireableEventHandlerSignal and access
/// property in the current scope
mixin template EventHandlerSignalMixin(string __name, HandlerT)
{
    import dgt.signal;

    mixin("private FireableEventHandlerSignal!HandlerT _" ~ __name ~ " =\n"
            ~ "    new FireableEventHandlerSignal!HandlerT;");

    mixin("public @property EventHandlerSignal!HandlerT " ~ __name ~ "() { return _" ~ __name
            ~ "; }");
}