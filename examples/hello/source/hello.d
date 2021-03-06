module hello;

import core.time : dur;

import dgt.application;
import dgt.core.enums : Alignment;
import dgt.gfx.color : Color;
import dgt.gfx.geometry;
import dgt.gfx.image;
import dgt.platform;
import dgt.ui : UserInterface;
import dgt.ui.button;
import dgt.ui.checkbox;
import dgt.ui.label;
import dgt.ui.layout;
import dgt.window;

import gfx.core.rc : rc;
import gfx.core.typecons;

import std.exception;
import std.math : PI;
import std.stdio;
import std.typecons : scoped;

int main()
{
    {
        import gfx.core.log : Severity, severity;
        severity = Severity.trace;
    }
    debug(rc) {
        //import gfx.core.rc : rcPrintStack, rcTypeRegex;
        //rcPrintStack = true;
        //rcTypeRegex = "Typeface";
    }

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
    // {
    //     import gfx.math.transform : rotation, scale, translation;
    //     import std.math : PI;
    //     const size = label.size.asVec;
    //     const center = fvec(size/2, 0);
    //     const factor = 1.5f;
    //     const transform =
    //             translation(center) *
    //             rotation(0.1*2*PI, fvec(0, 0, 1)) *
    //             scale(factor, factor, 1) *
    //             translation(-center);
    //     label.transform = transform;
    // }

    auto btn = new Button;
    btn.text = "Exit?";
    btn.alignment = Alignment.center;
    btn.id = "button";

    auto cb = new CheckBox;
    cb.text = "Exit";
    cb.alignment = Alignment.center;
    cb.id = "checkbox";

    btn.onClick += {
        if (cb.checked) app.exit(0);
    };

    auto layout = new LinearLayout;
    layout.setVertical();
    layout.appendView(label);
    layout.appendView(btn);
    layout.appendView(cb);
    layout.gravity = Gravity.center;

    ui.root = layout;

    import dgt.ui.animation : SmoothTransitionAnimation;
    auto anim = new SmoothTransitionAnimation(ui, dur!"seconds"(3));
    anim.name = "hello rotate";
    anim.onTick = (float phase) {
        import gfx.math.transform : rotation, scale, translation;
        import std.math : PI, sin;
        const size = label.size.asVec;
        const center = fvec(size/2, 0);
        const factor = 1 + cast(float)sin(phase*PI);
        const transform =
                translation(center) *
                rotation(phase*2*PI, fvec(0, 0, 1)) *
                scale(factor, factor, 1) *
                translation(-center);
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
    //timer.start();

    return app.loop();
}
