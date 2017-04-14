module hello;

import gfx.foundation.rc;
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
import dgt.image;
import dgt.geometry;

import std.typecons : scoped;
import std.stdio;
import std.math : PI;

int main()
{
    auto app = new Application();
    scope(exit) app.dispose();

    auto win = new Window("Hello DGT");
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
    auto fillPaint = new ColorPaint();
    auto strokePaint = new ColorPaint(fvec(0.8, 0.2, 0.2, 1));
    auto textPaint = new ColorPaint(fvec(0, 0, 1, 1));

    // preparing text
    FontRequest font;
    font.family = "serif";
    font.size = FontSize.pts(100);
    auto layout = makeRc!TextLayout("Hello", TextFormat.plain, font);
    layout.layout();
    // This is "hello" for those who wonder.
    auto arLayout = makeRc!TextLayout("مرحبا", TextFormat.plain, font);
    arLayout.layout();

    auto img = Image.loadFromImport!"dlang_logo.png"(ImageFormat.argbPremult);

    auto tree = FractalBranch(branchStart, 0, 1, numFractalLevels);
    auto treePath = new Path([0, 0]);
    treePath.lineTo([branchVec.x, branchVec.y]);

    win.onRequestFrame = () {
        immutable size = win.size;
        auto frameImg = new Image(ImageFormat.argbPremult, size);
        {
            auto ctx = createContext(frameImg);
            scope(exit) ctx.dispose();

            ctx.clear([0, 0, 0, 0]);

            ctx.sandbox!({
                fillPaint.color = fvec(size.width/1300f, 0.8, 0.2, 1);
                ctx.fillPaint = fillPaint;
                ctx.strokePaint = strokePaint;
                ctx.lineWidth = 5f;
                auto p = new Path([size.width-10, 10]);
                p.lineTo([size.width-10, 400]);
                p.lineTo([size.width-400, 10]);
                ctx.drawPath(p, PaintMode.fill | PaintMode.stroke);
            });

            ctx.sandbox!({
                ctx.lineWidth = 5f;
                tree.draw(treePath, ctx);
            });

            ctx.sandbox!({
                ctx.fillPaint = textPaint;
                ctx.transform = ctx.transform.translate(30, size.height-30);
                layout.renderInto(ctx);
            });

            ctx.sandbox!({
                ctx.fillPaint = textPaint;
                ctx.transform = ctx.transform.translate(size.width-400, 150);
                arLayout.renderInto(ctx);
            });

            ctx.sandbox!({
                ctx.transform = ctx.transform.translate(
                    size.width - img.width - 10,
                    size.height - img.height - 10
                );
                ctx.drawImage(img);
            });
        }

        // import std.format : format;
        // static int num;
        // frameImg.convert(ImageFormat.argb).saveToFile(format("img%s.png",++num));

        import dgt.sg.rendernode : ImageRenderNode;
        import dgt.sg.renderframe : RenderFrame;

        immutable node = new immutable ImageRenderNode (
            fvec(0, 0), assumeUnique(frameImg)
        );
        return new immutable RenderFrame(
            win.nativeHandle, IRect(0, 0, size), fvec(0.6, 0.7, 0.8, 1), node
        );
    };

    win.show();
    return app.loop();
}

private:

enum branchScale = 0.7f;
enum branchAngle = PI / 8;
immutable branchVec = fvec(0, -150);
immutable branchStart = fvec(320, 460);
immutable subBranches = [ 1.5, -0.5, -2.0 ];
enum numFractalLevels = 5;

struct FractalBranch
{
    Transform base;
    FractalBranch[] branches;

    this(in FVec2 pos, in real angle, in float scale, in int remainingDepth)
    {
        assert(remainingDepth >= 0);

        this.base = Transform.identity
            .scale(scale, scale)
            .rotate(angle)
            .translate(pos);

        if (remainingDepth)
        {
            immutable endPos = pos +
                branchVec.transform(
                    Transform.identity
                        .scale(scale, scale)
                        .rotate(angle)
                );
            void addBranch(in real angle)
            {
                branches ~= FractalBranch (
                    endPos, angle, scale*branchScale, remainingDepth-1
                );
            }

            import std.algorithm : each;

            subBranches.each!(
                sb => addBranch(angle + sb * branchAngle)
            );
        }
    }



    void draw(in Path path, VgContext context)
    {
        context.sandbox!({
            context.transform = base;
            context.drawPath(path, PaintMode.stroke);
        });
        foreach(br; branches)
        {
            br.draw(path, context);
        }
    }

}
