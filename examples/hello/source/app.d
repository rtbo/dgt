
import dgt.application;
import dgt.window;

import std.typecons : scoped;
import core.thread;
import core.time;


void main()
{
    auto app = new Application();
    auto win = new Window();
    win.show();
    Thread.sleep(dur!"msecs"(1000));
}
