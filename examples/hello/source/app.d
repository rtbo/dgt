import dgt.application;
import dgt.window;
import dgt.event;
import key = dgt.keys;
import dgt.vg;

import std.typecons : scoped;
import std.stdio;

int main()
{
    auto app = new Application();
    auto win = new Window();
    win.onKeyDown += (WindowKeyEvent ev) {
        switch (ev.sym)
        {
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
    win.onExpose += (WindowExposeEvent ev)
    {
        auto factory = win.vgFactory;
        auto ctx = factory.createContext();
        auto fillPaint = factory.createPaint();
        auto strokePaint = factory.createPaint();

        scope (exit)
        {
            strokePaint.dispose();
            fillPaint.dispose();
            ctx.dispose();
        }

        fillPaint.color = [0.8, 0.8, 0.2, 1.0];
        strokePaint.color = [0.8, 0.2, 0.2, 1.0];
        ctx.fillPaint = fillPaint;
        ctx.strokePaint = strokePaint;

        ctx.lineWidth = 5f;
        auto p = new Path([10, 10]);
        p.lineTo([10, 400]);
        p.lineTo([400, 10]);
        ctx.drawPath(p, PaintMode.fill | PaintMode.stroke);
    };
    win.onClosed += (Window) { app.exit(0); };
    win.show();
    return app.loop();
}
