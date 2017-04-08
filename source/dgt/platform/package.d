module dgt.platform;

import dgt.core.resource;
import dgt.geometry;
import dgt.screen;
import dgt.window;
import dgt.image;
import dgt.gfx;

import std.typecons : BitFlags;

interface Platform : Disposable
{
    void initialize();

    @property string name() const;

    PlatformGlContext createGlContext();

    @property inout(Screen) defaultScreen() inout;
    @property inout(Screen)[] screens() inout;
    PlatformWindow createWindow(Window window);
    void processNextEvent();
}

interface PlatformWindow
{
    @property inout(Window) window() inout;

    bool created() const;
    void create(WindowState state);
    void close();

    @property string title() const;
    @property void title(string title);

    @property WindowState state() const;
    @property void state(WindowState state);

    @property IRect geometry() const;
    @property void geometry(IRect pos);

    PlatformWindowBuffer makeBuffer(in ISize size);
}

/// Per platform implementation of a GL context
interface PlatformGlContext
{
    bool realize(GlAttribs attribs,
                    PlatformWindow window,
                    PlatformGlContext sharedCtx,
                    Screen screen);
    bool makeCurrent(PlatformWindow window);
    void doneCurrent();
    void swapBuffers(PlatformWindow window);
}

/// A native buffer image suitable for blitting pixels on screen.
/// Top left corner of this buffer image fit with the top left corner of the
/// window.
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
