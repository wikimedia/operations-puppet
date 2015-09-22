#!/bin/bash
# helper script to rename a mailman list
# Daniel Zahn <dzahn@wikimedia.org>
# https://wikitech.wikimedia.org/wiki/Mailman#Rename_a_mailing_list
#
oldlist=$1
newlist=$2

# create new list $2
# rsync ./lists/ dir from old to new
# copy mbox file from old to new
# rename mbox file
# recreate archives from mbox for new list
# set correct permissions
# add old list email address to "acceptable aliases" on new list
# output suggested apache redirect and exim alias lines

