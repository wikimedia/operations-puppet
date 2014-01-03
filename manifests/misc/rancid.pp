# misc/rancid.pp

class misc::rancid {
	# TODO: finish. very incomplete.

	system::role { "misc::rancid": description => "Really Awful Notorious CIsco config Differ (sp)" }

	package { "rancid": ensure => present }

	generic::systemuser { 'rancid':
		name => 'rancid'
	}

	file { '/etc/rancid/rancid.conf':
		require => Package['rancid'],
		owner => root,
		group => root,
		mode => 0444,
		source => 'puppet:///files/misc/rancid/rancid.conf'
	}

	file { "/var/lib/rancid/core":
		require => [ Package["rancid"], Generic::Systemuser['rancid'] ],
		owner => rancid,
		group => rancid,
		mode => 0550,
		recurse => remote,
		source => "puppet:///files/misc/rancid/core";
	}

	file { '/etc/cron.d/rancid':
		require => File['/var/lib/rancid/core'],
		owner => root,
		group => root,
		mode => 0444,
		source => 'puppet:///files/misc/rancid/rancid.cron'
	}

	file { '/var/log/rancid':
		owner => rancid,
		group => rancid,
		mode => 0550
	}
}
