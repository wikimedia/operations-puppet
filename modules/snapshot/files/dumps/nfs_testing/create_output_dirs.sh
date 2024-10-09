#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# after the nfs share for testing is manually mounted, run this script
# to create the various output directories in the tree for dumps,
# if they do not already exist from e.g. a previous testing session.

# shellcheck disable=SC1090

# get some directory names, and so on from here
source "$HOME/nfs_testing/test_outputdir_paths.sh"

if ! [[ "$mountpoint" =~ /mnt/[a-zA-Z_]+ ]]; then
    echo "The setting in $HOME/nfs_testing/test_outputdir_paths.sh does not look like a mount point, giving up."
    exit 1
fi

if [ "$EUID" -eq 0 ]; then
    echo "You should not run this as root but as the dumps user."
    exit 1
fi

# check if the setting is an nfs mount; if not, we'll whine and exit.
mountinfo=$( /usr/bin/mount | /usr/bin/grep "$mountpoint" | /usr/bin/awk '{ print $1 }' )
if [[ "$mountinfo" =~ ^[a-zA-Z0-9.]+:[a-zA-Z_/]+ ]]; then
  remote=$( echo -n "$mountinfo" | /usr/bin/awk -F: '{ print $1 }' )
  if [[ "$remote" =~ ^[a-zA-Z.]+wmnet ]]; then
     mounted="OK"
  fi
fi

if [ "$mounted" != "OK" ]; then
    echo "Make sure that the nfs share you want to test is mounted at $mountpoint"
    echo "and then run this script again."
    exit 1
fi

mkdir -p "$xmldumpsdir"
mkdir -p "$otherdumpsdir"
for dirname in "$privatedir" "$publicdir" "$tempdir" ; do
  mkdir -p "$dirname"
done

# we choose a subset of the "other" dumps since many can't be tested quickly. most of them
# should not be impacted by changing to a new nfs share, even with a different distro
# version on the nfs server.
for dirname in  'categoriesrdf' 'incr' 'pagetitles' 'wikibase' ; do
  mkdir -p "$otherdumpsdir/$dirname"
done
