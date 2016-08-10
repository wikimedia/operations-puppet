#!/bin/bash

set -e

case "$1" in
        check)

            if /bin/grep -qs $2 /proc/mounts; then
                echo "It's mounted."
            else
                echo "It's not mounted."
                exit 1
            fi

            if /usr/bin/timeout -k 10s 20s ls $2 &> /dev/null; then
                echo "It seems healthy."
            else
                echo "It does not seem healthy."
                exit 1
            fi
            ;;
        mount)

            # mount understands to look in /etc/fstab
            /usr/bin/timeout -k 10s 20s /bin/mount -v --target $2

            ;;
        umount)

            # -f = force an unmount (in case of an unreachable NFS system).  \
            # (Requires kernel 2.1.116 or later.)
            #
            # -l = Lazy  unmount.  Detach the filesystem from the file hierarchy now, \
            # and clean up all references to this \
            #  filesystem as soon as it is not busy anymore.
            /usr/bin/timeout -k 10s 20s /bin/umount -fl $2

            # While a mount path is not associated we don't
            # want files being dumped their on local disk
            /bin/chmod 600 $2
            ;;
esac
