class misc::beta::scripts {

	require misc::deployment::scripts

	file {
		"/usr/local/bin/wmf-beta-autoupdate":
			owner => root,
			group => root,
			mode => 0555,
			require => File["/usr/local/bin/mw-update-l10n"],
			source => "puppet:///files/misc/beta/wmf-beta-autoupdate";
		"/etc/default/wmf-beta-autoupdate":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/misc/beta/wmf-beta-autoupdate.default";
	}

	# Make sure wmf-beta-autoupdate can run the l10n updater as l10nupdate
	sudo_user { "mwdeploy" : privileges => ['ALL = (l10nupdate) NOPASSWD:/usr/local/bin/mw-update-l10n'] }

	upstart_job { "wmf-beta-autoupdate": install => true }

	service { "wmf-beta-autoupdate":
		require => [
			File["/usr/local/bin/wmf-beta-autoupdate"],
			Upstart_job["wmf-beta-autoupdate"],
			Systemuser["mwdeploy"],
		],
		subscribe => [
			File["/etc/default/wmf-beta-autoupdate"],
			File["/usr/local/bin/wmf-beta-autoupdate"],
		],
		provider => upstart,
		ensure => running;
	}

}
