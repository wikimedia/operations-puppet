#/bin/bash
# report average spam score of held messages
# Daniel Zahn <dzahn@wikimedia.org>
#
# usage: ./spam_report <listname>

list_name = $1
mailman_dir = "/var/lib/mailman"

if [ -z "$list_name" ]
    then echo "please specify a list name. usage: $0 <listname>"
    exit 0
fi

if [ ! -d "$mailman_dir/data" ]
    then echo "no mailman data found at ${mailman_dir}/data"
    exit 1
fi

/usr/bin/find ${mailman_dir}/data/ \
-name "heldmsg-${list_name}*.pck \
-exec ${mailman_dir}/bin/dumpdb {} \; \
| grep -o "Spam-Score: [0-9]*.[0-9]*" \
| tee /tmp/mailman_spam_score_${list_name}


num_held_messages=$(wc -l /tmp/mailman_spam_score_${list_name})

all_scores=$(sed "s/Spam-Score: / + /g" < /tmp/mailman_spam_score_${list_name})

#sum_score=$(echo $all_scores | bc )
#average_score=$()

echo "spam report for list ${list_name} ...\n"


