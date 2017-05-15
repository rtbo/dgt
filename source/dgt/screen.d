/// Screen module
module dgt.screen;

import dgt.geometry : IRect;

interface Screen
{
    @property int num() const;
    @property IRect rect() const;
    @property double dpi() const;
}
