# role/apaches.pp

# Virtual monitor group resources for the monitoring server
@monitor_group { "appserver": description => "pmtpa application servers" }
@monitor_group { "api_appserver": description => "pmtpa API application servers" }
@monitor_group { "bits_appserver": description => "pmtpa Bits application servers" }
@monitor_group { "imagescaler": description => "image scalers" }
@monitor_group { "jobrunner": description => "jobrunner application servers" }


# FIXME: add documentation for parameters
class role::applicationserver {
	class common(
		$cluster,
		$nagios_group=$cluster,
		$lvs_pool,
		$upload=true
		) {

		include	standard,
			mediawiki::packages

		if $::realm == 'production' {
			include	admins::roots,
				admins::dctech,
				admins::mortals,
				geoip,
				# FIXME: l10nupdate should move out of accounts::
				accounts::l10nupdate
		}

		if $lvs_pool != undef {
			include lvs::configuration
			class { "lvs::realserver": realserver_ips => [ $lvs::configuration::lvs_service_ips[$::realm][$lvs_pool][$::site] ] }
		}

		if $upload == true {
			## need to replace this with swift stuff
			include	nfs::upload
		}
	}

	class apache {
		include	apaches::cron,
			apaches::service,
			apaches::pybal_check,
			apaches::syslog

		monitor_service { "appserver http": description => "Apache HTTP",
			check_command => $::realm ? { 'production' => "check_http_wikipedia",
				'labs' => "check_http_url!commons.wikimedia.beta.wmflabs.org|http://commons.wikimedia.beta.wmflabs.org/wiki/Main_Page" }
		}
	}

	## prod role classes
	class appserver{
		class {"role::applicationserver::common": cluster => "appserver", lvs_pool => "apaches"}
		
		include role::applicationserver::apache
	}
	class api_appserver{
		class {"role::applicationserver::common": cluster => "api_appserver", lvs_pool => "api"}
			
		include role::applicationserver::apache
	}
	class bits_appserver{
		class {"role::applicationserver::common": cluster => "bits_appserver", lvs_pool => "apaches", upload => false}
		
		include role::applicationserver::apache
	}
	class imagescaler{
		class {"role::applicationserver::common": cluster => "imagescaler", lvs_pool => "rendering" }

		include role::applicationserver::apache

		include	imagescaler::cron,
			imagescaler::packages,
			imagescaler::files
			if $::realm == 'labs' {
				include	nfs::apache::labs
			}
	}
	class jobrunner{
		class {"role::applicationserver::common": cluster => "jobrunner", upload => false }

		package { [ 'wikimedia-job-runner' ]:
			ensure => latest;
		}
	}
}

