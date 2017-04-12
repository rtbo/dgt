module dgt.sg.renderer;

import dgt.context;
import dgt.geometry;
import dgt.sg.rendernode;
import dgt.sg.renderframe;

import gfx.foundation.rc;
import gfx.pipeline;
import gfx.device;
import gfx.device.gl3;

import std.concurrency;
import std.exception;
import std.stdio;

Tid startRenderLoop(shared(GlContext) context)
{
    return spawn(&renderLoop, context, thisTid);
}

bool renderFrame(Tid renderLoopTid, immutable(RenderFrame) frame)
{
    import core.time : dur;
    writeln("main: will call receive");
    if (!receiveTimeout(dur!"msecs"(15), (ReadyToRender rr){})) {
        writeln("main: timed out!");
        return false;
    }
    writeln("main: will call send");
    send(renderLoopTid, frame);
    writeln("main: done");
    return true;
}

private:

struct ReadyToRender {}


void renderLoop(shared(GlContext) context, Tid mainLoopTid)
{
    auto renderer = new Renderer(context);

    while (true)
    {
        writeln("render: will call send");
        send(mainLoopTid, ReadyToRender());
        writeln("render: done!\nrender: will call receive");
        receive(
            (immutable(RenderFrame) frame) {
                writeln("render: received frame!");
                renderer.renderFrame(frame);
                writeln("render: rendered frame!");
            }
        );
    }
}


class Renderer
{
    shared(GlContext) _context;
    Device _device;
    Encoder _encoder;
    BuiltinSurface!Rgba8 _surf;
    RenderTargetView!Rgba8 _rtv;
    ISize _size;

    this(shared(GlContext) context)
    {
        _context = context;
    }

    void initialize() {
        _device = enforce(createGlDevice());
        _device.retain();

        _surf = new BuiltinSurface!Rgba8(
            _device.builtinSurface,
            cast(ushort)_size.width, cast(ushort)_size.height,
            _context.attribs.samples
        );
        _surf.retain();

        _rtv = _surf.viewAsRenderTarget();
        _rtv.retain();

        _encoder = Encoder(_device.makeCommandBuffer());
    }

    void renderFrame(immutable(RenderFrame) frame)
    {
        if (!_context.makeCurrent(frame.windowHandle)) {
            return;
        }
        scope(exit) _context.doneCurrent();

        _size = frame.viewport.size;
        if (!_device) {
            initialize();
        }

        immutable vp = cast(TRect!ushort)frame.viewport;
        _encoder.setViewport(vp.x, vp.y, vp.width, vp.height);

        if (frame.hasClearColor) {
            auto col = frame.clearColor;
            _encoder.clear!Rgba8(_rtv, [col.r, col.g, col.b, col.a]);
        }

        if (frame.root) {
            renderNode(frame.root);
        }

        _encoder.flush(_device);
        _context.swapBuffers(frame.windowHandle);
    }

    void renderNode(immutable(RenderNode) node)
    {

    }
}
