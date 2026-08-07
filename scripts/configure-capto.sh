#!/usr/bin/env bash
# Print Capto whitelist configure args (sourced or executed for inspection).
# IMPORTANT: --disable-everything MUST come before any --enable-protocol/demuxer/…
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
--disable-doc
--disable-htmlpages
--disable-manpages
--disable-podpages
--disable-txtpages
--disable-ffplay
--disable-ffprobe
--disable-everything
--enable-gpl
--enable-libx264
--enable-ffnvcodec
--enable-nvenc
--enable-amf
--enable-network
--enable-protocol=file
--enable-protocol=pipe
--enable-protocol=tcp
--enable-indev=dshow
--enable-demuxer=rawvideo
--enable-demuxer=pcm_f32le
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

# QSV omitted from first cut to protect single-exe DLL audit (see CAPABILITIES).
