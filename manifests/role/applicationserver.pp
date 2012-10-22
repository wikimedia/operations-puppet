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
		## TODO: rename to just mediawiki after full transition to module
			mediawiki_new

		if $::realm == 'production' {
			include	admins::roots,
				admins::mortals,
				geoip
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
	# This class installs everything necessary to process jobs
	class jobs (
		$user = "apache",
		$type = "",
		$nice = 20,
		$script = "/usr/local/bin/jobs-loop.sh",
		$pid_file = "/var/run/mw-jobs.pid",
		$timeout = 300,
		$extra_args = "",
		$procs = 5
	) {

		## TODO: get rid of this awfulness after full transition to module/precise
		if ( $::lsbdistcodename == "precise" ) {
		include mediawiki_new
		} else {
		include mediawiki::packages
		}

		package { [ 'wikimedia-job-runner' ]:
			ensure => absent;
		}
		file {
			"/etc/init.d/mw-job-runner":
				owner => root,
				group => root,
				mode => 0755,
				source => "puppet:///files/jobrunner/mw-job-runner.init";
		}
		file {
			"/etc/default/mw-job-runner":
				content => template("jobrunner/mw-job-runner.default.erb");
		}
		file {
			"/usr/local/bin/jobs-loop.sh":
				owner => root,
				group => root,
				mode => 0755,
				content => template("jobrunner/jobs-loop.sh.erb");
		}
		service {
			"mw-job-runner":
				require => [
					File[
						"/etc/default/mw-job-runner",
						"/etc/init.d/mw-job-runner",
						"/usr/local/bin/jobs-loop.sh"
					],
					Package[
						"wikimedia-job-runner",
						"wikimedia-task-appserver"
					],
				],
				subscribe => File[
					"/etc/default/mw-job-runner",
					"/etc/init.d/mw-job-runner",
					"/usr/local/bin/jobs-loop.sh"
				],
				hasstatus => false,
				pattern => $script,
				ensure => running;
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

		class { "role::applicationserver::jobs": procs => 12 }
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
	class videoscaler{
		class { "role::applicationserver::common": group => "videoscaler" }

		include imagescaler::cron,
			imagescaler::packages,
			imagescaler::files

		class {"role::applicationserver::jobs":
			procs => 5,
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
}
