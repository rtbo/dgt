module dgt.bindings.turbojpeg.symbols;

import dgt.bindings.turbojpeg.definitions;

import core.stdc.config : c_ulong;

extern (C) nothrow @nogc
{
    alias da_tjInitCompress = tjhandle function();

    alias da_tjCompress2 = int function(tjhandle handle, ubyte* srcBuf, int width, int pitch,
            int height, int pixelFormat, ubyte** jpegBuf, c_ulong* jpegSize,
            int jpegSubsamp, int jpegQual, int flags);

    alias da_tjBufSize = c_ulong function(int width, int height, int jpegSubsamp);

    alias da_tjBufSizeYUV = c_ulong function(int width, int height, int subsamp);

    alias da_tjEncodeYUV2 = int function(tjhandle handle, ubyte* srcBuf, int width,
            int pitch, int height, int pixelFormat, ubyte* dstBuf, int subsamp, int flags);

    alias da_tjInitDecompress = tjhandle function();

    alias da_tjDecompressHeader2 = int function(tjhandle handle, ubyte* jpegBuf,
            c_ulong jpegSize, int* width, int* height, int* jpegSubsamp);

    alias da_tjGetScalingFactors = tjscalingfactor* function(int* numscalingfactors);

    alias da_tjDecompress2 = int function(tjhandle handle, ubyte* jpegBuf, c_ulong jpegSize,
            ubyte* dstBuf, int width, int pitch, int height, int pixelFormat, int flags);

    alias da_tjDecompressToYUV = int function(tjhandle handle, ubyte* jpegBuf,
            c_ulong jpegSize, ubyte* dstBuf, int flags);

    alias da_tjInitTransform = tjhandle function();

    alias da_tjTransform = int function(tjhandle handle, ubyte* jpegBuf, c_ulong jpegSize,
            int n, ubyte** dstBufs, c_ulong* dstSizes, tjtransform* transforms, int flags);

    alias da_tjDestroy = int function(tjhandle handle);

    alias da_tjAlloc = ubyte* function(int bytes);

    alias da_tjFree = void function(ubyte* buffer);

    alias da_tjGetErrorStr = char* function();

    alias da_TJBUFSIZE = c_ulong function (int width, int height);

    alias da_TJBUFSIZEYUV = c_ulong function (int width, int height, int jpegSubsamp);

    alias da_tjCompress = int function(tjhandle handle, ubyte* srcBuf, int width, int pitch, int height,
            int pixelSize, ubyte* dstBuf, c_ulong* compressedSize,
            int jpegSubsamp, int jpegQual, int flags);

    alias da_tjEncodeYUV = int function(tjhandle handle, ubyte* srcBuf, int width,
            int pitch, int height, int pixelSize, ubyte* dstBuf, int subsamp, int flags);

    alias da_tjDecompressHeader = int function(tjhandle handle, ubyte* jpegBuf,
            c_ulong jpegSize, int* width, int* height);

    alias da_tjDecompress = int function(tjhandle handle, ubyte* jpegBuf, c_ulong jpegSize,
            ubyte* dstBuf, int width, int pitch, int height, int pixelSize, int flags);
}

__gshared
{

    da_tjInitCompress tjInitCompress;

    da_tjCompress2 tjCompress2;

    da_tjBufSize tjBufSize;

    da_tjBufSizeYUV tjBufSizeYUV;

    da_tjEncodeYUV2 tjEncodeYUV2;

    da_tjInitDecompress tjInitDecompress;

    da_tjDecompressHeader2 tjDecompressHeader2;

    da_tjGetScalingFactors tjGetScalingFactors;

    da_tjDecompress2 tjDecompress2;

    da_tjDecompressToYUV tjDecompressToYUV;

    da_tjInitTransform tjInitTransform;

    da_tjTransform tjTransform;

    da_tjDestroy tjDestroy;

    da_tjAlloc tjAlloc;

    da_tjFree tjFree;

    da_tjGetErrorStr tjGetErrorStr;

    da_TJBUFSIZE TJBUFSIZE;

    da_TJBUFSIZEYUV TJBUFSIZEYUV;

    da_tjCompress tjCompress;

    da_tjEncodeYUV tjEncodeYUV;

    da_tjDecompressHeader tjDecompressHeader;

    da_tjDecompress tjDecompress;
}
