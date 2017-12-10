module hello;

import core.time : dur;

import dgt.application;
import dgt.core.color : Color;
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

    return app.loop();
}
