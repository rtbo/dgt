module hello;

import core.time : dur;

import dgt.application;
import dgt.core.color : Color;
import dgt.core.geometry;
import dgt.core.image;
import dgt.core.rc : rc;
import dgt.font.library;
import dgt.font.style;
import dgt.font.typeface;
import dgt.platform;
import dgt.ui : UserInterface;
import dgt.ui.layout;
import dgt.ui.text;
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

    struct Proverb {
        string text;
        string css;
    }
    Proverb[] proverbs = [
        Proverb(`Assiduity makes all things easy.`,
                `font: 26px serif`),
        Proverb(`Le visage est le miroir du cœur.`,
                `font: italic 0.8cm "Times New Roman", "Nimbus Roman", serif`),
        Proverb(`Früh steh auf, wer ein Meister werden will.`,
                `font: italic 1.5em serif`),
        Proverb(`لاتنفق كلمتين اذا كفتك كلمة ـ مثل عربي`,
                `font: 30px "Droid Arabic Naskh"`), // try a specific font, if not present fallback to default
        Proverb(`花开堪折直需折`,
                `font: 0.5in`),         // default family for chinese text
        Proverb(`あつささむさもひがんまで`,
                `font: 0.4in` ),        // default family for japanese text
    ];

    auto ui = new UserInterface;
    ui.clearColor = some(Color.black);
    auto layout = new LinearLayout;
    layout.id = "layout";
    layout.setVertical();
    layout.gravity = Gravity.center;
    layout.spacing = 20;

    TextView french;

    foreach (i, p; proverbs) {
        import std.format : format;
        auto view = new TextView;
        view.id = format("text%s", i+1);
        view.text = p.text;
        view.inlineCSS = p.css;
        view.color = Color.white;
        layout.appendView(view);
        if (i==1) french = view;
    }
    ui.root = layout;


    import dgt.ui.animation;
    auto anim = new SmoothTransitionAnimation(ui, dur!"seconds"(3));
    anim.onTick = (float phase) {
        import dgt.math.transform : rotation, scale, translation;
        import std.math : PI, sin;
        const size = french.size.asVec;
        const center = fvec(size/2, 0);
        const factor = 1 + cast(float)sin(phase*PI);
        const transform =
                translation!float(center) *
                rotation(phase*2*PI, fvec(0, 0, 1)) *
                scale(factor, factor, 1) *
                translation!float(-center);
        french.transform = transform;
    };

    auto win = new Window("Hello DGT");
    win.ui = ui;
    win.show();

    auto timer = Application.platform.createTimer();
    timer.duration = dur!"seconds"(2);
    timer.mode = PlatformTimer.Mode.singleShot;
    timer.handler = &anim.start;
    timer.start();
    scope(exit) timer.dispose();

    return app.loop();
}
