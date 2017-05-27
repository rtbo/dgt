module hello;

import dgt.application;
import dgt.enums;
import dgt.event;
import dgt.geometry;
import dgt.image;
import dgt.math;
import dgt.sg.miscnodes;
import dgt.sg.node;
import dgt.text.font;
import dgt.text.fontcache;
import dgt.text.layout;
import dgt.widget.button;
import dgt.widget.label;
import dgt.widget.layout;
import dgt.window;

import gfx.foundation.rc;

import std.typecons : scoped;
import std.stdio;
import std.math : PI;

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
    hello.cssStyle = "font-family: serif; font-style: italic; font-size: 1in;";

    auto icon = new Label;
    icon.name = "icon";
    icon.icon = logoImg;
    icon.alignment = Alignment.center;

    auto layout = new LinearLayout;
    layout.name = "layout";
    layout.orientation = Orientation.horizontal;
    layout.appendWidget(hello);
    layout.appendWidget(icon);
    layout.spacing = 6;
    layout.gravity = Gravity.center;

    auto exit = new Button;
    exit.name = "exit";
    exit.text = "Exit";
    exit.onClick += {
        app.exit(0);
    };

    auto root = new LinearLayout;
    root.name = "root";
    root.setVertical();
    root.appendWidget(layout);
    root.appendWidget(exit);
    root.spacing = 6;
    root.gravity = Gravity.center;
    root.cssStyle = `
        :root { background-color: lavenderblush; }
    `;

    win.root = root;

    win.show();
    return app.loop();
}
