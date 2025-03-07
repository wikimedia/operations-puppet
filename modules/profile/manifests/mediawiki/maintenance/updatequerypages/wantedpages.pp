define profile::mediawiki::maintenance::updatequerypages::wantedpages(
    Wmflib::Ensure $ensure = present,
) {
    $db_cluster = regsubst($name, '@.*', '\1')
    profile::mediawiki::periodic_job { "updatequerypages_wantedpages_${name}":
        ensure   => $ensure,
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Wantedpages",
        interval => '*-12,26 01:00',
    }
}
