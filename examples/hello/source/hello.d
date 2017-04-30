module hello;

import dgt.application;
import dgt.event;
import dgt.geometry;
import dgt.image;
import dgt.keys;
import dgt.math;
import dgt.render.frame;
import dgt.render.node;
import dgt.sg.group;
import dgt.sg.miscnodes;
import dgt.sg.node;
import dgt.text.font;
import dgt.text.fontcache;
import dgt.text.layout;
import dgt.vg;
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
    win.onKeyDown += (KeyEvent ev) {
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

    auto helloNode = textNode("Hello", font, textPaint);
    helloNode.name = "hello-en";
    auto arHelloNode = textNode("مرحبا", font, textPaint);
    arHelloNode.name = "hello-ar";

    immutable logoImg = assumeUnique(Image.loadFromImport!"dlang_logo.png"(ImageFormat.argb));
    auto logoNode = new SgImage;
    logoNode.image = logoImg;
    logoNode.name = "logo";

    auto root = new SgGroup;
    root.name = "root";
    root.appendChild(helloNode);
    root.appendChild(arHelloNode);
    root.appendChild(logoNode);

    writeln(root.toString());

    win.onResize += (ResizeEvent ev) {
        helloNode.transform = FMat4.identity.translate(50, ev.size.height-50, 0);
        arHelloNode.transform = FMat4.identity.translate(ev.size.width-350, 150, 0);
        logoNode.transform = FMat4.identity.translate(
            ev.size.width-logoImg.width-10, ev.size.height-logoImg.height-10, 0
        );
    };

    win.root = root;

    // auto tree = FractalBranch(branchStart, 0, 1, numFractalLevels);
    // auto treePath = new Path([0, 0]);
    // treePath.lineTo([branchVec.x, branchVec.y]);

    win.show();
    return app.loop();
}

private:

SgNode textNode(string text, FontRequest font, Paint paint)
{
    auto textNode = new SgText;
    textNode.text = text;
    textNode.font = font;
    textNode.color = (cast(ColorPaint)paint).color;
    immutable metrics = textNode.metrics;
    immutable topLeft = cast(FVec2)(-metrics.bearing);

    auto ulNode = new SgColorRect;
    ulNode.color = fvec(1, 1, 1, 0.5);
    ulNode.rect = FRect(topLeft.x, 5, metrics.size.x, 5);

    auto node = new SgGroup;
    node.appendChild(textNode);
    node.appendChild(ulNode);
    return node;
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
