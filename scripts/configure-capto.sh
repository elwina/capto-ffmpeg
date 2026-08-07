#!/usr/bin/env bash
# Print Capto whitelist configure args (sourced or executed for inspection).
# shellcheck disable=SC2034

configure_capto_args() {
  # $1=prefix $2=unused-target $3=cc-wrapper $4=cxx-wrapper $5=ar-wrapper $6=ranlib-wrapper
  local prefix="$1"
  local cc="$3"
  local cxx="$4"
  local ar="$5"
  local ranlib="$6"

  cat <<EOF
--prefix=${prefix}
--target-os=mingw32
--arch=x86_64
--cross-prefix=
--cc=${cc}
--cxx=${cxx}
--ar=${ar}
--ranlib=${ranlib}
--pkg-config=pkg-config
--pkg-config-flags=--static
--extra-cflags=-I${prefix}/include
--extra-ldflags=-L${prefix}/lib
--extra-ldexeflags=-static
--enable-static
--disable-shared
--disable-autodetect
--enable-gpl
--enable-libx264
--enable-ffnvcodec
--enable-nvenc
--enable-amf
--disable-doc
--disable-htmlpages
--disable-manpages
--disable-podpages
--disable-txtpages
--disable-ffplay
--disable-ffprobe
--enable-protocol=file
--enable-protocol=pipe
--enable-protocol=tcp
--disable-everything
--enable-indev=dshow
--enable-demuxer=rawvideo
--enable-demuxer=f32le
--enable-demuxer=mov
--enable-muxer=mp4
--enable-muxer=gif
--enable-muxer=ipod
--enable-encoder=libx264
--enable-encoder=h264_nvenc
--enable-encoder=h264_amf
--enable-encoder=gif
--enable-encoder=aac
--enable-decoder=rawvideo
--enable-decoder=pcm_f32le
--enable-parser=h264
--enable-parser=aac
--enable-bsf=h264_mp4toannexb
--enable-bsf=aac_adtstoasc
--enable-filter=scale
--enable-filter=null
--enable-filter=overlay
--enable-filter=hflip
--enable-filter=fps
--enable-filter=split
--enable-filter=palettegen
--enable-filter=paletteuse
--enable-filter=volume
--enable-filter=amix
--enable-filter=aformat
--enable-filter=aresample
--enable-swscale
--enable-swresample
--enable-avdevice
--enable-avfilter
--enable-avformat
--enable-avcodec
--enable-avutil
EOF
}

# Note: f32le is typically a demuxer named "f32le" under lavf — enable via:
# --enable-demuxer=f32le if available in this FFmpeg version.
# QSV omitted from first cut to protect single-exe DLL audit (see CAPABILITIES).
