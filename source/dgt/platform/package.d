/// Platform abstraction module
module dgt.platform;

import dgt.context;
import dgt.geometry;
import dgt.image;
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

    GlContext createGlContext(
                GlAttribs attribs, PlatformWindow window,
                GlContext sharedCtx, Screen screen);

    @property inout(Screen) defaultScreen() inout;
    @property inout(Screen)[] screens() inout;
    PlatformWindow createWindow(Window window);

    void collectEvents(void delegate(PlEvent) collector);
    void processEvents();
    Wait waitFor(Wait flags);
    void vsync();
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
    @property void state(WindowState state);

    @property IRect geometry() const;
    @property void geometry(IRect pos);

    PlatformWindowBuffer makeBuffer(in ISize size);
}

/// A native buffer image suitable for blitting pixels on screen.
/// Top left corner of this buffer image fit with the top left corner of the
/// window.
/// Suitable for software rendering into an image.
interface PlatformWindowBuffer : Disposable
{
    /// The window associated to the buffer.
    @property inout(PlatformWindow) window() inout;

    /// The buffer data encapsulated as image.
    @property inout(Image) image() inout;

    /// Blits the image pixels into the window native surface.
    /// Orig is at the same time the source and destination offset for
    /// reading and writing.
    void blit(in IPoint orig, in ISize size);
}
