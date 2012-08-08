# role/apaches.pp

# Virtual monitor group resources for the monitoring server
@monitor_group { "appserver_eqiad": description => "eqiad application servers" }
@monitor_group { "appserver_pmtpa": description => "pmtpa application servers" }
@monitor_group { "api_appserver_eqiad": description => "eqiad API application servers" }
@monitor_group { "api_appserver_pmtpa": description => "pmtpa API application servers" }
@monitor_group { "bits_appserver_eqiad": description => "eqiad Bits application servers" }
@monitor_group { "bits_appserver_pmtpa": description => "pmtpa Bits application servers" }
@monitor_group { "imagescaler_eqiad": description => "eqiad image scalers" }
@monitor_group { "imagescaler_pmtpa": description => "pmtpa image scalers" }
@monitor_group { "jobrunner_eqiad": description => "eqiad jobrunner application servers" }
@monitor_group { "jobrunner_pmtpa": description => "pmtpa jobrunner application servers" }

class role::applicationserver {
# Class: role::applicationserver
#
# This class installs a mediawiki application server
#
# Parameters:
#	- $group:
#		Determines what logical group the host will be a
#		part of. Used for ganglia. Possibilities are:
#		appserver, api_appserver, bits_appserver, imagescaler, jobrunner
#	- $lvs_pool:
#		Determines lvsrealserver IP(s) that the host will receive.
#		From lvs::configuration::$lvs_service_ips
	class common(
		$group,
		$lvs_pool
		) {

		$nagios_group = "${::cluster_${::site}"

		include	standard,
			mediawiki

		if $::realm == 'production' {
			include	admins::roots,
				admins::dctech,
				admins::mortals,
				geoip
		}

		if $lvs_pool {
			include lvs::configuration
			class { "lvs::realserver": realserver_ips => $lvs::configuration::lvs_service_ips[$::realm][$lvs_pool][$::site] }
		}
	}

	# This class installs everything necessary for an apache webserver
	class webserver {
		include	::applicationserver,
			sudo::appserver,
			applicationserver::pybal_check,
			applicationserver::sync,
			applicationserver::syslog,
			applicationserver::config::php

		if( $::realm == 'labs' ) {
			include	nfs::apache::labs
		}

		monitor_service { "appserver http":
			description => "Apache HTTP",
			check_command => $::realm ? {
				'production' => "check_http_wikipedia",
				'labs' => "check_http_url!commons.wikimedia.beta.wmflabs.org|http://commons.wikimedia.beta.wmflabs.org/wiki/Main_Page"
				}
		}
	}

	## TODO: Still needed to pmtpa testing. can be deleted once we're using swift fully
	class upload_nfs {
		include	nfs::upload
	}

	## prod role classes
	class appserver{
		class { "role::applicationserver::common": cluster => "appserver", lvs_pool => "apaches" }

		class { "applicationserver::config::apache": }

		include role::applicationserver::webserver
		include role::applicationserver::upload_nfs
	}
	class appserver::api{
		class { "role::applicationserver::common": cluster => "api_appserver", lvs_pool => "api" }

		class { "applicationserver::config::apache": maxclients => "100" }

		include role::applicationserver::webserver
		include role::applicationserver::upload_nfs
	}
	class appserver::bits{
		class { "role::applicationserver::common": cluster => "bits_appserver", lvs_pool => "apaches" }

		class { "applicationserver::config::apache": }

		include role::applicationserver::webserver
	}
	class imagescaler{
		class { "role::applicationserver::common": cluster => "imagescaler", lvs_pool => "rendering" }

		class { "applicationserver::config::apache": }

		include role::applicationserver::webserver
		include role::applicationserver::upload_nfs

		include	imagescaler::cron,
			imagescaler::packages,
			imagescaler::files
	}
	class jobrunner{
		class { "role::applicationserver::common": cluster => "jobrunner" }

		include ::jobrunner
	}
}
