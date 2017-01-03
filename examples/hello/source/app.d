import dgt.application;
import dgt.window;
import dgt.event;
import key = dgt.keys;
import dgt.vg;
import dgt.math.transform;
import dgt.text.fontcache;
import dgt.text.font;
import dgt.text.layout;
import dgt.core.resource;

import std.typecons : scoped;
import std.stdio;

int main()
{
    auto app = makeUniq!Application();
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

    // preparing text
    FontRequest font;
    font.family = "Serif";
    font.size = FontSize.pts(100);
    auto layout = makeRc!TextLayout("Hello", TextFormat.plain, font);
    layout.layout();

    win.onExpose += (WindowExposeEvent ev)
    {
        auto factory = win.vgFactory;
        auto ctx = factory.createContext().rc();
        auto fillPaint = factory.createPaint().rc();
        auto strokePaint = factory.createPaint().rc();
        auto textPaint = factory.createPaint().rc();

        immutable size = win.size;

        fillPaint.color = [size.width/1300f, 0.8, 0.2, 1.0];
        strokePaint.color = [0.8, 0.2, 0.2, 1.0];
        textPaint.color = [ 0.2, 0.2, 0.8, 1.0 ];

        {
            ctx.save();
            scope(exit) ctx.restore();

            ctx.fillPaint = fillPaint;
            ctx.strokePaint = strokePaint;
            ctx.lineWidth = 5f;
            auto p = new Path([size.width-10, 10]);
            p.lineTo([size.width-10, 400]);
            p.lineTo([size.width-400, 10]);
            ctx.drawPath(p, PaintMode.fill | PaintMode.stroke);
        }

        {
            ctx.save();
            scope(exit) ctx.restore();

            ctx.fillPaint = textPaint;
            ctx.transform = ctx.transform.translate(30, size.height-30);
            layout.renderInto(ctx);
        }

    };
    win.onClosed += (Window) { app.exit(0); };
    win.show();
    return app.loop();
}
