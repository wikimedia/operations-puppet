class coredb::snapshot {

	file {
		"/usr/local/sbin/snaprotate.pl":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///modules/coredb/utils/snaprotate.pl"
	}

	if $role::coredb::config::topology[$::shard][snapshot][$::hostname] {
		# TODO: shame. this will stay for now.
		$snaprotate_extraparams = $::hostname ? {
			'db26' => "-c 1",
			default => ""
		}
		cron { snaprotate:
			command => "/usr/local/sbin/snaprotate.pl -a swap -V tank -s data -L 100G $snaprotate_extraparams",
			require => File["/usr/local/sbin/snaprotate.pl"],
			user => root,
			minute => 15,
			hour => '*/8',
			ensure => present;
		}
	} else {
		cron { snaprotate:
			ensure => absent;
		}
	}

}
