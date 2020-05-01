define profile::mediawiki::maintenance::updatequerypages::mostrevisions() {
    $db_cluster = regsubst($name, '@.*', '\1')
    profile::mediawiki::periodic_job { "updatequerypages_mostrevisions_${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Mostrevisions",
        interval => '*-11,25 01:00',
    }
}
