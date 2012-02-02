class role::cache {
	class squid {
		class text {
			system_role { "role::cache::squid::text": description => "text Squid server" }

			$cluster = "squids_text"

			if ! $lvs_realserver_ips {
				include lvs::configuration
		
				$sip = $lvs::configuration::lvs_service_ips[$::realm][text][$::site]

				$lvs_realserver_ips = [
					$sip['textsvc'],
					$sip['wikimedialb'],
					$sip['wikipedialb'],
					$sip['wiktionarylb'],
					$sip['wikiquotelb'],
					$sip['wikibookslb'],
					$sip['wikisourcelb'],
					$sip['wikinewslb'],
					$sip['wikiversitylb'],
					$sip['mediawikilb'],
					$sip['foundationlb']
				]
			}

			# FIXME: make coherent with $cluster
			$nagios_group = $site ? {
				'pmtpa' => 'squids_text',
				'esams' => 'squids_esams_text',
				'eqiad' => 'squids_eqiad_text'
			}

			include	standard,
				squid,
				lvs::realserver

			# HTCP packet loss monitoring on the ganglia aggregators
			if $ganglia_aggregator == "true" and $site != "esams" {
				include misc::monitoring::htcp-loss
			}
		}

		class upload {
			system_role { "role::cache::squid::upload": description => "upload Squid server" }

			$cluster = "squids_upload"

			if ! $lvs_realserver_ips {
				include lvs::configuration

				$sip = $lvs::configuration::lvs_service_ips[$::realm][upload][$::site]
				
				$lvs_realserver_ips = [ $sip['uploadsvc'], $sip['uploadlb'] ]
			}

			# FIXME: make coherent with $cluster
			$nagios_group = $site ? {
				'pmtpa' => 'squids_upload',
				'esams' => 'squids_esams_upload'
			}

			include standard,
				squid,
				lvs::realserver

			# HTCP packet loss monitoring on the ganglia aggregators
			if $ganglia_aggregator == "true" and $site != "esams" {
				include misc::monitoring::htcp-loss
			}
		}
	}
}
