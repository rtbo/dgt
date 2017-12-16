module hello;

import core.time : dur;

import dgt.application;
import dgt.core.color : Color;
import dgt.core.rc : rc;
import dgt.scene.scene : Scene;
import dgt.window;

import gfx.foundation.typecons : some;

import std.math : PI;
import std.stdio;
import std.typecons : scoped;

int main()
{
    auto app = new Application();
    scope(exit) app.dispose();

    auto win = new Window("Hello DGT");

    auto sc = new Scene;
    win.scene = sc;
    sc.clearColor = some(Color.blue);

    win.show();

    auto timer = Application.platform.createTimer();
    timer.duration = dur!"seconds"(2);
    timer.handler = &win.close;
    timer.start();
    scope(exit) timer.dispose();

    import dgt.font.library : FontLibrary;
    import dgt.font.style : FontStyle;
    auto fl = FontLibrary.create();
    auto fs = fl.matchFamily("serif").rc;
    foreach(const i; 0 .. fs.styleCount) {
        writeln(fs.style(i));
    }

    return app.loop();
}
