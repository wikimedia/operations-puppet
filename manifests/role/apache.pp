# role/apache.pp
# cache::applicationserver role class

class role::applicationserver {
	class common(
		$cluster,
		$nagios_group=$cluster,
		$lvs_pool,
		$apache=true,
		$upload=true,
		$geoip=true,
		$jobrunner=false
		) {

		include	standard,
			mediawiki::packages

		if $::realm == 'production' {
			include	admins::roots,
				admins::dctech,
				admins::mortals,
				accounts::l10nupdate
				if $geoip == true {
					include	geoip
				}
		}

		if $lvs_pool {
			include lvs::configuration
			class { "lvs::realserver": realserver_ips => [ $lvs::configuration::lvs_service_ips[$::realm][$lvs_pool][$::site] ] }
		}

		if $apache == true {
			include	apaches::cron,
				apaches::service,
				apaches::pybal-check,
				apaches::syslog
			class { "apaches::monitoring": realm => $realm }
		}

		if $cluster == "imagesclager" {
			include	imagescaler::cron,
				imagescaler::packages,
				imagescaler::files
				if $::realm == 'labs' {
					include	nfs::apache::labs
				}
		}

		if $upload == true {
			include	nfs::upload
		}

		if $jobrunner == true {
			include	jobrunner::packages
		}
	}

	## prod role classes
	class appserver{
		class {"role::applicationserver::common": cluster => "appserver", lvs_pool => "apaches"}
	}
	class api_appserver{
		class {"role::applicationserver::common": cluster => "api_appserver", lvs_pool => "api"}
	}
	class bits_appserver{
		class {"role::applicationserver::common": cluster => "bits_appserver", lvs_pool => "apaches", upload => false}
	}
	class imagescaler{
		class {"role::applicationserver::common": cluster => "imagescaler", lvs_pool => "rendering", geoip => false }
	}
	class jobrunner{
		class {"role::applicationserver::common": cluster => "jobrunner", geoip => false, upload => false, lvsrealserver => false, apache => false }
	}
}

