Bugzilla module for Wikimedia

this module sets up parts of a custom
Bugzilla installation for Wikimedia

production: https://bugzilla.wikimedia.org
labs/testing: https://wikitech.wikimedia.org/wiki/Nova Resource:Bugzilla
docs: http://wikitech.wikimedia.org/view/Bugzilla

requirements: a basic Apache setup on the node
             class {'webserver::php5': ssl => true; }

this sets up:

- the apache site config
- the SSL certs
- the /srv/org/wikimedia dir
- cronjobs and scripts:
 - auditlomail for bz admins, bash
 - mail report for community metrics, bash
 - whine / collectstats statistics, perl
 - bugzilla reporter, php

you still have to copy upstream bugzilla itself
to the bugzilla path and clone our modifications
from the wikimedia/bugzilla/modifcations repo

