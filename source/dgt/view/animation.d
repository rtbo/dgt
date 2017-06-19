module dgt.view.animation;

import core.time;
public import core.time : dur, Duration, MonoTime;

import dgt.event.handler;
import dgt.window;

import std.experimental.logger;


abstract class Animation
{
    this(Window window) {
        _window = window;
    }
    this(Window window, in Duration dur) {
        _window = window;
        _duration = dur;
    }

    final @property Window window()
    {
        return _window;
    }

    final @property Duration duration()
    {
        return _duration;
    }

    final @property void duration(in Duration dur)
    {
        _duration = dur;
    }

    final void start()
    {
        if (_running) {
            warning("try to start a running animation");
            return;
        }
        _running = true;
        _startTime = MonoTime.currTime;
        _lastTick = MonoTime.zero;
        _window.invalidate();
        _window.animManager.register(this);
        if (_onStart) _onStart.fire();
    }

    final void stop()
    {
        if (!_running) {
            warning("try to stop a non-running animation");
            return;
        }
        _running = false;
        _window.animManager.unregister(this);
        if (_onStop) _onStop.fire();
    }

    final @property bool running()
    {
        return _running;
    }

    final @property Signal!() onStart(Slot!() slot) {
        if (!_onStart) _onStart = new FireableSignal!();
        return _onStart;
    }
    final @property Signal!() onStop(Slot!() slot) {
        if (!_onStop) _onStop = new FireableSignal!();
        return _onStop;
    }

    final @property MonoTime startTime() {
        return _startTime;
    }

    abstract void tick(Duration sinceStart);

private:
    Window _window;
    Duration _duration;
    MonoTime _startTime;
    MonoTime _lastTick;
    FireableSignal!() _onStart;
    FireableSignal!() _onStop;
    bool _running;
}


package(dgt):

final class AnimationManager
{
    @property bool hasAnimations()
    {
        return _runningAnimations.length > 0;
    }

    void tick() {
        immutable t = MonoTime.currTime;

        foreach (anim; _runningAnimations) {
            if (anim.duration <= Duration.zero ||
                anim._lastTick < (anim.startTime + anim.duration))
            {
                anim.tick(t - anim.startTime);
                anim._lastTick = t;
            }
            else {
                anim.stop();
            }
        }
    }

    private void register(Animation anim)
    {
        import std.algorithm : canFind;
        assert(anim && anim.window.animManager is this);
        assert(anim.running);
        assert(!_runningAnimations.canFind(anim));

        _runningAnimations ~= anim;
    }

    private void unregister(Animation anim)
    {
        import std.algorithm : canFind, remove;
        assert(anim && anim.window.animManager is this);
        assert(!anim.running);
        assert(_runningAnimations.canFind(anim));

        _runningAnimations = _runningAnimations.remove!(a => a is anim);
    }

    Animation[] _runningAnimations;
}
