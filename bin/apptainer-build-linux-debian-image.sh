#!/bin/bash

###############################################################################
###############################################################################
# Copyright (c) 2023 Paul Preney.
# Distributed under the terms of the GNU Public License version 3
#
# NOTE: See bottom of this script for commands to build images.
#
# This script builds Debian Apptainer SIF images using debootstrap. Before
# using this script debootstrap, sudo, and apptainer must be installed and
# properly configured.
#
# debootstrap URL: https://packages.qa.debian.org/d/debootstrap.html
#   * Many Linux distributions have debootstrap available as a package.
#
# apptainer URL: https://www.apptainer.org
#
###############################################################################
###############################################################################

TIMESTAMP=$(date -u --iso-8601=seconds)

function run_as_root()
{
  sudo "$@"
}

function run_debootstrap()
{
  local eol="$1"

  local no_check_gpg=""
  case $eol in
    eol)
      local no_check_gpg="--no-check-gpg"
      ;;
  esac

  run_as_root mkdir -p "$ROOTDIR"
  run_as_root debootstrap $no_check_gpg \
    --arch="$ARCH" "$RELEASE" "$ROOTDIR" "$URL"
}

function apptainer_definition()
{
  case "$RELEASE" in
    potato)
      cat <<ZZEOF
Bootstrap: localimage
From: $ROOTDIR

%post
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
export LANGUAGE=C

apt-get update
apt-get -y upgrade

apt-get -y install --reinstall locales
dpkg-reconfigure -fnoninteractive locales

apt-get -y install nano vim

# Clean up...
apt-get -y clean
ZZEOF
      ;;

    woody|sarge)
      cat <<ZZEOF
Bootstrap: localimage
From: $ROOTDIR

%post
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
export LANGUAGE=C

apt-get update
apt-get -y upgrade

apt-get -y install --reinstall locales
dpkg-reconfigure -fnoninteractive locales

apt-get -y install apt-utils
apt-get -y install nano vim

# Clean up...
apt-get -y clean
ZZEOF
      ;;

    etch)
      cat <<ZZEOF
Bootstrap: localimage
From: $ROOTDIR

%post
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
export LANGUAGE=C

apt-get update
apt-get -y upgrade

apt-get -y install --reinstall locales
dpkg-reconfigure -fnoninteractive locales
update-locale --reset LANG="\$LANG" LC_ALL="\$LC_ALL" LANGUAGE="\$LANGUAGE"

apt-get -y install tzdata
dpkg-reconfigure -fnoninteractive tzdata

apt-get -y install apt-utils
apt-get -y install nano vim

# Clean up...
apt-get -y clean
ZZEOF
      ;;

    lenny|squeeze)
      cat <<ZZEOF
Bootstrap: localimage
From: $ROOTDIR

%post
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
export LANGUAGE=C

echo 'APT::Get::AllowUnauthenticated "true";' >>/etc/apt/apt.conf
apt-get update
apt-get -y upgrade

apt-get -y install --reinstall locales
dpkg-reconfigure -fnoninteractive locales
update-locale --reset LANG="\$LANG" LC_ALL="\$LC_ALL" LANGUAGE="\$LANGUAGE"

apt-get -y install tzdata
dpkg-reconfigure -fnoninteractive tzdata

apt-get -y install apt-utils
apt-get -y install nano vim

# Clean up...
apt-get -y autoremove
apt-get -y clean
ZZEOF
      ;;
    
    wheezy|jessie|stretch)
      cat <<ZZEOF
Bootstrap: localimage
From: $ROOTDIR

%post
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8

echo 'APT::Get::AllowUnauthenticated "true";' >>/etc/apt/apt.conf
apt-get update
apt-get -y upgrade

apt-get -y install --reinstall locales
dpkg-reconfigure -fnoninteractive locales
update-locale --reset LANG="\$LANG" LC_ALL="\$LC_ALL" LANGUAGE="\$LANGUAGE"

apt-get -y install tzdata
dpkg-reconfigure -fnoninteractive tzdata

