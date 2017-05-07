module hello;

import dgt.application;
import dgt.enums;
import dgt.event;
import dgt.geometry;
import dgt.image;
import dgt.keys;
import dgt.math;
import dgt.render.frame;
import dgt.render.node;
import dgt.sg.miscnodes;
import dgt.sg.node;
import dgt.sg.parent;
import dgt.text.font;
import dgt.text.fontcache;
import dgt.text.layout;
import dgt.vg;
import dgt.widget.group;
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
    win.onKeyDown = (KeyEvent ev) {
        switch (ev.sym)
        {
        case KeySym.f:
            win.showFullscreen();
            break;
        case KeySym.n:
            win.showNormal();
            break;
        case KeySym.m:
            win.showMaximized();
            break;
        case KeySym.s:
            win.showMinimized();
            break;
        case KeySym.escape:
            win.close();
            break;
        default:
            break;
        }
    };

    // preparing text
    FontRequest font;
    font.family = "serif";
    font.size = FontSize.pts(100);

    immutable logoImg = assumeUnique (
        Image.loadFromImport!"dlang_logo.png"(ImageFormat.argb)
    );
    auto hello = new Label;
    hello.name = "hello";
    hello.text = "Hello";
    hello.alignment = Alignment.center;
    hello.onMouseDown = (MouseEvent ev) { ev.consume(); writeln("hello mouse down"); };

    auto icon = new Label;
    icon.name = "icon";
    icon.icon = logoImg;
    icon.alignment = Alignment.center;

    auto layout = new LinearLayout;
    layout.name = "layout";
    layout.orientation = Orientation.horizontal;
    layout.appendWidget(hello);
    layout.appendWidget(icon);
    layout.gravity = Gravity.center;

    win.root = layout;

    win.show();
    return app.loop();
}
