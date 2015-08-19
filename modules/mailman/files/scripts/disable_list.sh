#!/bin/bash
#
# Enables and Disables a Mailman mailing list simply thorugh configuration settings.
#
# John Lewis 2015

ENABLE=0

function disable_list {
    echo "advertised=0" | config_list -i /dev/stdin $list
    echo "emergency=1"  | config_list -i /dev/stdin $list
    echo "member_moderation_action=2" | config_list -i /dev/stdin $list
    echo "generic_nonmember_action=2" | config_list -i /dev/stdin $list
    rm /var/lib/mailman/data/heldmsg-$list-*.pck
}

function enable_list {
    echo "advertised=1" | config_list -i /dev/stdin $list
    echo "emergency=0"  | config_list -i /dev/stdin $list
    echo "member_moderation_action=0" | config_list -i /dev/stdin $list
    echo "generic_nonmember_action=1" | config_list -i /dev/stdin $list
}

function usage {
    echo "Usage: $0 [-e|--enable] <listname>"; exit 1;
}

while test "$#" -gt 0; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --enable|-e)
            ENABLE=1
            shift
            ;;
        *)
            list=$1
            shift
            ;;

    esac
done

if [ $ENABLE -eq 1 ]; then
    enable_list
    echo "$list enabled. Please verify archives are intact and the list administrative page works."
else
    disable_list
    echo "$list disabled. Archives should be available at current location, all mail should be moderated and the list should not be on the listinfo page."
fi
