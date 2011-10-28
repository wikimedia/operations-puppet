#!/bin/bash

##################################
# THIS FILE IS MANAGED BY PUPPET #
##################################

REV="$1"
nohup sh -c "
wget -q --timeout=30 -O /dev/null --post-data=\"\" \
  \"http://www.mediawiki.org/w/api.php?action=codeupdate&format=xml&repo=MediaWiki&rev=$REV\""

