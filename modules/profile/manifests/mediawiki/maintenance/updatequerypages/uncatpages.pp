# SPDX-License-Identifier: Apache-2.0
define profile::mediawiki::maintenance::updatequerypages::uncatpages() {
    $db_cluster = regsubst($name, '@.*', '\1')
    profile::mediawiki::periodic_job { "updatequerypages_uncatpages_${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Uncategorizedpages",
        interval => '*-14,28 01:00',
    }
}
