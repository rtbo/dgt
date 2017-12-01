module dgt.bindings.turbojpeg.load;

import dgt.bindings.turbojpeg.symbols;
import dgt.bindings;

/// Load the turbojpeg library symbols.
/// Must be called before any use of tj* functions.
/// If no libNames is provided, a per-platform guess is performed.
public void loadTurboJpegSymbols(string[] libNames = [])
{
    version (linux)
    {
        auto defaultLibNames = ["libturbojpeg.so", "libturbojpeg.so.0"];
    }
    version (Windows)
    {
        auto defaultLibNames = ["turbojpeg.dll", "libturbojpeg.dll", "libturbojpeg-0.dll"];
    }
    if (libNames.length == 0)
    {
        libNames = defaultLibNames;
    }
    turboJpegLoader.load(libNames);
}

/// Check whether turbojpeg is loaded
public @property bool turboJpegLoaded()
{
    return turboJpegLoader.loaded;
}

shared static this()
{
    turboJpegLoader = new TurboJpegLoader();
}

private __gshared TurboJpegLoader turboJpegLoader;

private class TurboJpegLoader : SharedLibLoader
{
    override void bindSymbols()
    {
        bind!(tjInitCompress)();
        bind!(tjCompress2)();
        bind!(tjBufSize)();
        bind!(tjBufSizeYUV)();
        bind!(tjEncodeYUV2)();
        bind!(tjInitDecompress)();
        bind!(tjDecompressHeader2)();
        bind!(tjGetScalingFactors)();
        bind!(tjDecompress2)();
        bind!(tjDecompressToYUV)();
        bind!(tjInitTransform)();
        bind!(tjTransform)();
        bind!(tjDestroy)();
        bind!(tjAlloc)();
        bind!(tjFree)();
        bind!(tjGetErrorStr)();
        bind!(TJBUFSIZE)();
        bind!(TJBUFSIZEYUV)();
        bind!(tjCompress)();
        bind!(tjEncodeYUV)();
        bind!(tjDecompressHeader)();
        bind!(tjDecompress)();
    }
}