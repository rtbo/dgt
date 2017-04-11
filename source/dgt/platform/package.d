module dgt.platform;

import gfx.foundation.rc;
import dgt.geometry;
import dgt.screen;
import dgt.window;
import dgt.image;
import dgt.context;

import std.typecons : BitFlags;

interface Platform : Disposable
{
    void initialize();

    @property string name() const;

    shared(PlatformGlContext) createGlContext();

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

    @property size_t nativeHandle() const;

    @property string title() const;
    @property void title(string title);

    @property WindowState state() const;
    @property void state(WindowState state);

    @property IRect geometry() const;
    @property void geometry(IRect pos);

    PlatformWindowBuffer makeBuffer(in ISize size);
}

/// Per platform implementation of a GL context
shared interface PlatformGlContext
{
    bool realize(GlAttribs attribs,
                    PlatformWindow window,
                    shared(PlatformGlContext) sharedCtx,
                    Screen screen);
    bool makeCurrent(size_t nativeHandle);
    void doneCurrent();
    void swapBuffers(size_t nativeHandle);
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
