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
    echo "ban_list=['^.*@.*]" | config_list -i /dev/stdin $list
    if find /var/lib/mailman/data/ | grep heldmsg-$list; then
        rm /var/lib/mailman/data/heldmsg-$list-*.pck
    fi
}

function enable_list {
    echo "advertised=1" | config_list -i /dev/stdin $list
    echo "emergency=0"  | config_list -i /dev/stdin $list
    echo "member_moderation_action=0" | config_list -i /dev/stdin $list
    echo "generic_nonmember_action=1" | config_list -i /dev/stdin $list
    echo "ban_list=[]" | config_list -i /dev/stdin $list
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
            if find /var/lib/mailman/lists -maxdepth 1 | grep -q $1; then
                list=$1
                shift
            else
                echo "$1 is not a valid list name. Please verify the name with lists_list -b."
                exit 0
            fi
            ;;

    esac
done

test -z $list && usage

if [ $ENABLE -eq 1 ]; then
    enable_list
    echo "$list enabled. Please verify archives are intact and the list administrative page works."
else
    disable_list
    echo "$list disabled. Archives should be available at current location, all mail should be moderated and the list should not be on the listinfo page."
fi
