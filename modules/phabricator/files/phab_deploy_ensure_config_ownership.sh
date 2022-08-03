#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Ensures that files under phabricator/conf/local/ and phabricator/support/
# have the right group ownership and permissions. This script is intended to
# run following the config_deploy stage of phabricator deployment via scap
# deploy.

set -eu

if [ -z "$SCAP_REV_PATH" ]; then
  echo '$SCAP_REV_PATH is not defined.'
  echo 'Note: This script is only intended to run as a scap deploy check'
  exit 1
fi

chgrp mail "$SCAP_REV_PATH"/phabricator/conf/local/mail.json
chgrp phd "$SCAP_REV_PATH"/phabricator/conf/local/phd.json
chgrp phd "$SCAP_REV_PATH"/phabricator/conf/local/vcs.json
chgrp www-data "$SCAP_REV_PATH"/phabricator/conf/local/www.json

chgrp www-data "$SCAP_REV_PATH"/phabricator/support/redirect_config.json

chmod 0440 "$SCAP_REV_PATH"/phabricator/conf/local/*.json
chmod 0440 "$SCAP_REV_PATH"/phabricator/support/*.json

