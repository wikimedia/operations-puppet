#!/bin/bash
#
# take an email address and remove it from all private lists
#
# dzahn@wikimedia.org - 20150507
#
#    subscribe_policy (spolicy) can be:
#
#    1 = "Confirm"
#    2 = "Require approval"
#    3 = "Confirm and approve"
#
#    archive_private (apolicy) can be:
#
#    0 = "public"
#    1 = "private"
#

mm_base="/usr/lib/mailman/bin/"
user=$1
declare -a privatelists

if [ -z "$user" ]
    then echo "usage: $0 <email address>"
    exit 0
fi

echo "looking for lists $user is subscribed to .."
user_lists=$(${mm_base}find_member $user | grep -v 'found in')

echo -e "found on:\n $user_lists"

echo -e "analyzing if lists are public or private..\n"

for list in $user_lists
do
    echo -n "$list: "

    spolicy=$(${mm_base}config_list -o - $list | grep -E "^subscribe_policy" | cut -d " " -f3)
    apolicy=$(${mm_base}config_list -o - $list | grep -E "archive_private" | cut -d " " -f3)

    # echo $spolicy
    # echo $apolicy

    case $spolicy in
    1)
        echo -n "sub: confirm "
        ;;
    2)
        echo -n "sub: approve "
        ;;
    3)
        echo -n "sub: confapprove "
        ;;
    *)
        echo -n "sub: ERROR "
        ;;
    esac

    case $apolicy in
    0)
        echo -n "arc: public"
        ;;
    1)
        echo -n "arc: private"
        ;;
    *)
        echo -n "arc: ERROR"
        ;;
    esac

    if [ $spolicy == "3" ] && [ $apolicy == "1" ]
        then
        echo -n " DEFINITELY PRIVATE"
        privatelists+=( "$list" )
    elif [ $spolicy == "2" ] && [ $apolicy == "1" ]
        then
        echo -n " LOOKS PRIVATE"
        privatelists+=( "$list" )
    elif [ $spolicy == "1" ] && [ $apolicy == "0" ]
        then
        echo -n " DEFINITELY PUBLIC"
    else
        echo -n " DEFINITELY WEIRD"
    fi

    echo

done

echo -e "\nprivate lists: ${privatelists[@]}\n"
echo "do you want me to remove $user from all the above? (yes/no)"
read yesorno

case $yesorno in

 "yes")
    echo "ok removing .."
    ;;
 "no")
    echo "doing nothing. bye."
    exit 0
    ;;
  *)
    echo "please type 'yes' or 'no'"
    exit 1
    ;;
esac

echo $user > /tmp/remove-mailman-user

for privlist in ${privatelists[@]}
do
    # echo $privlist
    echo "${mm_base}remove_members -f /tmp/remove-mailman-user $privlist"
    ${mm_base}remove_members -f /tmp/remove-mailman-user $privlist
done

rm /tmp/remove-mailman-user
echo "done. bye"

