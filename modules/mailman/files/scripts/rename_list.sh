#!/bin/bash
# helper script to rename a mailman list
# Daniel Zahn <dzahn@wikimedia.org>
# https://wikitech.wikimedia.org/wiki/Mailman#Rename_a_mailing_list
#
mailman_dir="/var/lib/mailman"

oldlist=$1
newlist=$2

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "usage: $0 <old list> <new list>"
    exit 0
else
    oldlist=$1
    newlist=$2
fi

# create new list $2
echo "${mailman_dir}/bin/newlist ${newlist}"

# rsync ./lists/ dir from old to new
echo "/usr/bin/rsync -avp ${mailman_dir}/lists/${oldlist} ${mailman_dir}/lists/${newlist}"

# copy mbox file from old to new
echo "cp ${mailman_dir}/archives/private/${oldlist}.mbox/${oldlist}.mbox ${mailman_dir}/archives/private/${newlist}.mbox/${newlist}.mbox"

# recreate archives from mbox for new list
echo "${mailman_dir}/bin/arch ${newlist}"

# set correct permissions
echo "chown list:list ${mailman_dir}/archives/private/${newlist}.mbox/${newlist}.mbox"

# add old list email address to "acceptable aliases" on new list
echo "echo \"acceptable_aliases = '${oldlist}@lists.wikimedia.org'\"  | ${mailman_dir}/bin/config_list -i /dev/stdin ${newlist}"

# output suggested apache redirect and exim alias lines
echo -e "\nPlease add the following code to ./files/exim/listserver_aliases:\n"
echo -e "${oldlist}: ${newlist} \n"

echo -e "Please add the following code to ./modules/mailman/templates/lists.wikimedia.org.org:\n"
echo -e "Redirect permanent /mailman/listinfo/${oldlist} https://<%= @lists_servername %>/mailm
an/listinfo/${newlist}"

