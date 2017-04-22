module dgt.eventloop;

import dgt.application;
import dgt.event;

/// An event loop
class EventLoop
{
    /// Enter event processing loop
    int loop()
    {
        while (!_exitFlag) {
            Application.instance.platform.processEvents();
        }
        return _exitCode;
    }

    /// Register an exit code and exit at end of current event loop
    void exit(int code = 0)
    {
        _exitCode = code;
        _exitFlag = true;
    }

    protected bool _exitFlag;
    protected int _exitCode;
}
