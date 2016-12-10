module dgt.platform;

import dgt.geometry;


interface Platform
{
    PlatformWindow createWindow();
}


interface PlatformWindow
{
    @property string title() const;
    @property void title(string title);

    @property IRect geometry() const;
    @property void geometry(IRect pos);
}
