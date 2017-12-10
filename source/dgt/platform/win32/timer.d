/// Win32 timer implementation
module dgt.platform.win32.timer;

version(Windows):

import core.sys.windows.windows;
import core.time;

import dgt.application;
import dgt.core.signal;
import dgt.platform;
import dgt.platform.win32;

class Win32Timer : PlatformTimer
{
    UINT_PTR _timerId;
    UINT_PTR _timerHandle;
    Mode _mode;
    MonoTime _started;
    Duration _duration;
    uint _shots;
    bool _engaged;
    Slot!() _handler;

    uint _remShots;
    Mode _activeMode;

    this (in UINT_PTR timerId) {
        _timerId = timerId;
    }

    override void dispose() {
        if (_engaged) stop();
        auto wPl = cast(Win32Platform)Application.platform;
        wPl.releaseTimerID(_timerId);
    }

    @property Mode mode() {
        return _mode;
    }
    @property void mode(in Mode mode) {
        _mode = mode;
    }
    @property bool engaged() {
        return _engaged;
    }
    @property MonoTime started() {
        return _started;
    }
    @property Duration duration() {
        return _duration;
    }
    @property void duration(in Duration dur) {
        _duration = dur;
    }
    @property uint shots() {
        return _shots;
    }
    @property void shots(in uint val) {
        _shots = val;
    }

    @property Slot!() handler() {
        return _handler;
    }
    @property void handler(Slot!() slot) {
        _handler = slot;
    }

    void start() {
        _activeMode = _mode;
        _remShots = _shots;
        _started = MonoTime.currTime;
        _engaged = true;

        auto wPl = cast(Win32Platform)Application.platform;
        wPl.registerTimer(this);

        _timerHandle = SetTimer(null, _timerId, cast(UINT)_duration.total!"msecs", null);
    }

    void stop() {
        KillTimer(null, _timerHandle);

        auto wPl = cast(Win32Platform)Application.platform;
        wPl.unregisterTimer(this);

        _timerHandle = 0;
        _engaged = false;
        _remShots = 0;
    }

    void notifyShot() {
        switch (_activeMode) {
        case Mode.singleShot:
            stop();
            break;
        case Mode.multipleShots:
            _remShots -= 1;
            if (!_remShots) {
                stop();
            }
            break;
        default:
            break;
        }
    }

    @property UINT_PTR timerId() {
        return _timerId;
    }
}
