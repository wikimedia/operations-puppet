# role/cache.pp
# cache::squid and cache::varnish role classes

# Virtual resources for the monitoring server
@monitor_group { "cache_text_pmtpa": description => "text squids pmtpa" }
@monitor_group { "cache_text_eqiad": description => "text squids eqiad" }
@monitor_group { "cache_text_esams": description => "text squids esams" }

@monitor_group { "cache_upload_pmtpa": description => "upload squids pmtpa" }
@monitor_group { "cache_upload_eqiad": description => "upload squids eqiad" }
@monitor_group { "cache_upload_esams": description => "upload squids esams" }

class role::cache {
	class squid {
		class common($role) {
			system_role { "role::cache::${role}": description => "${role} Squid cache server"}

			$cluster = "squids_${role}"
			$nagios_group = "cache_${role}_${::site}"

			include lvs::configuration

			include	standard,
				squid
			
			class { "lvs::realserver": realserver_ips => $lvs::configuration::lvs_service_ips[$::realm][$role][$::site] }

			# Monitoring
			monitor_service {
				"frontend http":
					description => "Frontend Squid HTTP",
					check_command => $role ? {
						text => 'check_http',
						upload => 'check_http_upload',
					};
				"backend http":
					description => "Backend Squid HTTP",
					check_command => $role ? {
						text => 'check_http_on_port!3128',
						upload => 'check_http_upload_on_port!3128',
					};
			}

			# HTCP packet loss monitoring on the ganglia aggregators
			if $ganglia_aggregator == "true" and $::site != "esams" {
				include misc::monitoring::htcp-loss
			}
		}
	}

	class text {
		class { "role::cache::squid::common": role => "text" }
	}

	class upload {
		class { "role::cache::squid::common": role => "upload" }
	}

	class bits {
		$cluster = "cache_bits"
		$nagios_group = "cache_bits_${::site}"

		$lvs_realserver_ips = $::site ? {
			"pmtpa" => [ "208.80.152.210", "10.2.1.23" ],
			"eqiad" => [ "208.80.154.234", "10.2.2.23" ],
			"esams" => [ "91.198.174.233", "10.2.3.23" ],
		}

		$bits_appservers = [ "srv191.pmtpa.wmnet", "srv192.pmtpa.wmnet", "srv248.pmtpa.wmnet", "srv249.pmtpa.wmnet", "mw60.pmtpa.wmnet", "mw61.pmtpa.wmnet" ]
		$test_wikipedia = [ "srv193.pmtpa.wmnet" ]
		$all_backends = [ "srv191.pmtpa.wmnet", "srv192.pmtpa.wmnet", "srv248.pmtpa.wmnet", "srv249.pmtpa.wmnet", "mw60.pmtpa.wmnet", "mw61.pmtpa.wmnet", "srv193.pmtpa.wmnet" ]

		$varnish_backends = $::site ? {
			/^(pmtpa|eqiad)$/ => $all_backends,
			# [ bits-lb.pmtpa, bits-lb.eqiad ]
			#'esams' => [ "208.80.152.210", "208.80.154.234" ],
			# FIXME: add pmtpa back in
			'esams' => [ "208.80.154.234" ],
			default => []
		}

		# FIXME: stupid hack to unbreak hashes-in-selectors in puppet 2.7
		$multiple_backends = {
			'pmtpa-eqiad' => {
				"backend" => $bits_appservers,
				"test_wikipedia" => $test_wikipedia
				},
			'esams' => {
				"backend" => $varnish_backends,
			}
		}

		$varnish_directors = $::site ? {
			/^(pmtpa|eqiad)$/ => $multiple_backends["pmtpa-eqiad"],
			'esams' => $multiple_backends["esams"],
		}

		$varnish_xff_sources = [ { "ip" => "208.80.152.0", "mask" => "22" }, { "ip" => "91.198.174.0", "mask" => "24" } ]

		system_role { "role::cache::bits": description => "bits Varnish cache server" }
		system_role { "cache::bits": description => "bits Varnish cache server", ensure => absent }

		require generic::geoip::files

		include standard,
			lvs::realserver,
			varnish::monitoring::ganglia

		varnish::instance { "bits":
			name => "",
			vcl => "bits",
			port => 80,
			admin_port => 6082,
			storage => "-s malloc,1G",
			backends => $varnish_backends,
			directors => $varnish_directors,
			backend_options => {
				'port' => 80,
				'connect_timeout' => "5s",
				'first_byte_timeout' => "35s",
				'between_bytes_timeout' => "4s",
				'max_connections' => 10000,
				'probe' => "bits",
				'retry5x' => 1
			},
			enable_geoiplookup => "true"
		}
	}

	class mobile {
		$cluster = "cache_mobile"
		$nagios_group = "cache_mobile_${::site}"

		monitor_service { "varnishncsa": description => "mobile traffic loggers",
			check_command => "nrpe_check_varnishncsa" }

		$lvs_realserver_ips = $::site ? {
			'eqiad' => [ "208.80.154.236", "10.2.2.26" ],
			default => [ ]
		}

		$varnish_fe_backends = $::site ? {
			"eqiad" => [ "cp1041.wikimedia.org", "cp1042.wikimedia.org",
				"cp1043.wikimedia.org", "cp1044.wikimedia.org" ],
			default => []
		}
		$varnish_fe_directors = {
			"pmtpa" => {},
			"eqiad" => { "backend" => $varnish_fe_backends },
			"esams" => {},
		}

		$varnish_xff_sources = [ { "ip" => "208.80.152.0", "mask" => "22" } ]

		system_role { "role::cache::mobile": description => "mobile Varnish cache server" }
		system_role { "cache::mobile": description => "mobile Varnish cache server", ensure => absent }

		include standard,
			varnish::htcpd,
			varnish::logging,
			varnish::monitoring::ganglia,
			lvs::realserver,
			nrpe

		varnish::instance { "mobile-backend":
			name => "",
			vcl => "mobile-backend",
			port => 81,
			admin_port => 6083,
			storage => "-s file,/a/sda/varnish.persist,50% -s file,/a/sdb/varnish.persist,50%",
			backends => [ "10.2.1.1" ],
			directors => { "backend" => [ "10.2.1.1" ] },
			backend_options => {
				'port' => 80,
				'connect_timeout' => "5s",
				'first_byte_timeout' => "35s",
				'between_bytes_timeout' => "4s",
				'max_connections' => 1000,
				'probe' => "bits",
				'retry5x' => 1
				},
		}

		varnish::instance { "mobile-frontend":
			name => "frontend",
			vcl => "mobile-frontend",
			port => 80,
			admin_port => 6082,
			backends => $varnish_fe_backends,
			directors => $varnish_fe_directors[$::site],
			backend_options => {
				'port' => 81,
				'connect_timeout' => "5s",
				'first_byte_timeout' => "35s",
				'between_bytes_timeout' => "2s",
				'max_connections' => 100000,
				'probe' => "varnish",
				'retry5x' => 0
				},
		}
	}
}
