class snapshot::cirrusjson-dump(
	$enable = true,
	$user   = undef,
) {
	if ($enable == true) {
		$ensure = 'present'
	} else {
		$ensure = 'absent'
	}

	system::role { 'snapshot::cirrussearch':
		ensure      => $ensure,
		description => 'producer of weekly cirrussearch json dumps'
	}

	$scriptPath = '/usr/local/bin/dumpcirrussearch.sh'
	file { $scriptPath:
		mode => '0755',
		owner => 'root',
		group => 'root',
		source => 'puppet:///modules/snapshot/dumpcirrussearch.sh',
	}

	cron { 'cirrussearch-dump':
		ensure      => $ensure,
		command     => "$scriptPath --config ${snapshot::dirs::dumpsdir}/confs/wikidump.conf",
		environment => 'MAILTO=ops-dumps@wikimedia.org',
		user        => $user,
		minute      => '15',
		hour        => '16',
		weekday     => '1',
		require     => File[$scriptPath],
	}
}

