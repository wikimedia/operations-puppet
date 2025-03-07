define profile::mediawiki::maintenance::updatequerypages::deadendpages(
    Wmflib::Ensure $ensure = present,
) {
    $db_cluster = regsubst($name, '@.*', '\1')
    profile::mediawiki::periodic_job { "updatequerypages_deadendpages_${name}":
        ensure   => $ensure,
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Deadendpages",
        interval => '*-9,23 01:00',
    }
}