apt-get -y install apt-utils
apt-get -y install nano vim

# Clean up...
apt-get -y autoremove
apt-get -y clean
ZZEOF
      ;;
    
    buster|bullseye|bookworm|stable|testing|unstable|sid|experimental)
      cat <<ZZEOF
Bootstrap: localimage
From: $ROOTDIR

%post
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8

apt-get update
apt-get -y upgrade

apt-get -y install --reinstall locales
dpkg-reconfigure -fnoninteractive locales
update-locale --reset LANG="\$LANG" LC_ALL="\$LC_ALL" LANGUAGE="\$LANGUAGE"

apt-get -y install tzdata
dpkg-reconfigure -fnoninteractive tzdata

apt-get -y install apt-utils
apt-get -y install nano vim

# Clean up...
apt-get -y autoremove
apt-get -y clean
ZZEOF
      ;;
    
    *)
      ;;
  esac
}

function build_debian_sif()
{
  ARCH="$1"
  RELEASE="$2"
  SIFFILE="$3"
  ROOTDIR=$(sudo mktemp -d)
  DEFFILE=$(mktemp)
  apptainer_definition | cat >"$DEFFILE"

  function cleanup()
  {
    rm -f $DEFFILE
    run_as_root rm -rf $ROOTDIR
  }

  trap cleanup SIGINT EXIT

  case "$RELEASE" in
    potato|woody|sarge|etch|lenny|squeeze|wheezy|jessie|stretch)
      URL=http://archive.debian.org/debian-archive/debian/
      EOL=eol
      ;;
    buster|bullseye|bookworm|stable|testing|unstable|sid|experimental)
      URL=http://deb.debian.org/debian
      EOL=not_eol
      ;;
    *)
      echo "Unknown release $RELEASE. Aborting."
      exit 127
      ;;
  esac

  run_debootstrap $EOL
  run_as_root apptainer build "${SIFFILE}" "$DEFFILE"

  trap - SIGINT ERR EXIT
  cleanup
}

###############################################################################
###############################################################################
#
# Debian Releases URL: https://wiki.debian.org/DebianReleases
# Debian LTS URL: https://wiki.debian.org/LTS
#
###############################################################################
###############################################################################

#
# Specific Debian releases...
#
# NOTE: Some Linux distributions may need an ncurses-compat library installed
#       so that v5 calls can work, e.g., with old i386 images.
#
# NOTE: To use these images one is strongly recommended to use Apptainer's
#       -C, -c, or -e options.
#

# i386...
#build_debian_sif i386 potato linux-debian-2.2-potato-i386-eol.sif
#build_debian_sif i386 woody linux-debian-3.0-woody-i386-eol.sif
#build_debian_sif i386 sarge linux-debian-3.1-sarge-i386-eol.sif

# amd64...
#build_debian_sif amd64 etch linux-debian-4-etch-amd64-eol.sif
#build_debian_sif amd64 lenny linux-debian-5-lenny-amd64-eol.sif
#build_debian_sif amd64 squeeze linux-debian-6-squeeze-amd64-eol.sif
#build_debian_sif amd64 wheezy linux-debian-7-wheezy-amd64-eol.sif
#build_debian_sif amd64 jessie linux-debian-8-jessie-amd64-eol.sif
#build_debian_sif amd64 stretch linux-debian-9-stretch-amd64-eol.sif
#build_debian_sif amd64 buster linux-debian-10-buster-amd64-${TIMESTAMP}.sif
#build_debian_sif amd64 bullseye linux-debian-11-bullseye-amd64-${TIMESTAMP}.sif
#build_debian_sif amd64 bookworm linux-debian-12-bookworm-amd64-${TIMESTAMP}.sif

#
# Generic Debian release names...
#
#build_debian_sif amd64 stable linux-debian-stable-amd64-${TIMESTAMP}.sif
#build_debian_sif amd64 testing linux-debian-testing-amd64-$TIMESTAMP}.sif
#build_debian_sif amd64 unstable linux-debian-unstable-amd64-${TIMESTAMP}.sif

###############################################################################
###############################################################################
