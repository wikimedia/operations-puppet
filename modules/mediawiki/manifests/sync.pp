# mediawiki syncing class
class mediawiki::sync {

	require mediawiki::packages
	require mediawiki::users::l10nupdate

	$scriptpath = $misc::deployment::scap_scripts::scriptpath

	file {
		"${scriptpath}/scap-1":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/scap-1';
		"${scriptpath}/scap-2":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/scap-2';
		"${scriptpath}/sync-common":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/sync-common';
	}

	exec { 'mw-sync':
		command     => "${scriptpath}/sync-common",
		require     => File["${scriptpath}/sync-common"],
		cwd         => '/tmp',
		user        => root,
		group       => root,
		path        => "${scriptpath}:/usr/bin:/usr/sbin",
		refreshonly => true,
		timeout     => 600,
		logoutput   => on_failure;
	}
}

