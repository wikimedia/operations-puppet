class role::cache {
	class squid {
		class text {
			system_role { "role::cache::squid::text": description => "text Squid server" }

			$cluster = "squids_text"

			include lvs::configuration

			# FIXME: make coherent with $cluster
			$nagios_group = $site ? {
				'pmtpa' => 'squids_text',
				'esams' => 'squids_esams_text',
				'eqiad' => 'squids_eqiad_text'
			}

			include	standard,
				squid
			
			class { "lvs::realserver": realserver_ips => $lvs::configuration::lvs_service_ips[$::realm][text][$::site]

			# HTCP packet loss monitoring on the ganglia aggregators
			if $ganglia_aggregator == "true" and $site != "esams" {
				include misc::monitoring::htcp-loss
			}
		}

		class upload {
			system_role { "role::cache::squid::upload": description => "upload Squid server" }

			$cluster = "squids_upload"

			include lvs::configuration

			# FIXME: make coherent with $cluster
			$nagios_group = $site ? {
				'pmtpa' => 'squids_upload',
				'esams' => 'squids_esams_upload'
			}

			include standard,
				squid

			class { "lvs::realserver": realserver_ips => $lvs::configuration::lvs_service_ips[$::realm][upload][$::site]

			# HTCP packet loss monitoring on the ganglia aggregators
			if $ganglia_aggregator == "true" and $site != "esams" {
				include misc::monitoring::htcp-loss
			}
		}
	}
}
