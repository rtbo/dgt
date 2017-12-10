// implementation of PlatformTimer with fd linux timer
module dgt.platform.xcb.timer;

version(linux):

import core.sys.linux.timerfd;
import core.sys.linux.time;
import core.sys.linux.unistd;

import core.time;

import dgt.application;
import dgt.core.signal;
import dgt.platform;
import dgt.platform.xcb;

final class LinuxFdTimer : PlatformTimer
{
    int _fd;
    Mode _mode;
    MonoTime _started;
    Duration _duration;
    uint _shots;
    bool _engaged;
    Slot!() _handler;

    uint _remShots;
    Mode _activeMode;

    this () {
        _fd = timerfd_create(CLOCK_MONOTONIC, 0);
    }

    override void dispose() {
        close(_fd);
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
        auto xcbP = cast(XcbPlatform)Application.platform;
        xcbP.registerTimer(this);

        _activeMode = _mode;
        _remShots = _shots;
        _started = MonoTime.currTime;
        _engaged = true;

        immutable durSpec = durToTimespec(_duration);
        itimerspec spec;
        spec.it_value = durSpec;
        if (_mode != Mode.singleShot) {
            spec.it_interval = durSpec;
        }
        timerfd_settime(_fd, 0, &spec, null);
    }

    void stop() {
        itimerspec spec;
        timerfd_settime(_fd, 0, &spec, null);

        _remShots = 0;
        _started = MonoTime.init;
        _engaged = false;

        auto xcbP = cast(XcbPlatform)Application.platform;
        xcbP.unregisterTimer(this);
    }

    @property int fd() {
        return _fd;
    }
    void notifyShot() {
        switch(_activeMode) {
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
}

timespec durToTimespec(in Duration duration) {
    immutable secs = duration.total!"seconds";
    immutable nsecs = (duration - dur!"seconds"(secs)).total!"nsecs";
    return timespec(secs, nsecs);
}
