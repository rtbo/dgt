/// Screen module
module dgt.screen;

import dgt.core.geometry : IRect;

interface Screen
{
    @property int num() const;
    @property IRect rect() const;
    @property double dpi() const;
    final @property int width() const
    {
        return rect.width;
    }
    final @property int height() const
    {
        return rect.height;
    }
}
