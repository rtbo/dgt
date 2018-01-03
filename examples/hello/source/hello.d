module hello;

import core.time : dur;

import dgt.application;
import dgt.core.color : Color;
import dgt.core.enums : Alignment;
import dgt.core.geometry;
import dgt.core.image;
import dgt.core.rc : rc;
import dgt.platform;
import dgt.ui : UserInterface;
import dgt.ui.label;
import dgt.window;

import gfx.foundation.typecons;

import std.exception;
import std.math : PI;
import std.stdio;
import std.typecons : scoped;

int main()
{
    auto app = new Application();
    scope(exit) app.dispose();

    auto ui = new UserInterface;

    immutable logoImg = assumeUnique (
        Image.loadFromView!"dlang_logo.png"(ImageFormat.argb)
    );
    auto label = new Label;
    label.text = "Hello";
    label.icon = logoImg;
    label.alignment = Alignment.center;
    label.id = "label";

    ui.root = label;

    import dgt.ui.animation : SmoothTransitionAnimation;
    auto anim = new SmoothTransitionAnimation(ui, dur!"seconds"(3));
    anim.name = "hello rotate";
    anim.onTick = (float phase) {
        import dgt.math.transform : rotation, scale, translation;
        import std.math : PI, sin;
        const size = label.size.asVec;
        const center = fvec(size/2, 0);
        const factor = 1 + cast(float)sin(phase*PI);
        const transform =
                translation!float(center) *
                rotation(phase*2*PI, fvec(0, 0, 1)) *
                scale(factor, factor, 1) *
                translation!float(-center);
        label.transform = transform;
    };

    auto win = new Window("Hello DGT");
    win.ui = ui;
    win.show();

    auto timer = Application.platform.createTimer();
    scope(exit) timer.dispose();
    timer.duration = dur!"seconds"(1);
    timer.mode = PlatformTimer.Mode.singleShot;
    timer.handler = &anim.start;
    timer.start();

    return app.loop();
}
