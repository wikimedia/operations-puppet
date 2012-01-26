class role::cache::squid::text {
	system_role { "role::cache::squid::text": description => "text Squid server" }

	$cluster = "squids_text"

	if ! $lvs_realserver_ips {
		$sip = $lvs::configuration::lvs_service_ips['production']['text'][$site]

		$lvs_realserver_ips = $realm ? {
			'production' => $site ? {
			 	'pmtpa' => [ "208.80.152.2", "208.80.152.200", "208.80.152.201", "208.80.152.202", "208.80.152.203", "208.80.152.204", "208.80.152.205", "208.80.152.206", "208.80.152.207", "208.80.152.208", "208.80.152.209", "10.2.1.25" ],
				'eqiad' => [ $sip['wikimedialb'], $sip['wikipedialb'], $sip['wiktionarylb'], $sip['wikiquotelb'], $sip['wikibookslb'],  $sip['wikisourcelb'], $sip['wikinewslb'], $sip['wikiversitylb'], $sip['mediawikilb'], $sip['foundationlb'] ],
				'esams' => [ "91.198.174.232", "91.198.174.233", "91.198.174.224", "91.198.174.225", "91.198.174.226", "91.198.174.227", "91.198.174.228", "91.198.174.229", "91.198.174.230", "91.198.174.231", "91.198.174.235", "10.2.3.25" ]
			},
			# TODO: add text svc address
			'labs' => $site ? {
			 	'pmtpa' => [ "208.80.153.193", "208.80.153.197", "208.80.153.198", "208.80.153.199", "208.80.153.200", "208.80.153.201", "208.80.153.202", "208.80.153.203", "208.80.153.204", "208.80.153.205" ],
				'eqiad' => [ "" ],
				'esams' => [ "" ]
			}
		}
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
