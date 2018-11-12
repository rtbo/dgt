/// Animations module
module dgt.ui.animation;

import core.time;

import dgt : dgtTag;
import dgt.core.signal;
import dgt.ui;

import gfx.core.log;

abstract class Animation
{
    this(UserInterface ui) {
        _ui = ui;
    }
    this(UserInterface ui, in Duration dur) {
        _ui = ui;
        _duration = dur;
    }

    final @property UserInterface ui()
    {
        return _ui;
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
            warningf(dgtTag, "try to start a running animation: %s", name);
            return;
        }
        tracef(dgtTag, "starting animation %s", name);
        _running = true;
        _startTime = MonoTime.currTime;
        _lastTick = MonoTime.zero;
        _ui.requestPass(UIPass.frame);
        _ui.animManager.register(this);
        if (_onStart) _onStart.fire();
    }

    final void stop()
    {
        if (!_running) {
            warningf(dgtTag, "try to stop a non-running animation: %s", name);
            return;
        }
        tracef(dgtTag, "stopping animation %s", name);
        _running = false;
        _ui.animManager.unregister(this);
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

    abstract void tick(in Duration sinceStart);

    @property string name() const {
        return _name;
    }
    @property void name(in string value) {
        _name = value;
    }

private:
    UserInterface _ui;
    Duration _duration;
    MonoTime _startTime;
    MonoTime _lastTick;
    FireableSignal!() _onStart;
    FireableSignal!() _onStop;
    bool _running;
    string _name;
}

class TransitionAnimation : Animation
{
    this(UserInterface ui) {
        super(ui);
        _tickHandler = new Handler!float;
    }
    this(UserInterface ui, in Duration duration, in float from=0, in float to=1) {
        super(ui, duration);
        _from = from;
        _to = to;
        _tickHandler = new Handler!float;
    }

    @property float from() {
        return _from;
    }
    @property void from(in float value) {
        _from = value;
    }

    @property float to() {
        return _to;
    }
    @property void to(in float value) {
        _to = value;
    }

    /// map the time value to the value of the transition.
    /// Time ranges from 0 to 1. If the animation overshoot at the last tick,
    /// the time is clamped to 1.
    /// Returns: the phase of the transistion between 0 and 1.
    abstract float map(in float x);

    final @property void onTick(Slot!float handler) {
        if (_tickHandler.engaged) {
            warningf(dgtTag, "overriding animation tick handler: %s", name);
        }
        _tickHandler = handler;
    }

    final override void tick(in Duration sinceStart) {
        import std.algorithm : clamp;
        const x = clamp(sinceStart.total!"usecs" / cast(float)duration.total!"usecs", 0f, 1f);
        const y = from + map(x) * (to - from);
        _tickHandler.fire(y);
    }

private:
    float _from = 0;
    float _to = 1;
    Handler!float _tickHandler;
}

final class LinearTransitionAnimation : TransitionAnimation
{
    this(UserInterface ui) {
        super(ui);
    }
    this(UserInterface ui, in Duration duration, in float from=0, in float to=1) {
        super(ui, duration, from, to);
    }

    override float map(in float x) {
        return x;
    }
}

final class SmoothTransitionAnimation : TransitionAnimation
{
    this(UserInterface ui) {
        super(ui);
    }
    this(UserInterface ui, in Duration duration, in float from=0, in float to=1) {
        super(ui, duration, from, to);
    }

    override float map(in float x) {
        import std.algorithm : clamp;
        return clamp(x*x*(3 - 2*x), 0f, 1f);
    }
}

package(dgt.ui):

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
        assert(anim && anim.ui.animManager is this);
        assert(anim.running);
        assert(!_runningAnimations.canFind(anim));

        _runningAnimations ~= anim;
    }

    private void unregister(Animation anim)
    {
        import std.algorithm : canFind, remove;
        assert(anim && anim.ui.animManager is this);
        assert(!anim.running);
        assert(_runningAnimations.canFind(anim));

        _runningAnimations = _runningAnimations.remove!(a => a is anim);
    }

    Animation[] _runningAnimations;
}
