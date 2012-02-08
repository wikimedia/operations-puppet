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
	class configuration {
		$active_nodes = {
			"text" => {
				"pmtpa" => [
					'sq31.wikimedia.org',   # API
					'sq33.wikimedia.org',   # API
					'sq34.wikimedia.org',   # API
					'sq35.wikimedia.org',   # API
					'sq36.wikimedia.org',   # API
					'sq37.wikimedia.org',
					'sq38.wikimedia.org',
					'sq39.wikimedia.org',
					'sq40.wikimedia.org',

					'sq59.wikimedia.org',
					'sq60.wikimedia.org',
					'sq61.wikimedia.org',
					'sq62.wikimedia.org',
					'sq63.wikimedia.org',
					'sq64.wikimedia.org',
					'sq65.wikimedia.org',
					'sq66.wikimedia.org',

					'sq71.wikimedia.org',
					'sq72.wikimedia.org',
					'sq73.wikimedia.org',
					'sq74.wikimedia.org',
					'sq75.wikimedia.org',
					'sq76.wikimedia.org',
					'sq77.wikimedia.org',
					'sq78.wikimedia.org',
					],
				"eqiad" => [
					'cp1001.eqiad.wmnet',
					'cp1002.eqiad.wmnet',
					'cp1003.eqiad.wmnet',
					'cp1004.eqiad.wmnet',
					'cp1005.eqiad.wmnet',
					'cp1006.eqiad.wmnet',
					'cp1007.eqiad.wmnet',
					'cp1008.eqiad.wmnet',
					'cp1009.eqiad.wmnet',
					'cp1010.eqiad.wmnet',
					'cp1011.eqiad.wmnet',
					'cp1012.eqiad.wmnet',
					'cp1013.eqiad.wmnet',
					'cp1014.eqiad.wmnet',
					'cp1015.eqiad.wmnet',
					'cp1016.eqiad.wmnet',
					'cp1017.eqiad.wmnet',
					'cp1018.eqiad.wmnet',
					'cp1019.eqiad.wmnet',
					'cp1020.eqiad.wmnet',
				],
				"esams" => [
					"knsq23.esams.wikimedia.org",
					"knsq24.esams.wikimedia.org",
					"knsq25.esams.wikimedia.org",
					"knsq26.esams.wikimedia.org",
					"knsq27.esams.wikimedia.org",
					"knsq28.esams.wikimedia.org",
					"knsq29.esams.wikimedia.org",

					"amssq31.esams.wikimedia.org",
					"amssq32.esams.wikimedia.org",
					"amssq33.esams.wikimedia.org",
					"amssq34.esams.wikimedia.org",
					"amssq35.esams.wikimedia.org",
					"amssq36.esams.wikimedia.org",
					"amssq37.esams.wikimedia.org",
					"amssq38.esams.wikimedia.org",
					"amssq39.esams.wikimedia.org",
					"amssq40.esams.wikimedia.org",
					"amssq41.esams.wikimedia.org",
					"amssq42.esams.wikimedia.org",
					"amssq43.esams.wikimedia.org",
					"amssq44.esams.wikimedia.org",
					"amssq45.esams.wikimedia.org",
					"amssq46.esams.wikimedia.org",
					]
			},
			"bits" => {
				"pmtpa" => [],
				"eqiad" => [],
				"esams" => [],
			},
			"upload" => {
				"pmtpa" => [
					'sq41.wikimedia.org',
					'sq42.wikimedia.org',
					'sq43.wikimedia.org',
					'sq44.wikimedia.org',
					'sq45.wikimedia.org',
					'sq46.wikimedia.org',
					'sq47.wikimedia.org',
					'sq48.wikimedia.org',
					'sq49.wikimedia.org',
					'sq50.wikimedia.org',

					'sq51.wikimedia.org',
					'sq52.wikimedia.org',
					'sq53.wikimedia.org',
					'sq54.wikimedia.org',
					'sq55.wikimedia.org',
					'sq56.wikimedia.org',
					'sq57.wikimedia.org',
					'sq58.wikimedia.org',

					'sq79.wikimedia.org',
					'sq80.wikimedia.org',
					'sq81.wikimedia.org',
					'sq82.wikimedia.org',
					'sq83.wikimedia.org',
					'sq84.wikimedia.org',
					'sq85.wikimedia.org',
					'sq86.wikimedia.org',
				],
				"eqiad" => [
					'cp1021.eqiad.wmnet',
					'cp1022.eqiad.wmnet',
					'cp1023.eqiad.wmnet',
					'cp1024.eqiad.wmnet',
					'cp1025.eqiad.wmnet',
					'cp1026.eqiad.wmnet',
					'cp1027.eqiad.wmnet',
					'cp1028.eqiad.wmnet',
					'cp1029.eqiad.wmnet',
					'cp1030.eqiad.wmnet',
					'cp1031.eqiad.wmnet',
					'cp1032.eqiad.wmnet',
					'cp1033.eqiad.wmnet',
					'cp1034.eqiad.wmnet',
					'cp1035.eqiad.wmnet',
					'cp1036.eqiad.wmnet',
					'cp1037.eqiad.wmnet',
					'cp1038.eqiad.wmnet',
					'cp1039.eqiad.wmnet',
					'cp1040.eqiad.wmnet'
				],
				"esams" => [
					'knsq16.knams.wikimedia.org',
					'knsq17.knams.wikimedia.org',
					'knsq18.knams.wikimedia.org',
					'knsq19.knams.wikimedia.org',
					'knsq20.knams.wikimedia.org',
					'knsq21.knams.wikimedia.org',
					'knsq22.knams.wikimedia.org',

					'amssq47.esams.wikimedia.org',
					'amssq48.esams.wikimedia.org',
					'amssq49.esams.wikimedia.org',
					'amssq50.esams.wikimedia.org',
					'amssq51.esams.wikimedia.org',
					'amssq52.esams.wikimedia.org',
					'amssq53.esams.wikimedia.org',
					'amssq54.esams.wikimedia.org',
					'amssq55.esams.wikimedia.org',
					'amssq56.esams.wikimedia.org',
					'amssq57.esams.wikimedia.org',
					'amssq58.esams.wikimedia.org',
					'amssq59.esams.wikimedia.org',
					'amssq60.esams.wikimedia.org',
					'amssq61.esams.wikimedia.org',
					'amssq62.esams.wikimedia.org',
				],
			}
		}

		$decommissioned_nodes = {
			"text" => {
				"pmtpa" => ["sq32.wikimedia.org"],
				"eqiad" => [],
				"esams" => ["knsq30.esams.wikimedia.org"]
			},
			"bits" => {
				"pmtpa" => [],
				"eqiad" => [],
				"esams" => [],
			},
			"upload" => {
				"pmtpa" => [],
				"eqiad" => [],
				"esams" => [],
			},
		}
	}

	class squid {
		class common($role) {
			system_role { "role::cache::${role}": description => "${role} Squid cache server"}

			$cluster = "squids_${role}"
			$nagios_group = "cache_${role}_${::site}"

			include lvs::configuration

			include	standard,
				::squid
			
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
