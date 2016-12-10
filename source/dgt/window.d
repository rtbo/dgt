module dgt.window;

import dgt.platform;


enum WindowState {
    Normal,
    Maximized,
    Minimized,
    Fullscreen,
    Hidden
}


class Window
{

    private PlatformWindow platformWindow_;
}