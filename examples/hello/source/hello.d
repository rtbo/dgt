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
import dgt.sg.rendernode;
import dgt.sg.renderframe;

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

    immutable helloNode = textNode("Hello", font, textPaint);
    immutable arHelloNode = textNode("مرحبا", font, textPaint);

    immutable logoImg = assumeUnique(Image.loadFromImport!"dlang_logo.png"(ImageFormat.argb));
    immutable logoNode = new immutable ImageRenderNode(FPoint(0, 0), logoImg);

    auto tree = FractalBranch(branchStart, 0, 1, numFractalLevels);
    auto treePath = new Path([0, 0]);
    treePath.lineTo([branchVec.x, branchVec.y]);

    win.onRequestFrame = () {
        import dgt.math.mat : FMat4;

        immutable size = win.size;

        immutable renderTree = new immutable GroupRenderNode([
            new immutable TransformRenderNode(
                FMat4.identity.translate(50, size.height-50, 0), helloNode
            ),
            new immutable ColorRenderNode(
                fvec(1, 1, 1, 0.5), FRect(50+helloNode.bounds.left, size.height-45, helloNode.bounds.width, 5)
            ),
            new immutable TransformRenderNode(
                FMat4.identity.translate(size.width-350, 150, 0), arHelloNode
            ),
            new immutable ColorRenderNode(
                fvec(1, 1, 1, 0.5), FRect(size.width-350+arHelloNode.bounds.left, 155, arHelloNode.bounds.width, 5)
            ),
            new immutable TransformRenderNode(
                FMat4.identity.translate(size.width-logoImg.width-10,
                                size.height-logoImg.height-10, 0),
                logoNode
            ),
        ]);

        return new immutable RenderFrame(
            win.nativeHandle, IRect(0, 0, size), fvec(0.6, 0.7, 0.8, 1), renderTree
        );
    };

    win.show();
    return app.loop();
}

private:


immutable(RenderNode) textNode(string text, FontRequest font, Paint paint)
{
    auto layout = makeRc!TextLayout(text, TextFormat.plain, font);
    layout.layout();
    immutable metrics = layout.metrics;
    auto img = new Image(ImageFormat.argbPremult, ISize(metrics.size));
    {
        auto ctx = createContext(img);
        scope(exit) ctx.dispose();

        ctx.transform = Transform.identity.translate(metrics.bearing);
        ctx.fillPaint = paint;
        layout.renderInto(ctx);
    }
    return new immutable ImageRenderNode(cast(FVec2)(-metrics.bearing), assumeUnique(img));
}


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
