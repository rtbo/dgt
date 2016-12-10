module dgt.window;

import dgt.platform;


enum WindowState
{
    normal,
    maximized,
    minimized,
    fullscreen,
    hidden
}


class Window
{
    private PlatformWindow platformWindow_;
}