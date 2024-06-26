#!/bin/bash

###############################################################################
###############################################################################
# Copyright (c) 20232-2024 Paul Preney.
# Distributed under the terms of the GNU Public License version 3
#
# This script builds Gentoo Apptainer SIF images using Boostrap: scratch 
# by downloading a stage3 tarball as a starting point.
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

function run_bash_function_as_root()
{
  sudo bash -c "$(declare -f); $*"
}

function apptainer_definition()
{
  case "$RELEASE" in
    latest)
      cat <<ZZEOF
Bootstrap: localimage
From: $GENTOO_ROOTFS

%post
    # Run emerge-webrsync...
    source /etc/profile
    emerge-webrsync

    # Enable the first non-deprecated profile...
    #   * determine all deprecated profiles
    TMPFILE1=\`mktemp\`
    find /var/db/repos/gentoo/profiles/default \
        -mindepth 3 -type f -name 'deprecated' | \
        cut -d/ -f7- | sed 's|/deprecated$||' | sort -u >\$TMPFILE1

    #   * determine all profiles
    TMPFILE2=\`mktemp\`
        find /var/db/repos/gentoo/profiles/default \
        -mindepth 3 -type d | cut -d/ -f7- | sort -u >\$TMPFILE2

    #   * compute the set difference
    TMPFILE3=\`mktemp\`
        comm -13 \$TMPFILE1 \$TMPFILE2 >\$TMPFILE3

    #   * remove prefix, systemd, and no-multilib entries,
    #     sort by string length, strip out architecture, and
    #     output first entry
    TMPFILE4=\`mktemp\`
    cat \$TMPFILE3 | grep -v '/prefix' | grep -v '/systemd' | \
        grep -v '/no-multilib' | \
        awk '{ print length, \$0 }' | sort -n | cut -d' ' -f2- \
        | grep amd64 | head -n 1 >\$TMPFILE4

    PROFILE=\`cat \$TMPFILE4\`
    echo "Selecting profile: \$PROFILE"
    eselect profile set \$PROFILE
    unset PROFILE
    rm -f TMPFILE1 TMPFILE2 TMPFILE3 TMPFILE4

    # Either enable all locales or the C.UTF-8 locale...
    MAKEOPTS=-j
    cat /usr/share/i18n/SUPPORTED >/etc/locale.gen
    #echo "C.UTF-8 UTF-8" >/etc/locale.gen

    # and generate those locales...
    locale-gen

    # Set timezone to Etc/UTC...
    #echo "Etc/UTC" >/etc/timezone
    emerge --config sys-libs/timezone-data

    # Update the system environment...
    source /etc/profile
    env-update
ZZEOF
      ;;
  esac
}

function dload_latest_stage3()
{
  local ARCH="$1"
  local RELEASE="$2"
  local ROOTDIR="$3"
  local URL="$4"
  local FLAVOUR="${5:--openrc}"   # default to -openrc

  cd "$ROOTDIR"
  export STAGE3_FNAME=$RELEASE-stage3-$ARCH$FLAVOUR.txt

  # Determine the latest release stage3 tarball...
  curl -L "$URL/$STAGE3_FNAME" | grep stage3-$ARCH$FLAVOUR | awk '{ print $1 }' >"$ROOTDIR/stage3.txt"
  local TARBALL_URL="$GENTOO_BASE_URL/$(cat "$ROOTDIR/stage3.txt")"

  # Download the tarball...
  curl -L "$URL/$TARBALL_URL" -o ./stage3-tarball
}

function extract_stage3_tarball()
{
  local ROOTDIR="$1"
  local GENTOO_ROOTFS="$2"
  echo "Extracting stage3 tarball..."
  tar -C "$GENTOO_ROOTFS" -xpf "$ROOTDIR"/stage3-tarball --xattrs-include='*.*' --numeric-owner
}

function build_gentoo_sif()
{
  export ARCH="$1"
  export RELEASE="$2"
  SIFFILE="$3"

  export ROOTDIR=$(sudo mktemp -d)
  DEFFILE=$(mktemp)
  export GENTOO_ROOTFS=$ROOTDIR/rootfs

  apptainer_definition | cat >"$DEFFILE"

  function cleanup()
  {
    rm -f $DEFFILE
    run_as_root rm -rf $ROOTDIR
  }

  trap cleanup SIGINT EXIT

  case "$RELEASE" in
    latest)
      URL=https://distfiles.gentoo.org/releases/$ARCH/autobuilds
      ;;
    *)
      echo "Unknown release $RELEASE. Aborting."
      exit 127
      ;;
  esac

  run_bash_function_as_root dload_latest_stage3 "$ARCH" "$RELEASE" "$ROOTDIR" "$URL"
  run_as_root mkdir "${GENTOO_ROOTFS}"
  run_bash_function_as_root extract_stage3_tarball "$ROOTDIR" "$GENTOO_ROOTFS"
  run_as_root apptainer build "${SIFFILE}" "$DEFFILE"

  trap - SIGINT ERR EXIT
  cleanup
}

###############################################################################
###############################################################################

#for arch in \
#  x86 amd64 alpha arm arm64 hppa ia64 loong mips m68k ppc riscv s390 sparc ; \

for arch in amd64 ; \
do
  build_gentoo_sif $arch latest linux-gentoo-latest-$arch-${TIMESTAMP}.sif
done

###############################################################################
###############################################################################
