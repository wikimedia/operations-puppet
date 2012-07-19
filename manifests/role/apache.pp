# role/apache.pp
# cache::applicationserver role class

class role::applicationserver {
	class common(
		$cluster,
		$nagios_group=$cluster,
		$apache=true,
		$lvs_pool,
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
				apaches::monitoring,
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

		if $lvsrealserver == true {
			## need to replace this with swift stuff
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
	## FIXME:
	## hash in lvs.pp needs to be restructured for lvs_pool to work for bits
	class bits_appserver{
		class {"role::applicationserver::common": cluster => "bits_appserver", upload => false}
	}
	class imagescaler{
		class {"role::applicationserver::common": cluster => "imagescaler", geoip => false, lvs_pool => "rendering"}
	}
	class jobrunner{
		class {"role::applicationserver::common": cluster => "jobrunner", geoip => false, upload => false, lvsrealserver => false, apache => false }
	}
}

