class misc::beta::scripts {

	file {
		"/usr/local/bin/wmf-beta-autoupdate":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/beta/wmf-beta-autoupdate";
		"/etc/default/wmf-beta-autoupdate":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/misc/beta/wmf-beta-autoupdate.default";
	}

	upstart_job { "wmf-beta-autoupdate": install => true }

	service { "wmf-beta-autoupdate":
		require => [
			File["/usr/local/bin/wmf-beta-autoupdate"],
			Upstart_job["wmf-beta-autoupdate"],
		],
		subscribe => [
			File["/etc/default/wmf-beta-autoupdate"],
			File["/usr/local/bin/wmf-beta-autoupdate"],
		],
		provider => upstart,
		ensure => running;
	}

}
