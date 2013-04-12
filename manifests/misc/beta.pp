class misc::beta::autoupdater {

	require misc::deployment::scripts

	file {
		"/usr/local/bin/wmf-beta-autoupdate":
			owner => root,
			group => root,
			mode => 0555,
			require => [
				#File["/usr/local/bin/mw-update-l10n"],
				Package["git-core"],
			],
			source => "puppet:///files/misc/beta/wmf-beta-autoupdate";
		"/etc/default/wmf-beta-autoupdate":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/misc/beta/wmf-beta-autoupdate.default";
		"/etc/init/wmf-beta-autoupdate.conf":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/upstart/wmf-beta-autoupdate.conf";
		"/var/log/wmf-beta-autoupdate.log":
			owner => mwdeploy,
			group => mwdeploy,
			mode => 0664;
	}

	# Make sure wmf-beta-autoupdate can run the l10n updater as l10nupdate
	sudo_user { "mwdeploy" : privileges => [
		'ALL = (l10nupdate) NOPASSWD:/usr/local/bin/mw-update-l10n',
		'ALL = (l10nupdate) NOPASSWD:/usr/local/bin/mwscript',
		# Some script running as mwdeploy explicily use "sudo -u mwdeploy"
		# which makes Ubuntu to request a password. The following rule
		# make sure we are not going to ask the password to mwdeploy when
		# it tries to identify as mwdeploy.
		'ALL = (mwdeploy) NOPASSWD: ALL',

		# mergeMessageFileList.php is run by mw-update-l10n as the apache user
		# since https://gerrit.wikimedia.org/r/#/c/44548/
		# Let it runs mwscript and others as apache user.
		'ALL = (apache) NOPASSWD: ALL',
	] }


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
