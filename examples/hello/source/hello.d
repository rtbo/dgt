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
        // Proverb("A", "font: 1in serif"),
        Proverb("Assiduity makes all things easy.",             "font: 1in serif"),
        Proverb("Le visage est le miroir du coeur.",            "font: italic 14px serif" ),
        // Proverb("Früh steh auf, wer ein Meister werden will",   "font: italic 1cm serif" ),
        // Proverb("لاتنفق كلمتين اذا كفتك كلمة ـ مثل عربي",        "font: 12px serif"),
        // Proverb("花开堪折直需折",                                  "font: 12px serif" ),
        // Proverb("あつささむさもひがんまで",                         "font: 12px serif" ),
    ];

    auto ui = new UserInterface;
    ui.clearColor = some(Color.blue);
    auto layout = new LinearLayout;
    layout.setVertical();
    layout.gravity = Gravity.center;

    foreach (p; proverbs) {
        auto view = new TextView;
        view.text = p.text;
        view.inlineCSS = p.css;
        layout.appendView(view);
    }
    ui.root = layout;

    auto win = new Window("Hello DGT");
    win.ui = ui;
    win.show();

    // auto timer = Application.platform.createTimer();
    // timer.duration = dur!"seconds"(10);
    // timer.handler = &win.close;
    // timer.start();
    // scope(exit) timer.dispose();

    return app.loop();
}
