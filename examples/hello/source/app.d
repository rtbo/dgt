import dgt.core.resource;
import dgt.application;
import dgt.window;
import dgt.event;
import key = dgt.keys;
import dgt.vg;
import dgt.math.transform;
import dgt.math.vec;
import dgt.text.fontcache;
import dgt.text.font;
import dgt.text.layout;

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
        case key.Sym.escape:
            win.close();
            break;
        default:
            break;
        }
    };

    // preparing drawing
    auto fillPaint = makeRc!ColorPaint();
    auto strokePaint = makeRc!ColorPaint(fvec(0.8, 0.2, 0.2, 1));
    auto textPaint = makeRc!ColorPaint(fvec(0, 0, 1, 1));

    // preparing text
    FontRequest font;
    font.family = "Serif";
    font.size = FontSize.pts(100);
    auto layout = makeRc!TextLayout("Hello", TextFormat.plain, font);
    layout.layout();

    win.onExpose += (WindowExposeEvent /+ev+/)
    {
        auto surf = win.surface.rc;
        auto ctx = createContext(surf).rc;

        immutable size = win.size;

        fillPaint.color = fvec(size.width/1300f, 0.8, 0.2, 1);

        ctx.sandbox!({
            ctx.fillPaint = fillPaint;
            ctx.strokePaint = strokePaint;
            ctx.lineWidth = 5f;
            auto p = new Path([size.width-10, 10]);
            p.lineTo([size.width-10, 400]);
            p.lineTo([size.width-400, 10]);
            ctx.drawPath(p, PaintMode.fill | PaintMode.stroke);
        });

        ctx.sandbox!({
            ctx.fillPaint = textPaint;
            ctx.transform = ctx.transform.translate(30, size.height-30);
            layout.renderInto(ctx);
        });

    };
    win.show();
    return app.loop();
}
