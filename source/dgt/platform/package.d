module dgt.platform;

import dgt.core.resource;
import dgt.geometry;
import dgt.screen;
import dgt.window;
import dgt.vg;

import std.typecons : BitFlags;

enum PlaformCaps
{
    none = 0,
    openGL = 1,
    openGLES = 2,
    openVG = 4,
}

alias PlatformCapsFlags = BitFlags!PlaformCaps;

interface Platform : Disposable
{
    @property string name() const;
    @property PlatformCapsFlags caps() const;
    @property inout(Screen) defaultScreen() inout;
    @property inout(Screen)[] screens() inout;
    PlatformWindow createWindow(Window window);
    void processNextEvent();
}

interface PlatformWindow
{
    bool created() const;
    void create(WindowState state);
    void close();

    @property string title() const;
    @property void title(string title);

    @property WindowState state() const;
    @property void state(WindowState state);

    @property IRect geometry() const;
    @property void geometry(IRect pos);

    @property VgFactory vgFactory();
}
