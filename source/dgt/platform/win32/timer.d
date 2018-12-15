/// Win32 timer implementation
module dgt.platform.win32.timer;

version(Windows):

import core.sys.windows.windows;
import core.time;

import dgt.application;
import dgt.core.signal;
import dgt.platform;
import dgt.platform.win32;

import std.exception;

class Win32Timer : PlatformTimer
{
    HANDLE _handle;
    Mode _mode;
    MonoTime _started;
    Duration _duration;
    uint _shots;
    bool _engaged;
    Slot!() _handler;

    uint _remShots;
    Mode _activeMode;

    this () {
        _handle = CreateWaitableTimer(null, FALSE, null);
        enforce(_handle, "cannot create a win32 timer");
    }

    override void dispose() {
        if (_engaged) stop();
        CloseHandle(_handle);
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

        immutable dur = _duration.total!"hnsecs";
        immutable relDur = -dur;
        immutable LARGE_INTEGER dueTime = {
            QuadPart: relDur
        };
        immutable period = (_activeMode == Mode.singleShot) ? 0 : cast(LONG)dur;
        import std.format : format;
        enforce(SetWaitableTimer(
            _handle, &dueTime, period, null, null, FALSE
        ), format("could not set win32 timer: error code %s", GetLastError()));
    }

    void stop() {
        CancelWaitableTimer(_handle);

        auto wPl = cast(Win32Platform)Application.platform;
        wPl.unregisterTimer(this);

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

    @property HANDLE handle() {
        return _handle;
    }
}
