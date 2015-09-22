#!/bin/bash
# helper script to rename a mailman list
# Daniel Zahn <dzahn@wikimedia.org>
# https://wikitech.wikimedia.org/wiki/Mailman#Rename_a_mailing_list
#
mailman_dir="/var/lib/mailman"

oldlist=$1
newlist=$2

# create new list $2
${mailman_dir}/bin/newlist ${newlist}
# rsync ./lists/ dir from old to new
rsync -avp ${mailman_dir}/lists/$oldlist ${mailman_dir}/lists/$newlist
# copy mbox file from old to new
cp ${mailman_dir}/archives/private/${oldlist}.mbox/${oldlist}.mbox ${mailman_dir}/archives/private/${newlist}.mbox/${newlist}.mbox
# recreate archives from mbox for new list
$[mailman_dir}/bin/arch ${newlist}
# set correct permissions
# add old list email address to "acceptable aliases" on new list
# output suggested apache redirect and exim alias lines

