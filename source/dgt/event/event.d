/// Events module
module dgt.event.event;

import dgt.enums;
import dgt.geometry : IPoint, IRect, ISize;
import dgt.keys;
import dgt.window : Window, WindowState;


/// Type of event. 3 categories: app, window and user.
/// Category can be tested using bitwise AND.
enum EventType : uint
{
    noneMask        = 0x0000_0000,
    allMask         = 0xffff_ffff,

    appBit          = 0x1000_0000,
    windowBit       = 0x2000_0000,
    userBit         = 0x4000_0000,

    focusBit        = 0x0100_0000,
    mouseBit        = 0x0200_0000,
    keyBit          = 0x0400_0000,

    timer           = appBit | 1,

    show            = windowBit | 1,
    hide,
    expose,
    resize,
    move,
    close,
    stateChange,
    focusIn         = windowBit | focusBit | 1,
    focusOut,
    mouseDown       = windowBit | mouseBit | 1,
    mouseUp,
    mouseMove,
    mouseDrag,
    mouseClick,
    mouseDblClick,
    mouseEnter,
    mouseLeave,
    keyDown         = windowBit | keyBit | 1,
    keyUp,
}

/// Tests whether the event type is of the app category
bool isAppEventType(EventType type)
{
    return (type & EventType.appBit) != 0;
}

/// Tests whether the event type is of the app category
bool isAppEvent(in Event ev)
{
    return ev.type.isAppEventType();
}

/// Tests whether the event type is of the window category
bool isWindowEventType(EventType type)
{
    return (type & EventType.windowBit) != 0;
}

/// Tests whether the event type is of the window category
bool isWindowEvent(in Event ev)
{
    return ev.type.isWindowEventType();
}

/// Tests whether the event type is of the user category
bool isUserEventType(EventType type)
{
    return (type & EventType.userBit) != 0;
}

/// Tests whether the event type is of the user category
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

    package(dgt) @property void size(in ISize s)
    {
        _size = s;
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

    package(dgt) @property void point(in IPoint p)
    {
        _point = p;
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
            MouseState state, KeyMods modifiers)
    in
    {
        assert(type & EventType.mouseBit);
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

class KeyEvent : WindowEvent
{
    this(EventType type, Window window, KeySym sym, KeyCode code,
            KeyMods modifiers, string text, uint nativeCode, uint nativeSymbol,
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
