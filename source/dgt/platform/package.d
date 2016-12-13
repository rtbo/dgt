module dgt.platform;

import dgt.geometry;
import dgt.screen;
import dgt.window;


interface Platform
{
    @property string name() const;
    @property inout(Screen)[] screens() inout;
    PlatformWindow createWindow(Window window);
    void shutdown();
}


interface PlatformWindow
{
    bool created() const;
    void create(WindowState state);

    @property string title() const;
    @property void title(string title);

    @property WindowState state() const;
    @property void state(WindowState state);

    @property IRect geometry() const;
    @property void geometry(IRect pos);
}
