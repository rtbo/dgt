module hello;

import core.time : dur;

import dgt.application;
import dgt.core.color : Color;
import dgt.core.geometry;
import dgt.core.image;
import dgt.core.rc : rc;
import dgt.font.msdfgen;
import dgt.font.msdfgen.shape;
import dgt.scene.scene : Scene;
import dgt.window;

import gfx.foundation.typecons : some;

import std.exception;
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

    auto tf = fs.createTypeface(0).rc;
    auto shape = buildShape(tf, 1896);
    enforce(shape.valid);
    shape.normalize();

    edgeColoringSimple(shape, 3f, 0);

    auto data = new ubyte[32*32*4];
    auto img = new Image(data, ImageFormat.xrgb, 32, 32*4);
    generateMSDF(img, shape, 2, FVec2(1, 1), FVec2(0, 8), 1);
    img.saveToFile("msdf.png");

    return app.loop();
}
