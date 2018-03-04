class mediawiki::maintenance::purge_expired_userrights( $ensure = present ) {
	cron { 'purge-expired-userrights':
        	ensure  => $ensure,
        	user    => $::mediawiki::users::web,
        	minute  => 0,
        	hour    => 0,
        	weekday => 0,
        	command => '/usr/local/bin/foreachwiki maintenance/purgeExpiredUserrights.php >/dev/null 2>&1',
	}
}
