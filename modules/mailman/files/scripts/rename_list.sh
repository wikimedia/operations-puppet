#!/bin/bash
# helper script to rename a mailman list
# Daniel Zahn <dzahn@wikimedia.org>
# https://wikitech.wikimedia.org/wiki/Mailman#Rename_a_mailing_list
#
mailman_dir="/var/lib/mailman"

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "usage: $0 <old list> <new list>"
    exit 0
else
    oldlist=$1
    newlist=$2
fi

echo "Going to rename list '$oldlist' to '$newlist'. Go ahead? (y/n)"
read yesorno
if [ $yesorno != 'y' ]; then
    echo -e "Nothing has been done. Bye.\n"
    exit 0
fi

# create new list $2
echo -e "First we are creating the new list '${newlist} like any other list. \nPlease use your email address as list admin when asked. It will be overwritten later.'. \n"
echo -e "${mailman_dir}/bin/newlist ${newlist}\n\n"
${mailman_dir}/bin/newlist ${newlist}
sleep 1

# rsync ./lists/ dir (config, subscribers) from old to new
echo -e "Syncing list config and subscribers from '${oldlist}' to '${newlist}'.\n"
echo -e "/usr/bin/rsync -avp ${mailman_dir}/lists/${oldlist}/ ${mailman_dir}/lists/${newlist}/\n\n"
/usr/bin/rsync -avp ${mailman_dir}/lists/${oldlist}/ ${mailman_dir}/lists/${newlist}/
sleep 1

# change "real_name" of the new list from old to new after we copied config
echo -e "Changing the list 'real_name' to '${newlist}' after we copied config over.\n"
echo -e "echo \"real_name = '${newlist}'\"  | ${mailman_dir}/bin/config_list -i /dev/stdin ${newlist}\n\n"
echo "real_name = '${newlist}'"  | ${mailman_dir}/bin/config_list -i /dev/stdin ${newlist}
sleep 1

# copy mbox file from old to new
echo -e "Copying mbox file from '${oldlist}' to '${newlist}'.\n"
echo -e "cp ${mailman_dir}/archives/private/${oldlist}.mbox/${oldlist}.mbox ${mailman_dir}/archives/private/${newlist}.mbox/${newlist}.mbox\n\n"
cp ${mailman_dir}/archives/private/${oldlist}.mbox/${oldlist}.mbox ${mailman_dir}/archives/private/${newlist}.mbox/${newlist}.mbox
sleep 1

# recreate archives from mbox for new list
echo -e "Recreating HTML archives from mbox file for '${newlist}'.\n"
echo -e "${mailman_dir}/bin/arch ${newlist}\n\n"
${mailman_dir}/bin/arch ${newlist}
sleep 1

# set correct permissions
echo -e "Making sure mbox file is owned by list:list.\n"
echo -e "chown list:list ${mailman_dir}/archives/private/${newlist}.mbox/${newlist}.mbox\n\n"
chown list:list ${mailman_dir}/archives/private/${newlist}.mbox/${newlist}.mbox
sleep 1

# add old list email address to "acceptable aliases" on new list
echo -e "Adding '${oldlist}@lists.wikimedia.org' to acceptable aliases on '${newlist}'.\n"
echo -e "echo \"acceptable_aliases = '${oldlist}@lists.wikimedia.org'\"  | ${mailman_dir}/bin/config_list -i /dev/stdin ${newlist}\n\n"
echo "acceptable_aliases = '${oldlist}@lists.wikimedia.org'"  | ${mailman_dir}/bin/config_list -i /dev/stdin ${newlist}
sleep 1

# output suggested apache redirect and exim alias lines
echo -e "\nPlease add the following code to './modules/profile/files/exim/listserver_aliases':\n--------\n"
echo -e "${oldlist}: ${newlist} \n--------\n"
sleep 1

echo -e "Please add the following code to './modules/mailman/templates/lists.wikimedia.org.erb':\n--------\n"
echo -e "Redirect permanent /mailman/listinfo/${oldlist} https://<%= @lists_servername %>/mailm
an/listinfo/${newlist}\n--------\n\n"
sleep 1

echo -e "To finish this please upload the code changes above to Gerrit and merge.\n\nTest by sending a mail to both ${oldlist}@lists.wikimedia.org and ${newlist}@lists.wikimedia.org.\n\nCheck the listinfo pages at https://lists.wikimedia.org/mailman/listinfo/${oldlist} and https://lists.wikimedia.org/mailman/listinfo/${newlist}\n"
sleep 1

echo -e "Don't forget to update the ticket and that should be all. Bye.\n"

