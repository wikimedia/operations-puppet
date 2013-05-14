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
@monitor_group { "videoscaler_pmtpa": description => "pmtpa video scaler" }
@monitor_group { "videoscaler_eqiad": description => "eqiad video scaler" }

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
		$lvs_pool = undef
		) {

		$nagios_group = "${group}_${::site}"
		$cluster = "${group}"

		include	standard,
			mediawiki

		if $::realm == 'production' {
			include	admins::roots,
				admins::mortals,
				geoip
		}

		if $::realm == 'labs' {
			# MediaWiki configuration specific to labs instances ('beta' project)

			# Umount /dev/vdb from /mnt ...
			mount { '/mnt':
				name => '/mnt',
				ensure => absent,
			}

			# ... and mount it on /srv
			mount { '/srv':
				ensure => mounted,
				device => '/dev/vdb',
				fstype => 'auto',
				options => 'defaults,nobootwait,comment=cloudconfig',
				require => Mount['/mnt'],
			}
		}

		if $lvs_pool != undef {
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

		class { "applicationserver::config::apache": maxclients => $maxclients }

		monitor_service { "appserver http":
			description => "Apache HTTP",
			check_command => $::realm ? {
				'production' => "check_http_wikipedia",
				'labs' => "check_http_url!commons.wikimedia.beta.wmflabs.org|http://commons.wikimedia.beta.wmflabs.org/wiki/Main_Page"
				}
		}

		## ganglia module for apache webservers
		file {
			"/usr/lib/ganglia/python_modules/apache_status.py":
				source => "puppet:///files/ganglia/plugins/apache_status.py",
				notify => Service[gmond];
			"/etc/ganglia/conf.d/apache_status.pyconf":
				source => "puppet:///files/ganglia/plugins/apache_status.pyconf",
				notify => Service[gmond];
		}
	}

	## prod role classes
	class appserver{
		system_role { "role::applicationserver::appserver": description => "Standard Apache Application server" }

		class { "role::applicationserver::common": group => "appserver", lvs_pool => "apaches" }

		include role::applicationserver::webserver
	}
	# role class specifically for test.w.o apache(s)
	class appserver::test{
		system_role { "role::applicationserver::appserver::test": description => "Test Apache Application server" }

		class { "role::applicationserver::common": group => "appserver", lvs_pool => "apaches" }

		class { "role::applicationserver::webserver": maxclients => "100" }
	}
	# Class for the beta project
	# The Apaches instances act as webserver AND imagescalers. We cannot
	# apply both roles cause puppet will complains about a duplicate class
	# definition for role::applicationserver::common
	class appserver::beta{
		system_role { "role::applicationserver::appserver::beta": description => "Beta Apache Application server" }

		class { "role::applicationserver::common": group => "beta_appserver" }

		include role::applicationserver::webserver

		# Load the class just like the role::applicationserver::imagescaler
		# role.
		include imagescaler::cron,
			imagescaler::packages,
			imagescaler::files
	}
	class appserver::api{
		system_role { "role::applicationserver::appserver::api": description => "Api Apache Application server" }

		class { "role::applicationserver::common": group => "api_appserver", lvs_pool => "api" }

		class { "role::applicationserver::webserver": maxclients => "100" }
	}
	class appserver::bits{
		system_role { "role::applicationserver::appserver::bits": description => "Bits Apache Application server" }

		class { "role::applicationserver::common": group => "bits_appserver", lvs_pool => "apaches" }

		include role::applicationserver::webserver
	}
	class imagescaler{
		system_role { "role::applicationserver::imagescaler": description => "Imagescaler Application server" }

		class { "role::applicationserver::common": group => "imagescaler", lvs_pool => "rendering" }

		class { "role::applicationserver::webserver": maxclients => "18" }

		# When adding class there, please also update the appserver::beta
		# class which mix both webserver and imagescaler roles.
		include	imagescaler::cron,
			imagescaler::packages,
			imagescaler::files
	}
	class videoscaler( $run_jobs_enabled = true ){
		system_role { "role::applicationserver::videoscaler": description => "TMH Jobrunner Server" }

		class { "role::applicationserver::common": group => "videoscaler" }

		include imagescaler::cron,
			imagescaler::packages,
			imagescaler::files

		class {"mediawiki::jobrunner":
			run_jobs_enabled => $run_jobs_enabled,
			dprioprocs => 10,
			iprioprocs => 0,
			type => "webVideoTranscode",
			timeout => 14400,
			extra_args => "-v 0"
		}

		include applicationserver::config::php,
			applicationserver::config::base,
			applicationserver::packages,
			applicationserver::cron,
			applicationserver::sudo

		# dependency for wikimedia-task-appserver
		service { 'apache':
			name => "apache2",
			enable => false,
			ensure => stopped;
		}
	}
	class jobrunner( $run_jobs_enabled = true ){
		system_role { "role::applicationserver::jobrunner": description => "Standard Jobrunner Server" }

		class { "role::applicationserver::common": group => "jobrunner" }

		class { "mediawiki::jobrunner": dprioprocs => 12, iprioprocs => 6, run_jobs_enabled => $run_jobs_enabled }
		include applicationserver::config::php,
			applicationserver::config::base,
			applicationserver::packages,
			applicationserver::cron,
			applicationserver::sudo

		# dependency for wikimedia-task-appserver
			service { 'apache':
				name => "apache2",
				enable => false,
				ensure => stopped;
		}
	}

	# Class for servers which run MW maintenance scripts.
	# Maintenance servers are sometimes dual-purpose with misc apache, so the
	# apache service installed by wikimedia-task-appserver is not disabled here.
	class maintenance {
		class { "role::applicationserver::common": group => "misc" }

		include applicationserver::config::php,
			applicationserver::config::base,
			applicationserver::packages,
			applicationserver::cron,
			applicationserver::sudo

	}
}
