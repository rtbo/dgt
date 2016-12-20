module dgt.vg;

public import dgt.vg.context;
public import dgt.vg.paint;
public import dgt.vg.path;
import dgt.surface;

/// A factory attached to a particular surface
interface VgFactory
{
    @property inout(Surface) surface() inout;
    VgContext createContext();
    Paint createPaint();
}
