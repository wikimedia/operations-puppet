class role::cache {
	class squid {
		class common($role) {
			system_role { "role::cache::squid::${role}": description => "${role} Squid server"}

			$cluster = "squids_${role}"

			include lvs::configuration

			# FIXME: make coherent with $cluster
			$nagios_group = $site ? {
				'pmtpa' => 'squids_${role}',
				'esams' => 'squids_esams_${role}',
				'eqiad' => 'squids_eqiad_${role}'
			}

			include	standard,
				squid
			
			class { "lvs::realserver": realserver_ips => $lvs::configuration::lvs_service_ips[$::realm][$role][$::site] }

			# HTCP packet loss monitoring on the ganglia aggregators
			if $ganglia_aggregator == "true" and $site != "esams" {
				include misc::monitoring::htcp-loss
			}

		}

		class text {
			class { "role::cache::squid::common": role => "text" }
		}

		class upload {
			class { "role::cache::squid::common": role => "upload" }
		}
	}
}
