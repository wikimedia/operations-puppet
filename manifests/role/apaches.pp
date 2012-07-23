# role/apaches.pp

# Virtual monitor group resources for the monitoring server
@monitor_group { "appserver": description => "pmtpa application servers" }
@monitor_group { "api_appserver": description => "pmtpa API application servers" }
@monitor_group { "bits_appserver": description => "pmtpa Bits application servers" }
@monitor_group { "imagescaler": description => "image scalers" }
@monitor_group { "jobrunner": description => "jobrunner application servers" }


class role::applicationserver {
	class common(
		## $cluster: used for ganglia
		## $nagios_ group: used for nagios
		## $lvs_pool: used for lvs realserver IP
		$cluster,
		$nagios_group=$cluster,
		$lvs_pool
		) {

		include	standard,
			mediawiki::packages

		if $::realm == 'production' {
			include	admins::roots,
				admins::dctech,
				admins::mortals,
				geoip,
				mediawiki::user::l10nupdate
		}

		if $lvs_pool != undef {
			include lvs::configuration
			class { "lvs::realserver": realserver_ips => [ $lvs::configuration::lvs_service_ips[$::realm][$lvs_pool][$::site] ] }
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

	## Still needed to pmtpa testing. can be deleted once we're using swift fully
	class upload_nfs {
		include	nfs::upload
	}

	## prod role classes
	class appserver{
		class {"role::applicationserver::common": cluster => "appserver", lvs_pool => "apaches" }
		
		include role::applicationserver::apache
		include role::applicationserver::upload_nfs
	}
	class api_appserver{
		class {"role::applicationserver::common": cluster => "api_appserver", lvs_pool => "api" }
			
		include role::applicationserver::apache
		include role::applicationserver::upload_nfs
	}
	class bits_appserver{
		class {"role::applicationserver::common": cluster => "bits_appserver", lvs_pool => "apaches" }
		
		include role::applicationserver::apache
	}
	class imagescaler{
		class {"role::applicationserver::common": cluster => "imagescaler", lvs_pool => "rendering" }

		include role::applicationserver::apache
		include role::applicationserver::upload_nfs

		include	imagescaler::cron,
			imagescaler::packages,
			imagescaler::files
	}
	class jobrunner{
		class {"role::applicationserver::common": cluster => "jobrunner" }

		package { [ 'wikimedia-job-runner' ]:
			ensure => latest;
		}
	}
}

