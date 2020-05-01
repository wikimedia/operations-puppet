define profile::mediawiki::maintenance::updatequerypages::mostlinked() {
    $db_cluster = regsubst($name, '@.*', '\1')
    profile::mediawiki::periodic_job { "updatequerypages_mostlinked_${name}":
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Mostlinked",
        interval => '*-10,24 01:00',
    }
}
