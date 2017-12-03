/// Platform abstraction module
module dgt.platform;

import dgt.context;
import dgt.core.geometry;
import dgt.platform.event;
import dgt.screen;
import dgt.window;
import gfx.foundation.rc;

import std.typecons : BitFlags;

/// Kind of event to wait for
enum Wait
{
    none = 0,
    input = 1,
    vsync = 2,
    timer = 4,

    all = input | vsync | timer
}

/// Platform singleton. Entry point to operating system specific code.
interface Platform : Disposable
{
    void initialize();

    @property string name() const;

    @property inout(Screen) defaultScreen() inout;
    @property inout(Screen)[] screens() inout;
    PlatformWindow createWindow(Window window);

    void wait(in Wait waitFlags);

    void collectEvents(void delegate(PlEvent) collector);
    void processEvents();
}

/// OS specific window interface.
interface PlatformWindow
{
    @property inout(Window) window() inout;

    bool created() const;

    void create()
    in { assert(!created); }
    out { assert(created); }

    void close();

    @property size_t nativeHandle() const;

    @property string title() const;
    @property void title(string title);

    @property WindowState state() const;
    void setState(WindowState state);

    @property IRect rect() const;
    void setRect(in IRect rect);
}
