class profile::mediawiki::maintenance::readinglists {
    profile::mediawiki::periodic_job { 'readinglists_purge':
        command  => '/usr/local/bin/mwscript extensions/ReadingLists/maintenance/purge.php --wiki=metawiki',
        interval => '02:42',
    }
}
