#!/bin/bash

# Sync multiple source directory contents into one destination using hardlinks.
# During each subsequent run, the destination directory
# will be created anew and then replace the original.

script_name=$(basename $0)

function usage {
    echo "
${script_name} [-h] [-v] [-n] [-t <base-temp-directory>] SRC... DEST

OPTIONS:
  -h  Print this usage message
  -v  Enable verbose logging of shell commands that are run
  -n  perform a dry run with no changes made
  -t  The base directory to create temp directories in.  Default: /tmp

DESCRIPTION:
  Syncs multiple source directories into a final destination directory
  using hard links. The final destination directory will be
  re-created from the source directories each run of this command.
  The original destination directory will be moved away and the newly
  created and hard synced destination directory will be moved to its place.
  The original will then be deleted.  Since all of this uses hard links
  (via cp -al), the extra 'copies' of these directories will not take
  up (much) additional filesystem space.

  ${script_name} is useful if you want to present the contents of multiple
  directories as one, but still want to allow people to delete contents out
  of the source directories.  If it weren't for the delete problem, rsync
  would be sufficient to solve this problem.

EXAMPLE:
  ${script_name} /my/dir1 /my/dir2 /my/dest

  This will copy the contents of /my/dir1/* and /my/dir2/* into
  /my/dest/ as hardlinks.  WARNING: /my/dest as is before
  this command runs will be deleted.  A new /my/dest will be moved
  into its place containing a fresh hardlink sync from the
  source directories.
"

exit 0
}


# Exit if any error is encountered
set -e

# Echos $@ to stdout prepended by a timestamp
function log {
    echo $(date +"%Y-%m-%dT%H:%M:%S") "$@"
}

# Logs $@ to stdout prepended by ERROR, and then exit 1.
function fatal {
    log ERROR: $@
    exit 1
}

# Run $@ as a shell command.
# If $verbose, log it first.
# If $dry_run, don't actually run it.
function cmd {
    if [ $verbose -eq 1 ]; then
        log $@
    fi
    if [ $dry_run -eq 0 ]; then
        $@
    fi
}


verbose=0
dry_run=0
base_temp_dir=/tmp

while getopts "hvnt:" opt; do
    case "$opt" in
    h)
        usage
        ;;
    v)  verbose=1
        ;;
    n)  dry_run=1
        ;;
    t)
        base_temp_dir=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

# All but the last argument should be treated as source directories
argc=$(($#-1))
source_dirs=${@:1:$argc}

# The last argument is the destination directory
dest_dir="${!#}"

# Check that we have $source_dirs and a $dest_dir.
if [ -z "${source_dirs}" -o -z "${dest_dir}" ]; then
    fatal "Must specify at least one source directory and exactly one destination directory. Aborting."
fi

# Check that all $source_dirs exist and are directories.
for source_dir in $source_dirs; do
    test -d $source_dir || fatal "Source directory '${source_dir}' is not a directory. Aborting."
done


# Begin hard syncing

log "Hard syncing $source_dirs into $dest_dir..."

if [ $dry_run -eq 1 ]; then
    mktemp_dry_run='u'
fi
# Make a temporary new destination directory in which to hardsync the sources.
temp_dest=$(mktemp -d$mktemp_dry_run $base_temp_dir/.hardsync.$(basename $dest_dir).XXXXXXXXXXXX)

# Later, before we mv $temp_dest to $dest_dir, the old $dest_dir will be moved to $temp_dest_trash.
# After $temp_dest has moved to $dest_dir, we can delete $temp_dest_trash
temp_dest_trash=$(mktemp -d$mktemp_dry_run $base_temp_dir/.hardsync.$(basename $dest_dir).trash.XXXXXXXXXXXX)

# cp -al each source dir into temp dest
for source_dir in $source_dirs; do
    cmd cp -al $source_dir/* $temp_dest/
done

#  Remove any existent $dest_dir and mv $temp_dest to $dest_dir
test -e $dest_dir && cmd mv -f $dest_dir $temp_dest_trash
cmd mv -f $temp_dest $dest_dir
cmd rm -rf $temp_dest_trash

log "Finished hard syncing $source_dirs into $dest_dir"
