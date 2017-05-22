/// Events module
module dgt.event.event;

import dgt.enums;
import dgt.geometry : IPoint, IRect, ISize;
import dgt.keys;


/// Type of event. 3 categories: app, input and user.
/// Category can be tested using Maskwise AND.
enum EventType : uint
{
    noneMask        = 0x0000_0000,
    allMask         = 0xffff_ffff,

    appMask         = 0x1000_0000,
    inputMask       = 0x2000_0000,
    userMask        = 0x4000_0000,

    focusMask       = 0x0100_0000,
    mouseMask       = 0x0200_0000 | inputMask,
    keyMask         = 0x0400_0000 | inputMask,

    timer           = appMask | 1,

    focusIn         = focusMask | 1,
    focusOut,
    mouseDown       = mouseMask | 1,
    mouseUp,
    mouseMove,
    mouseDrag,
    mouseClick,
    mouseDblClick,
    mouseEnter,
    mouseLeave,
    keyDown         = keyMask | 1,
    keyUp,
}

/// Tests whether the event type is of the app category
bool isAppEventType(EventType type)
{
    return (type & EventType.appMask) != 0;
}

/// Tests whether the event type is of the app category
bool isAppEvent(in Event ev)
{
    return ev.type.isAppEventType();
}

/// Tests whether the event type is of the input category
bool isInputEventType(EventType type)
{
    return (type & EventType.inputMask) != 0;
}

/// Tests whether the event type is of the input category
bool isInputEvent(in Event ev)
{
    return ev.type.isInputEventType();
}

/// Tests whether the event type is of the user category
bool isUserEventType(EventType type)
{
    return (type & EventType.userMask) != 0;
}

/// Tests whether the event type is of the user category
bool isUserEvent(in Event ev)
{
    return ev.type.isUserEventType;
}


abstract class Event
{
    this(EventType type)
    {
        _type = type;
    }

    final @property EventType type() const
    {
        return _type;
    }

    package(dgt) @property void type(in EventType type)
    {
        _type = type;
    }

    final @property bool consumed() const
    {
        return _consumed;
    }

    final void consume()
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
    this(int eventType)
    {
        assert(isUserEventType(cast(EventType)type));
        super(cast(EventType)type);
    }
}

class FocusEvent : Event
{
    this(EventType type, FocusMethod method)
    in
    {
        assert(type == EventType.focusIn || type == EventType.focusOut);
    }
    body
    {
        super(type);
        _method = method;
    }

    @property FocusMethod method() const
    {
        return _method;
    }

    private FocusMethod _method;
}

class MouseEvent : Event
{
    this(EventType type, IPoint point, MouseButton button,
            MouseState state, KeyMods modifiers)
    in
    {
        assert(type & EventType.mouseMask);
    }
    body
    {
        super(type);
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

    @property KeyMods modifiers() const
    {
        return _modifiers;
    }

    package(dgt) @property void point(in IPoint p)
    {
        _point = p;
    }

    package(dgt) @property void modifiers(in KeyMods m)
    {
        _modifiers = m;
    }

    private
    {
        IPoint _point;
        MouseButton _button;
        MouseState _state;
        KeyMods _modifiers;
    }
}

class KeyEvent : Event
{
    this(EventType type, KeySym sym, KeyCode code,
            KeyMods modifiers, string text, uint nativeCode, uint nativeSymbol,
            bool repeat = false, int repeatCount = 1)
    in
    {
        assert(type & EventType.keyMask);
    }
    body
    {
        super(type);
        _sym = sym;
        _code = code;
        _modifiers = modifiers;
        _text = text;
        _nativeCode = nativeCode;
        _nativeSymbol = nativeSymbol;

        _repeat = repeat;
        _repeatCount = repeatCount;
    }

    @property KeySym sym() const
    {
        return _sym;
    }

    @property KeyCode code() const
    {
        return _code;
    }

    @property KeyMods modifiers() const
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
        KeySym _sym;
        KeyCode _code;
        KeyMods _modifiers;
        string _text;
        uint _nativeCode;
        uint _nativeSymbol;

        bool _repeat;
        int _repeatCount;
    }
}
