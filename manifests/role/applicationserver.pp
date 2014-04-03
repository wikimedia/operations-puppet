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

	$mediawiki_log_aggregator = $::realm ? {
		'production' => 'fluorine.eqiad.wmnet:8420',
		'labs'       => "deployment-bastion.${::site}.wmflabs:8420",
	}

	class configuration::php {
		include role::applicationserver

		class { 'applicationserver::config::php':
			fatal_log_file => "udp://${role::applicationserver::mediawiki_log_aggregator}",
		}
	}

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
#	- $hhvm:
#		Whether to install Facebook HipHop Virtual Machine
#		Will FAIL the run if enabled on production.
#		(default: false)
	class common(
		$group,
		$lvs_pool = undef,
		$hhvm = false
		) {

		if $hhvm == true and $::realm == 'production' {
			fail( 'hhvm is not ready for production usage yet' )
		}

		$nagios_group = "${group}_${::site}"
		$cluster = "${group}"

		include	standard

		if $::realm == 'production' {
			include	admins::roots,
				admins::mortals,
				geoip,
				mediawiki

			nrpe::monitor_service { "twemproxy":
				description => "twemproxy process",
				nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u nobody -C nutcracker"
			}
			nrpe::monitor_service { 'twemproxy port':
				description => 'twemproxy port',
				nrpe_command  => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 11211 --timeout=2',
			}
		}

		if $::realm == 'labs' {
			# MediaWiki configuration specific to labs instances ('beta' project)
			include mediawiki

			if $::site == 'pmtpa' {
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
			} elsif $::site == 'eqiad' {
				# Does not come with /dev/vdb, we need to mount it using lvm
				include labs_lvm
				labs_lvm::volume { 'second-local-disk': mountat => '/srv' }
			}

			if $hhvm == true {
				notify { 'installing_hhvm': message => "Installing HHVM" }
				include ::applicationserver::hhvm
			}
		}

		if $lvs_pool != undef {
			include lvs::configuration
			class { "lvs::realserver": realserver_ips => $lvs::configuration::lvs_service_ips[$::realm][$lvs_pool][$::site] }
		}

		if $::realm == 'production' {
			deployment::target { "mediawiki": }
		}
	}

	# This class installs everything necessary for an apache webserver
	class webserver($maxclients="40") {
		include	::applicationserver,
			applicationserver::pybal_check,
			role::applicationserver,
			role::applicationserver::configuration::php

		class { "applicationserver::config::apache": maxclients => $maxclients }

		class { '::applicationserver::syslog':
			apache_log_aggregator => $role::applicationserver::mediawiki_log_aggregator,
		}

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
				owner  => 'root',
				group  => 'root',
				mode   => '0444',
				source => 'puppet:///files/ganglia/plugins/apache_status.py',
				notify => Service['gmond'];
			"/etc/ganglia/conf.d/apache_status.pyconf":
				owner  => 'root',
				group  => 'root',
				mode   => '0555',
				source => 'puppet:///files/ganglia/plugins/apache_status.pyconf',
				notify => Service['gmond'];
		}
	}

	## prod role classes
	class appserver{
		system::role { "role::applicationserver::appserver": description => "Standard Apache Application server" }

		class { "role::applicationserver::common": group => "appserver", lvs_pool => "apaches" }

		if $::site == "eqiad" and $::processorcount == "16" {
			$maxclients = "60"
		}
		elsif $::processorcount == "12" or $::processorcount == "24" {
			$maxclients = "50"
		}
		else {
			$maxclients = "40"
		}
		class { "role::applicationserver::webserver": maxclients => $maxclients }
	}
	# role class specifically for test.w.o apache(s)
	class appserver::test{
		system::role { "role::applicationserver::appserver::test": description => "Test Apache Application server" }

		class { "role::applicationserver::common": group => "appserver", lvs_pool => "apaches" }

		class { "role::applicationserver::webserver": maxclients => "100" }
	}
	# Class for the beta project
	# The Apaches instances act as webserver AND imagescalers. We cannot
	# apply both roles cause puppet will complains about a duplicate class
	# definition for role::applicationserver::common
	class appserver::beta{
		system::role { "role::applicationserver::appserver::beta": description => "Beta Apache Application server" }

		class { "role::applicationserver::common": group => "beta_appserver", hhvm => true }

		include role::applicationserver::webserver
		include ::beta::scap

		# Load the class just like the role::applicationserver::imagescaler
		# role.
		include imagescaler::cron,
			imagescaler::packages,
			imagescaler::files

		# Beta application servers have some ferm DNAT rewriting rules (bug
		# 45868) so we have to explicitly allow http (port 80)
		ferm::service { 'http':
			proto => 'tcp',
			port  => 'http'
		}

	}
	class appserver::api{
		system::role { "role::applicationserver::appserver::api": description => "Api Apache Application server" }

		class { "role::applicationserver::common": group => "api_appserver", lvs_pool => "api" }

		class { "role::applicationserver::webserver": maxclients => "100" }
	}
	class appserver::bits{
		system::role { "role::applicationserver::appserver::bits": description => "Bits Apache Application server" }

		class { "role::applicationserver::common": group => "bits_appserver", lvs_pool => "apaches" }

		class { "role::applicationserver::webserver": maxclients => "100" }
	}
	class imagescaler{
		system::role { "role::applicationserver::imagescaler": description => "Imagescaler Application server" }

		class { "role::applicationserver::common": group => "imagescaler", lvs_pool => "rendering" }

		class { "role::applicationserver::webserver": maxclients => "18" }

		# When adding class there, please also update the appserver::beta
		# class which mix both webserver and imagescaler roles.
		include	imagescaler::cron,
			imagescaler::packages,
			imagescaler::files
	}
	class videoscaler( $run_jobs_enabled = true ){
		system::role { "role::applicationserver::videoscaler": description => "TMH Jobrunner Server" }

		class { "role::applicationserver::common": group => "videoscaler" }

		include imagescaler::cron,
			imagescaler::packages,
			imagescaler::files

		class {"mediawiki::jobrunner":
			run_jobs_enabled => $run_jobs_enabled,
			dprioprocs => 5,
			iprioprocs => 0,
			procs_per_iobound_type => 0,
			type => "webVideoTranscode",
			timeout => 14400,
			extra_args => "-v 0"
		}

		include applicationserver::config::base,
			applicationserver::packages,
			applicationserver::cron,
			applicationserver::sudo,
			role::applicationserver::configuration::php

		# dependency for wikimedia-task-appserver
		service { 'apache':
			name => "apache2",
			enable => false,
			ensure => stopped;
		}
	}
	class jobrunner( $run_jobs_enabled = true ){
		system::role { "role::applicationserver::jobrunner": description => "Standard Jobrunner Server" }

		class { "role::applicationserver::common": group => "jobrunner" }

		if $::realm == 'production' {
			class { 'mediawiki::jobrunner':
				dprioprocs             => 17,
				iprioprocs             => 6,
				procs_per_iobound_type => 5,
				run_jobs_enabled       => $run_jobs_enabled,
			}
		} else {
			class { 'mediawiki::jobrunner':
				dprioprocs             => 5,
				iprioprocs             => 3,
				procs_per_iobound_type => 2,
				run_jobs_enabled       => $run_jobs_enabled,
			}
		}

		include applicationserver::config::base,
			applicationserver::packages,
			applicationserver::cron,
			applicationserver::sudo,
			role::applicationserver::configuration::php

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

		include applicationserver::config::base,
			applicationserver::packages,
			applicationserver::cron,
			applicationserver::sudo,
			role::applicationserver::configuration::php
	}
}
