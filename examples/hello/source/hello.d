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

    // preparing drawing
    auto fillPaint = new ColorPaint();
    auto strokePaint = new ColorPaint(fvec(0.8, 0.2, 0.2, 1));
    auto textPaint = new ColorPaint(fvec(0, 0, 1, 1));

    // preparing text
    FontRequest font;
    font.family = "serif";
    font.size = FontSize.pts(100);

    immutable logoImg = assumeUnique (
        Image.loadFromImport!"dlang_logo.png"(ImageFormat.argb)
    );
    auto hello = new Label;
    hello.text = "Hello";
    hello.alignment = Alignment.center;

    auto icon = new Label;
    icon.icon = logoImg;
    icon.alignment = Alignment.center;

    auto layout = new LinearLayout;
    layout.orientation = Orientation.horizontal;
    layout.appendWidget(hello);
    layout.appendWidget(icon);
    layout.gravity = Gravity.center;

    win.root = layout;

    win.show();
    return app.loop();
}
