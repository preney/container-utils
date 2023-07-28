#!/bin/bash

###############################################################################
###############################################################################
# Copyright (c) 2023 Paul Preney.
# Distributed under the terms of the GNU Public License version 3
#
# NOTE: See bottom of this script for commands to build images.
#
# This script builds Ubuntu Apptainer SIF images using debootstrap. Before
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
    breezy|dapper)
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

    edgy|feisty|gutsy|hardy|intrepid|jaunty|karmic|lucid|maverick)
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
apt-get -y autoremove
apt-get -y clean
ZZEOF
      ;;

    natty|oneiric|precise|saucy|raring|quantal|trusty|utopic|vivid|wily|xenial|yakkety|zesty|artful|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic)
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

function build_ubuntu_sif()
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
    breezy|dapper|edgy|feisty|gutsy|hardy|intrepid|jaunty|karmic|lucid|maverick|natty|oneiric|precise|saucy|raring|quantal|utopic|vivid|wily|yakkety|zesty|artful|cosmic|disco|eoan|groovy|hirsute|impish)
      URL=http://old-releases.ubuntu.com/ubuntu/
      EOL=eol
      ;;
    trusty|xenial|bionic|focal|jammy|kinetic|lunar|mantic)
      URL=http://us.archive.ubuntu.com/ubuntu/
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
# Ubuntu Releases URL: https://wiki.ubuntu.com/Releases
#
###############################################################################
###############################################################################

#
# NOTE: To use these images one is strongly recommended to use Apptainer's
#       -C, -c, or -e options.
#

#build_ubuntu_sif amd64 breezy linux-ubuntu-5.10-breezy-amd64-eol.sif

#build_ubuntu_sif amd64 dapper linux-ubuntu-6.04lts-dapper-amd64-eol.sif
#build_ubuntu_sif amd64 edgy linux-ubuntu-6.10-edgy-amd64-eol.sif
#build_ubuntu_sif amd64 feisty linux-ubuntu-7.04-fiesty-amd64-eol.sif
#build_ubuntu_sif amd64 gutsy linux-ubuntu-7.10-gutsy-amd64-eol.sif

#build_ubuntu_sif amd64 hardy linux-ubuntu-8.04lts-hardy-amd64-eol.sif
#build_ubuntu_sif amd64 intrepid linux-ubuntu-8.10-intrepid-amd64-eol.sif
#build_ubuntu_sif amd64 jaunty linux-ubuntu-9.04-jaunty-amd64-eol.sif
#build_ubuntu_sif amd64 karmic linux-ubuntu-9.10-karmic-amd64-eol.sif

#build_ubuntu_sif amd64 lucid linux-ubuntu-10.04lts-lucid-amd64-eol.sif
#build_ubuntu_sif amd64 maverick linux-ubuntu-10.10-maverick-amd64-eol.sif
#build_ubuntu_sif amd64 natty linux-ubuntu-11.04-natty-amd64-eol.sif
#build_ubuntu_sif amd64 oneiric linux-ubuntu-11.10-oneiric-amd64-eol.sif

#build_ubuntu_sif amd64 precise linux-ubuntu-12.04lts-precise-amd64-eol.sif
#build_ubuntu_sif amd64 quantal linux-ubuntu-12.10-quantal-amd64-eol.sif
#build_ubuntu_sif amd64 raring linux-ubuntu-13.04-raring-amd64-eol.sif
#build_ubuntu_sif amd64 saucy linux-ubuntu-13.10-saucy-amd64-eol.sif

#build_ubuntu_sif amd64 trusty linux-ubuntu-14.04lts-trusty-amd64-${TIMESTAMP}.sif
#build_ubuntu_sif amd64 utopic linux-ubuntu-14.10-utopic-amd64-eol.sif
#build_ubuntu_sif amd64 vivid linux-ubuntu-15.04-vivid-amd64-eol.sif
#build_ubuntu_sif amd64 wily linux-ubuntu-15.10-wily-amd64-eol.sif

#build_ubuntu_sif amd64 xenial linux-ubuntu-16.04lts-xenial-amd64-${TIMESTAMP}.sif
#build_ubuntu_sif amd64 yakkety linux-ubuntu-16.10-yakkety-amd64-eol.sif
#build_ubuntu_sif amd64 zesty linux-ubuntu-17.04-zesty-amd64-eol.sif
#build_ubuntu_sif amd64 artful linux-ubuntu-17.10-artful-amd64-eol.sif

#build_ubuntu_sif amd64 bionic linux-ubuntu-18.04lts-bionic-amd64-${TIMESTAMP}.sif
#build_ubuntu_sif amd64 cosmic linux-ubuntu-18.10-cosmic-amd64-eol.sif
#build_ubuntu_sif amd64 disco linux-ubuntu-19.04-disco-amd64-eol.sif
#build_ubuntu_sif amd64 eoan linux-ubuntu-19.10-eoan-amd64-eol.sif

#build_ubuntu_sif amd64 focal linux-ubuntu-20.04lts-focal-amd64-${TIMESTAMP}.sif
#build_ubuntu_sif amd64 groovy linux-ubuntu-20.10-groovy-amd64-eol.sif
#build_ubuntu_sif amd64 hirsute linux-ubuntu-21.04-hirsute-amd64-eol.sif
#build_ubuntu_sif amd64 impish linux-ubuntu-21.10-impish-amd64-eol.sif

#build_ubuntu_sif amd64 jammy linux-ubuntu-22.04lts-jammy-amd64-${TIMESTAMP}.sif
#build_ubuntu_sif amd64 kinetic linux-ubuntu-22.10-kinetic-amd64-${TIMESTAMP}.sif

# Don't yet work with debootstrap v1.0.128...
#build_ubuntu_sif amd64 lunar linux-ubuntu-23.04-lunar-amd64-${TIMESTAMP}.sif
#build_ubuntu_sif amd64 mantic linux-ubuntu-23.10-mantic-amd64-${TIMESTAMP}.sif

###############################################################################
###############################################################################
