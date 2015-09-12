#!/bin/bash
# create a mailman list report
# by dzahn as requested in RT #6055
# version 2 201504 per a new request without ticket

mmbinpath="/var/lib/mailman/bin"
mmarcpath="/var/lib/mailman/archives/private"
logpath="/home/dzahn"
date=$(date)

echo -e "\nmailman list report - ${date}\n"

count_has_archives=0
count_has_no_archives=0

lists=$(${mmbinpath}/list_lists -b)
# simple overview of list settings for a few specific ones or all
#lists=( ops wikitech-l )
#for list in $lists; do
#	 echo -e "list: $list\n"
#	 list_info=$(${mmbinpath}/config_list -o - $list | grep -E '^real_name|^description|^owner|^moderator|^advertised|^archive_private|^subscribe_policy')
#	 echo -e "$list_info\n\n"
#done


# num_lists=$($mmbinpath/list_lists -b | wc -l)
# echo "number of lists: $num_lists"


#function isprivate {
#    is_private=
#    echo "$1 may be private"
#}

#isprivate ops


#####
for list in $lists; do

	has_archive=$(${mmbinpath}/config_list -o - $list | grep 'archive =' | cut -d= -f2 | tr -d '[[:space:]]')
	# echo -e "$list has archive: '$has_archive'\n\n"

    num_subscribers_all=$(${mmbinpath}/list_members $list | wc -l)
    count_all_subscribers=$((count_all_subscribers + $num_subscribers_all))

    if [ $has_archive == "True" ] || [ $has_archive == "1" ]
    then
        count_has_archive=$((count_has_archive + 1))
        #echo -e "it has archives. $count_has_archive\n"

        archive_private=$(${mmbinpath}/config_list -o - $list | grep 'archive_private' | cut -d= -f2 | tr -d '[[:space:]]')
	    # echo -e "$list has archive: '$has_archive'\n\n"

        if [ $archive_private == "True" ] || [ $archive_private == "1" ]
        then
            count_archive_private=$((count_archive_private + 1))
            #echo -e "archives are private. $count_archive_private\n"

            num_subscribers_priv=$(${mmbinpath}/list_members $list | wc -l)
            # echo -e "num subscribers: $num_subscribers_priv"
            count_priv_subscribers=$((count_priv_subscribers + $num_subscribers_priv))
            # echo "found a private list with archives and $num_subscribers_priv subscribers on it. it's $list"
            echo "$num_subscribers_priv $list" | tee -a ${logpath}/lists_with_priv_archives_by_subscribers.log
            num_messages_priv=$(grep Message-ID ${mmarcpath}/${list}.mbox/${list}.mbox | wc -l)
            echo "$num_messages_priv $list" | tee -a ${logpath}/lists_with_priv_archives_by_messages.log
            echo "$list subscribers: $num_subscribers_priv messages: $num_messages_priv"
        else
            count_archive_public=$((count_archive_public + 1))
            #echo -e "archives are public. $count_archive_public\n"
        fi

    else
        count_has_no_archive=$((count_has_no_archive + 1))
        #echo -e "nope, no archives. $count_has_no_archive\n"
    fi

    # clear
    echo -e "has archive: $count_has_archive - no archive: $count_has_no_archive"
    echo -e "archive public: $count_archive_public - archive private: $count_archive_private"
    echo -e "all subscribers: $count_all_subscribers private subscribers: $count_priv_subscribers"
done

echo "has archives: $count_has_archive"
echo "has no archives: $count_has_no_archive"
echo "archive public: $count_archive_public - archive private: $count_archive_private"

sum_lists_ar=$(echo "$count_has_archive + $count_has_no_archive" | bc)
echo "sum a + no: $sum_lists_ar"

sum_lists_pp=$(echo "$count_archive_public + $count_archive_private" | bc)
echo "sum p + p: $sum_lists_pp"


