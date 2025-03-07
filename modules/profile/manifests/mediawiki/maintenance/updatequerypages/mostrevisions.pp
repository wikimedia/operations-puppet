define profile::mediawiki::maintenance::updatequerypages::mostrevisions(
    Wmflib::Ensure $ensure = present,
) {
    $db_cluster = regsubst($name, '@.*', '\1')
    profile::mediawiki::periodic_job { "updatequerypages_mostrevisions_${name}":
        ensure   => $ensure,
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Mostrevisions",
        interval => '*-11,25 01:00',
    }
}
