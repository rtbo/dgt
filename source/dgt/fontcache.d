module dgt.fontcache;

enum FontLocation
{
    system,
    user,
    application
}

struct FontFile
{
    FontLocation location;
    string path;
}

class FontCache
{
    private FontFile[] fontFiles_;

    private string[] appFolders_;

    private this()
    {}

    static @property FontCache instance()
    {
        static FontCache inst;
        if (inst is null)
        {
            inst = new FontCache();
        }
        return inst;
    }

    @property const(FontFile[]) fontFiles() const
    {
        return fontFiles_;
    }

    @property const(string[]) appFolders() const
    {
        return appFolders_;
    }
    @property void appFolders(string[] folders)
    {
        appFolders_ = folders;
    }

    void discover()
    {
        fontFiles_ = [];

        foreach (f; appFolders)
        {
            fontFiles_ ~= discoverFolder(f, FontLocation.application);
        }
        foreach (f; userFolders)
        {
            fontFiles_ ~= discoverFolder(f, FontLocation.user);
        }
        foreach (f; systemFolders)
        {
            fontFiles_ ~= discoverFolder(f, FontLocation.system);
        }
    }

    private FontFile[] discoverFolder(string path, FontLocation location)
    {
        import std.file;
        FontFile[] res;
        if (exists(path) && isDir(path))
        {
            foreach (DirEntry de; dirEntries(path, SpanMode.depth))
            {
                if (de.isFile)
                {
                    res ~= FontFile(location, de.name);
                }
            }
        }
        return res;
    }
}


private:

version(linux)
{
    @property string[] userFolders()
    {
        return [
            "~/.fonts",
        ];
    }
    @property string[] systemFolders()
    {
        return [
            "/usr/local/share/fonts",
            "/usr/share/fonts",
        ];
    }
}