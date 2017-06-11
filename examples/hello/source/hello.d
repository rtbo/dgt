module hello;

import dgt.application;
import dgt.enums;
import dgt.event;
import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.text.font;
import dgt.text.fontcache;
import dgt.text.layout;
import dgt.view.button;
import dgt.view.label;
import dgt.view.layout;
import dgt.view.miscviews;
import dgt.view.view;
import dgt.window;

import gfx.foundation.rc;

import std.math : PI;
import std.stdio;
import std.typecons : scoped;

int main()
{
    auto app = new Application();
    scope(exit) app.dispose();

    auto win = new Window("Hello DGT");

    immutable logoImg = assumeUnique (
        Image.loadFromImport!"dlang_logo.png"(ImageFormat.argb)
    );
    auto hello = new Label;
    hello.name = "hello";
    hello.text = "Hello";
    hello.alignment = Alignment.center;
    hello.css = "font: italic 1in serif";

    auto icon = new Label;
    icon.name = "icon";
    icon.icon = logoImg;
    icon.alignment = Alignment.center;

    auto layout = new LinearLayout;
    layout.name = "layout";
    layout.orientation = Orientation.horizontal;
    layout.appendChild(hello);
    layout.appendChild(icon);
    layout.spacing = 6;
    layout.gravity = Gravity.center;

    auto exit = new Button;
    exit.name = "exit";
    exit.text = "Exit";
    exit.css = "font-size: 40px";
    exit.padding = FPadding(16);
    exit.onClick += {
        app.exit(0);
    };

    auto root = new LinearLayout;
    root.name = "root";
    root.setVertical();
    root.appendChild(layout);
    root.appendChild(exit);
    root.spacing = 6;
    root.gravity = Gravity.center;
    root.css = `
        :root { background-color: lavenderblush; }
    `;

    win.root = root;

    win.show();
    return app.loop();
}
