# Container Utilities

__NOTE:__ This respository and its contents are currently under construction,
thus, there are no releases yet of its tools, etc.

This repository contains various container utilities, e.g., scripts, to
assist with various container technologies.

A particular aim of this repository is to provide a way to build base
(Linux) images that are not dependent on third-party repositories. For
example, when creating Apptainer images often individuals use Docker's
repositories to generate those, e.g., Debian/Ubuntu, images which should
instead pull the binaries, etc. needed from the site where such was
originally released from. For Debian and Ubuntu, using the `debootstrap`
program allows this to be done elegantly.

A significant reason for using containers is to enable running old programs in
old environments. It may or may not be easy to obtain an image for old
Linux environments and this repository aims to have scripts, etc. capable
of producing such images as far back as is possible/reasonable.


# Apptainer

The Apptainer image build scripts build minimal, or close to minimal,
images. Typically one will need to generate a sandbox image to add more
software, etc. Such could be done by running:

```
# 1. Extract the SIF file contents in to a directory...
sudo apptainer build -s image-work.dir filename.sif

# 2. Update the directory image...
sudo apptainer shell -C -w image-work.dir/ filename.sif

# 3. When done build a new SIF image...
sudo apptainer build new-filename.sif image-work.dir/
```

## Debian Linux

__SCRIPT:__ `bin/apptainer-build-linux-debian-image.sh`

This script builds Debian Linux Apptainer SIF image files using
`debootstrap`, `sudo`, and `apptainer` pulling the source binary files from
Debian's repositories --not Docker repositories. Old end-of-life releases as
well as new releases can be easily built.

__NOTE:__ Root permissions are required to execute this script. See the bottom
of the script for commands and uncomment the desired commands to build an
image.

## Ubuntu Linux

__SCRIPT:__ `bin/apptainer-build-linux-ubuntu-image.sh`

This script builds Ubuntu Linux Apptainer SIF image files using
`debootstrap`, `sudo`, and `apptainer` pulling the source binary files from
Ubuntu's repositories --not Docker repositories. Old end-of-life releases as
well as new releases can be easily built.

__NOTE:__ Root permissions are required to execute this script. See the bottom
of the script for commands and uncomment the desired commands to build an
image.
