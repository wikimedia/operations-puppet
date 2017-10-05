class mediawiki::maintenance::purge_expired_userrights( $ensure = present ) {
    cron { 'purge_expired_userrights':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwiki maintenance/purgeExpiredUserrights.php >/dev/null 2>&1',
        user    => $::mediawiki::users::web,
        monthday => [ 7, 21 ]
        hour    => 6,
        minute  => 42,
    }
}
