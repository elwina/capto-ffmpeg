#!/usr/bin/env bash
# Capto whitelist. --disable-everything MUST come before any --enable-protocol/…
# GPU vendors: headers / VPL dispatcher only — vendor runtimes LoadLibrary at encode time.
# HEVC: hardware encoders only (no libx265).
# shellcheck disable=SC2034

configure_capto_args() {
  local prefix="$1"
  local target="$2"
  local cc="$3"
  local cxx="$4"
  local ar="$5"
  local ranlib="$6"
  local arch="$7"
  local enable_libvpl="${8:-0}"

  local qsv_flags=""
  if [[ "${enable_libvpl}" == "1" ]]; then
    qsv_flags=$(cat <<'QSV'
--enable-libvpl
--enable-encoder=h264_qsv
--enable-encoder=hevc_qsv
QSV
)
  fi

  cat <<EOF
--prefix=${prefix}
--target-os=mingw32
--arch=${arch}
--cross-prefix=
--cc=${cc}
--cxx=${cxx}
--ar=${ar}
--ranlib=${ranlib}
--pkg-config=pkg-config
--pkg-config-flags=--static
--extra-version=capto
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
${qsv_flags}
--enable-network
--enable-protocol=file
--enable-protocol=pipe
--enable-protocol=tcp
--enable-demuxer=rawvideo
--enable-demuxer=pcm_f32le
--enable-demuxer=mov
--enable-muxer=mp4
--enable-muxer=gif
--enable-muxer=ipod
--enable-encoder=libx264
--enable-encoder=h264_nvenc
--enable-encoder=h264_amf
--enable-encoder=hevc_nvenc
--enable-encoder=hevc_amf
--enable-encoder=gif
--enable-encoder=aac
--enable-decoder=rawvideo
--enable-decoder=pcm_f32le
--enable-parser=h264
--enable-parser=hevc
--enable-parser=aac
--enable-bsf=h264_mp4toannexb
--enable-bsf=hevc_mp4toannexb
--enable-bsf=aac_adtstoasc
--enable-filter=scale
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
--enable-avfilter
--enable-avformat
--enable-avcodec
--enable-avutil
EOF
}

# No dshow/avdevice/overlay/hflip: Capto composites webcam in-process.
# No libx265: HEVC is GPU-only (nvenc/amf/qsv on x86_64).
