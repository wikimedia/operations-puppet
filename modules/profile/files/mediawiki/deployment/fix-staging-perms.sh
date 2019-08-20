#!/bin/bash
# Fixes permissions on /srv/mediawiki-staging.

set -euf
set -o pipefail

# Get root if we don't have it.
# Group 'deployment' should have sudo perms for this.
[[ "$UID" == 0 ]] || exec sudo "$0" "$@"

# All files and directories should be group-writable.
chmod -R g+w /srv/mediawiki-staging

# Files and directories should have group ownership of either wikidev or l10nupdate.
find /srv/mediawiki-staging -not -group l10nupdate -and -not -group wikidev -print0 | xargs -0 -r chgrp wikidev
