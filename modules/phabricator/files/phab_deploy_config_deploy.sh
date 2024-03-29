#!/bin/sh
#
# Ensures that files under phabricator/conf/local/ and phabricator/support/
# have the right group ownership and permissions. This script is intended to
# run following the config_deploy stage of phabricator deployment via scap
# deploy.

. /etc/phabricator/script-vars

if [ -z "$SCAP_REV_PATH" ]; then
  echo '$SCAP_REV_PATH is not defined.'
  echo 'Note: This script is only intended to run as a scap deploy check'
  exit 1
fi

# Note that the config file owner (deploy user) must retain write permissions
# in order to successfully clean up old scap-deployed revs, hence the 0640
# mode.
#
sudo chgrp www-data "$SCAP_REV_PATH"/phabricator/conf/local/*.json
sudo chmod 0640 "$SCAP_REV_PATH"/phabricator/conf/local/*.json
sudo chmod a+r "$SCAP_REV_PATH"/phabricator/conf/local/local.json

sudo chgrp mail "$SCAP_REV_PATH"/phabricator/conf/local/mail.json
sudo chgrp phd "$SCAP_REV_PATH"/phabricator/conf/local/phd.json
sudo chgrp phd "$SCAP_REV_PATH"/phabricator/conf/local/vcs.json

sudo chgrp www-data "$SCAP_REV_PATH"/phabricator/support/redirect_config.json
sudo chmod 0640 "$SCAP_REV_PATH"/phabricator/support/redirect_config.json
