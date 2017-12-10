/// Platform abstraction module
module dgt.platform;

import core.time : Duration, MonoTime;

import dgt.context;
import dgt.core.geometry;
import dgt.core.signal;
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

    GlContext createGlContext(
                GlAttribs attribs, PlatformWindow window,
                GlContext sharedCtx, Screen screen);

    PlatformTimer createTimer();

    Wait wait(in Wait waitFlags);
    void collectEvents(void delegate(PlEvent) collector);
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
    void setTitle(in string title);

    @property WindowState state() const;
    void setState(in WindowState state);

    @property IRect rect() const;
    void setRect(in IRect rect);
}

interface PlatformTimer : Disposable {
    enum Mode {
        singleShot,
        multipleShots,
        endless,
    }
    @property Mode mode();
    @property void mode(in Mode mode);
    @property bool engaged();
    @property MonoTime started();
    @property Duration duration();
    @property void duration(in Duration dur);
    @property uint shots();
    @property void shots(in uint val);

    void start()
    in {
        assert(!engaged);
        assert(duration > Duration.zero);
    }
    out {
        assert(engaged);
    }

    void stop()
    in {
        assert(engaged);
    }
    out {
        assert(!engaged);
    }

    @property Slot!() handler();
    @property void handler(Slot!() slot);
}
