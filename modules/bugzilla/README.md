Bugzilla module for Wikimedia
=============================

https://bugzilla.wikimedia.org
http://wikitech.wikimedia.org/view/Bugzilla

requirements: a basic Apache setup on the node
e.g. class {'webserver::php5': ssl => true; }


 - the apache site config
 - the SSL certs
 - the /srv/org/wikimedia dir
 - cronjobs and scripts:
  - auditlog mail for bz admins, bash
  - mail report for community metrics, bash
  - whine / collectstats statistics, perl
  - bugzilla reporter, php

You still have to copy upstream bugzilla itself into
/srv/org/wikimedia/bugzilla/ and clone our modifications
from the wikimedia/bugzilla/modifcations repo.

