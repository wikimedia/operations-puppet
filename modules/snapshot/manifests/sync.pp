class snapshot::sync {
    require snapshot::packages
    require mediawiki::sync

    exec { 'snapshot-trigger-mw-sync':
        command => '/bin/true',
        notify  => Exec['mw-sync'],
        unless  => '/usr/bin/test -d /usr/local/apache/common-local',
    }
}
