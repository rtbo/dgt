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

    auto scene = new Scene;
    scene.clearColor = some(Color.blue);

    auto win = new Window("Hello DGT");
    win.scene = scene;
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
    auto sc = tf.makeScalingContext(32).rc;

    IVec2 bearing;
    auto gl = sc.renderGlyph(957, bearing);
    auto msdf = sc.renderGlyphMSDF(957, bearing);

    gl.saveToFile("glyph.png");
    msdf.saveToFile("msdf.png");

    return app.loop();
}
