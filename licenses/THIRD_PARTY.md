# Third-party license notes

Pinned versions live in [`versions.env`](../versions.env). Full license texts
ship with each upstream project; this file is a redistribution map for Capto
Release packaging.

## FFmpeg

- Source: https://github.com/FFmpeg/FFmpeg  
- Tag: see `FFMPEG_TAG`  
- This build uses `--enable-gpl` and therefore the **GPL** terms apply to the
  combined work. Upstream also documents LGPL options for non-GPL builds.

## x264

- Source: https://code.videolan.org/videolan/x264  
- Ref: see `X264_REF`  
- License: GNU GPL v2 or later  
- Statically linked into `ffmpeg.exe`.

## nv-codec-headers (ffnvcodec)

- Source: https://github.com/FFmpeg/nv-codec-headers  
- Tag: see `FFNVCODEC_TAG`  
- License: MIT  
- Headers only; NVIDIA driver loaded at runtime.

## AMD AMF headers

- Source: https://github.com/GPUOpen-LibrariesAndSDKs/AMF  
- Tag: see `AMF_TAG`  
- License: MIT  
- Headers only; AMF runtime loaded at runtime.

## Intel libvpl (oneVPL dispatcher)

- Source: https://github.com/intel/libvpl  
- Tag: see `LIBVPL_TAG`  
- License: MIT  
- Open-source dispatcher statically linked; Intel GPU implementation DLLs
  loaded at runtime (not redistributed here).

## Build tooling (not in the Release binary)

Zig, NASM, CMake, Ninja, MSYS2 packages are build-host tools only.
