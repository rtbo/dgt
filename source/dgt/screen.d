module dgt.screen;

interface Screen
{
    @property int num() const;
    @property int width() const;
    @property int height() const;
    @property double dpi() const;
}
