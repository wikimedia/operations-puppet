# misc/rancid.pp

class misc::rancid {
	# TODO: finish. very incomplete.

	system_role { "misc::rancid": description => "Really Awful Notorious CIsco config Differ (sp)" }

	package { "rancid": ensure => present }
	
	file { "/var/lib/rancid/core":
		require => Package["rancid"],
		owner => rancid,
		group => rancid,
		mode => 0444,
		recurse => remote,
		source => "puppet:///files/misc/rancid/core";
	}
}
