module dgt.event;

import dgt.window : Window, WindowState;
import dgt.geometry : IPoint, ISize, IRect;
import dgt.enums;
import key = dgt.keys;

interface EventHandler {

    void handleEvent(Event ev);

}

enum EventType
{
    appMask = 0x01000000,
    appQuit, // generated e.g. with Ctrl-C, or when last window closes
    appUser,

    windowMask = 0x02000000,
    windowShow,
    windowHide,
    windowExpose,
    windowResize,
    windowMove,
    windowClose,
    windowStateChange,
    windowFocusIn,
    windowFocusOut,
    windowMouseDown,
    windowMouseUp,
    windowMouseMove,
    windowMouseEnter,
    windowMouseLeave,
    windowKeyDown,
    windowKeyUp,
}


bool isAppEventType(EventType type)
{
    return (type & EventType.appMask) != 0;
}

bool isAppEvent(in Event ev) {
    return ev.type.isAppEventType();
}


bool isWindowEventType(EventType type)
{
    return (type & EventType.windowMask) != 0;
}

bool isWindowEvent(in Event ev) {
    return ev.type.isWindowEventType();
}


unittest {
    assert( isAppEventType(EventType.appQuit));
    assert(!isAppEventType(EventType.windowClose));
    assert( isWindowEventType(EventType.windowClose));
    assert( isWindowEventType(EventType.windowFocusOut));
    assert( isWindowEventType(EventType.windowKeyDown));
    assert(!isWindowEventType(EventType.appQuit));
}


abstract class Event
{
    this(EventType type) {
        type_ = type;
    }

    @property EventType type() const { return type_; }

    @property bool consumed() const { return consumed_; }
    void consume() {
        consumed_ = true;
    }

    override string toString() {
        import std.conv : to;
        return "Event [ type:" ~ type_.to!string ~ " ]";
    }


    private EventType type_;
    private bool consumed_;
}


abstract class AppEvent : Event {

    this(EventType type) {
        super(type);
        assert(isAppEventType(type));
    }

}


class AppQuitEvent : AppEvent {

    this () {
        super(EventType.appQuit);
    }

    @property bool declined() const { return declined_; }
    void decline() {
        declined_ = true;
        consume();
    }

    @property int code() const { return code_; }
    @property void code(int code) {
        code_ = code;
        consume();
    }

    private bool declined_;
    private int code_;
}

class AppUserEvent : AppEvent {

    this () {
        super(EventType.appUser);
    }

}


abstract class WindowEvent : Event {

    this(EventType type, Window window) {
        super(type);
        assert(isWindowEventType(type));
        window_ = window;
    }

    @property inout(Window) window() inout { return window_; }

    private Window window_;
}


class WindowShowEvent : WindowEvent {

    this (Window window) {
        super(EventType.windowShow, window);
    }

}


class WindowHideEvent : WindowEvent {

    this (Window window) {
        super(EventType.windowHide, window);
    }

}


class WindowExposeEvent : WindowEvent {

    this (Window window) {
        super(EventType.windowExpose, window);
    }

}


class WindowResizeEvent : WindowEvent
{
    this (Window window, ISize size) {
        super(EventType.windowResize, window);
        size_ = size;
    }

    @property ISize size() const { return size_; }

    private ISize size_;
}


class WindowMoveEvent : WindowEvent
{
    this(Window window, IPoint point) {
        super(EventType.windowMove, window);
    }

    @property IPoint point() const { return point_; }

    private IPoint point_;
}


class WindowCloseEvent : WindowEvent
{
    this(Window window) {
        super(EventType.windowClose, window);
    }

    @property bool declined() const { return declined_; }
    void decline() {
        declined_ = true;
        consume();
    }

    private bool declined_;
}


class WindowStateChangeEvent : WindowEvent
{
    this(Window window, WindowState state) {
        super(EventType.windowStateChange, window);
        state_ = state;
    }

    @property WindowState state() const { return state_; }

    private WindowState state_;
}




class WindowFocusEvent : WindowEvent
{
    this (EventType type, Window window, FocusMethod method) in {
        assert(type == EventType.windowFocusIn || type == EventType.windowFocusOut);
    }
    body {
        super(type, window);
        method_ = method;
    }

    @property FocusMethod method() const { return method_; }

    private FocusMethod method_;
}



class WindowMouseEvent : WindowEvent
{
    this (EventType type, Window window, IPoint point,
          MouseButton button, MouseState state,
          key.Mods modifiers)
    in {
        assert(type == EventType.windowMouseDown || type == EventType.windowMouseUp ||
               type == EventType.windowMouseMove ||
               type == EventType.windowMouseEnter || type == EventType.windowMouseLeave);
    }
    body {
        super(type, window);
        point_ = point;
        button_ = button;
        state_ = state;
        modifiers_ = modifiers;
    }

    @property IPoint point() const { return point_; }
    @property MouseButton button() const { return button_; }
    @property MouseState state() const { return state_; }
    @property key.Mods modifiers() const { return modifiers_; }

    private {
        IPoint point_;
        MouseButton button_;
        MouseState state_;
        key.Mods modifiers_;
    }
}



class WindowKeyEvent : WindowEvent
{
    this(EventType type, Window window, key.Sym sym, key.Code scancode,
        key.Mods modifiers, string text, uint nativeCode, uint nativeSymbol,
        bool repeat=false, int repeatCount=1)
    in {
        assert(type == EventType.windowKeyDown || type == EventType.windowKeyUp);
    }
    body {
        super(type, window);
        sym_ = sym;
        code_ = code;
        modifiers_ = modifiers;
        text_ = text;
        nativeCode_ = nativeCode;
        nativeSymbol_ = nativeSymbol;

        repeat_ = repeat;
        repeatCount_ = repeatCount;
    }

    @property key.Sym sym() const { return sym_; }
    @property key.Code code() const { return code_; }
    @property key.Mods modifiers() const { return modifiers_; }
    @property string text() const { return text_; }
    @property uint nativeCode() const { return nativeCode_; }
    @property uint nativeSymbol() const { return nativeSymbol_; }

    @property bool repeat() const { return repeat_; }
    @property int repeatCount() const { return repeatCount_; }


    private {
        key.Sym sym_;
        key.Code code_;
        key.Mods modifiers_;
        string text_;
        uint nativeCode_;
        uint nativeSymbol_;

        bool repeat_;
        int repeatCount_;
    }

}
