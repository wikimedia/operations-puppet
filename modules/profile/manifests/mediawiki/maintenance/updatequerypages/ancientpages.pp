define profile::mediawiki::maintenance::updatequerypages::ancientpages() {
    $db_cluster = regsubst($name, '@.*', '\1')
    profile::mediawiki::periodic_job { "updatequerypages_ancientpages_${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Ancientpages",
        interval => '*-8,22 01:00',
    }
}
