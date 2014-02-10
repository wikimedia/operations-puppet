# mediawiki syncing class
class mediawiki::sync {

	include misc::deployment::vars

	require mediawiki::packages
	require mediawiki::users::l10nupdate

	git::clone { 'mediawiki/tools/scap':
		ensure    => 'latest',
		directory => '/srv/scap',
		owner     => 'root',
		group     => 'wikidev',
		mode      => '0775',
		origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/tools/scap.git',
	}

	$scriptpath = "/usr/local/bin"

	file {
		"${scriptpath}/find-nearest-rsync":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/find-nearest-rsync';
		"${scriptpath}/mwversionsinuse":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/mwversionsinuse';
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
		"${scriptpath}/scap-rebuild-cdbs":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/scap-rebuild-cdbs';
		"${scriptpath}/scap-recompile":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/scap-recompile';
		"${scriptpath}/sync-common":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/sync-common';
		"${scriptpath}/mergeCdbFileUpdates":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/mergeCdbFileUpdates';
		"${scriptpath}/refreshCdbJsonFiles":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/refreshCdbJsonFiles';

		# Fix $scriptpath screwup
		"/scap-1": ensure => absent;
		"/scap-2": ensure => absent;
		"/sync-common": ensure => absent;
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

