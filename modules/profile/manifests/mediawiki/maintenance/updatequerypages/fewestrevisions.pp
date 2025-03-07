define profile::mediawiki::maintenance::updatequerypages::fewestrevisions(
    Wmflib::Ensure $ensure = present,
) {
    $db_cluster = regsubst($name, '@.*', '\1')
    profile::mediawiki::periodic_job { "updatequerypages_fewestrevisions_${name}":
        ensure   => $ensure,
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Fewestrevisions",
        interval => '*-13,27 01:00',
    }
}
