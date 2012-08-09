# role/jobrunner.pp

class role::jobrunner::videoscaler {
	$cluster = "videoscaler"

	if( $::realm == 'labs' ) {
		include nfs::apache::labs
	}

	include standard,
		mediawiki::videoscaler,
		mediawiki::packages,
		apaches::packages,
		apaches::cron,
		apaches::service
}
