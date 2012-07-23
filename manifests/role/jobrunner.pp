# role/jobrunner.pp

class role::jobrunner::videoscaler {
	$cluster = "videoscaler"

	if( $::realm == 'labs' ) {
		include nfs::apache::labs
	}

	include standard,
		videoscaler::cron,
		videoscaler::packages,
		videoscaler::files,
		mediawiki::packages,
		apaches::packages,
		apaches::cron,
		apaches::service
}
