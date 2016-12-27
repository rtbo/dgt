import dgt.application;
import dgt.window;
import dgt.event;
import key = dgt.keys;
import dgt.vg;
import dgt.resource;

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
    win.onExpose += (WindowExposeEvent ev)
    {
        auto factory = win.vgFactory;
        auto ctx = factory.createContext().rc();
        auto fillPaint = factory.createPaint().rc();
        auto strokePaint = factory.createPaint().rc();

        immutable width = win.size.width;
        fillPaint.color = [width/1300f, 0.8, 0.2, 1.0];
        strokePaint.color = [0.8, 0.2, 0.2, 1.0];
        ctx.fillPaint = fillPaint;
        ctx.strokePaint = strokePaint;

        ctx.lineWidth = 5f;
        auto p = new Path([width-10, 10]);
        p.lineTo([width-10, 400]);
        p.lineTo([width-400, 10]);
        ctx.drawPath(p, PaintMode.fill | PaintMode.stroke);

        import dgt.text.font;
        import dgt.text.fontcache;
        import dgt.text.layout;
        import dgt.text.shaper;

        FontRequest font;
        font.family = "Courier";
        font.size = FontSize.pts(100);
        auto layout = makeRc!TextLayout("Hello", TextFormat.plain, font);
        layout.layout();
        auto shape = TextShaper.instance.shape(layout.items()[0]);
        auto glyph = shape.font.renderGlyph(shape.glyphs[0].index);
        ctx.mask(glyph.bitmap);
    };
    win.onClosed += (Window) { app.exit(0); };
    win.show();
    return app.loop();
}
