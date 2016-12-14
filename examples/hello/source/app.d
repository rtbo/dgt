
import dgt.application;
import dgt.window;
import dgt.event;
import key = dgt.keys;

import std.typecons : scoped;
import std.stdio;


int main()
{
    auto app = new Application();
    auto win = new Window();
    win.onKeyDown += (WindowKeyEvent ev) {
        switch(ev.sym) {
            case key.Sym.f:
                win.showFullscreen();
                break;
            case key.Sym.n:
                win.showNormal();
                break;
            case key.Sym.m:
                win.showMaximized();
                break;
            case key.Sym.s:
                win.showMinimized();
                break;
            default:
                break;
        }
    };
    win.onClosed += (Window) {
        app.exit(0);
    };
    win.show();
    return app.loop();
}
