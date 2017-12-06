class mediawiki::maintenance::readinglists( $ensure = present ) {

    require ::mediawiki

    system::role { 'mediawiki::maintenance::readinglists': description => 'Mediawiki Maintenance Server: purge old deleted data from ReadingLists extension' }

    cron { 'readinglists_purge':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        minute   => 42,
        hour     => 2,
        command  => '/usr/local/bin/mwscript extensions/ReadingLists/maintenance/purge.php metawiki > /var/log/mediawiki/readinglists_purge.log',
    }
}

