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

		$nagios_group = "${group}_${::site}"
		$cluster = "${group}"

		include	standard,
		## TODO: rename to just mediawiki after full transition to module
			mediawiki_new

		if $::realm == 'production' {
			include	admins::roots,
				admins::mortals,
				geoip
		}

		if $lvs_pool {
			include lvs::configuration
			class { "lvs::realserver": realserver_ips => $lvs::configuration::lvs_service_ips[$::realm][$lvs_pool][$::site] }
		}
	}

	# This class installs everything necessary for an apache webserver
	class webserver($maxclients="40") {
		include	::applicationserver,
			applicationserver::pybal_check,
			applicationserver::syslog,
			applicationserver::config::php

		class { "applicationserver::config::apache": }

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

	## prod role classes
	class appserver{
		class { "role::applicationserver::common": group => "appserver", lvs_pool => "apaches" }

		include role::applicationserver::webserver
	}
	class appserver::api{
		class { "role::applicationserver::common": group => "api_appserver", lvs_pool => "api" }

		class { "role::applicationserver::webserver": maxclients => "100" }
	}
	class appserver::bits{
		class { "role::applicationserver::common": group => "bits_appserver", lvs_pool => "apaches" }

		include role::applicationserver::webserver
	}
	class imagescaler{
		class { "role::applicationserver::common": group => "imagescaler", lvs_pool => "rendering" }

		include role::applicationserver::webserver

		include	imagescaler::cron,
			imagescaler::packages,
			imagescaler::files
	}
	class jobrunner{
		class { "role::applicationserver::common": group => "jobrunner" }

		include ::jobrunner
	}
}
