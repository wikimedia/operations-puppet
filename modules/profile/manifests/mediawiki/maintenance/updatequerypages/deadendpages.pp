define profile::mediawiki::maintenance::updatequerypages::deadendpages() {
    $db_cluster = regsubst($name, '@.*', '\1')
    profile::mediawiki::periodic_job { "updatequerypages_deadendpages_${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Deadendpages",
        interval => '*-9,23 01:00',
    }
}
