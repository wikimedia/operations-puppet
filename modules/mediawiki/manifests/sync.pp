# mediawiki syncing class
class mediawiki::sync {

	require mediawiki::packages
	require mediawiki::users::l10nupdate

	if $::realm == 'labs' {
		file { '/usr/local/apache':
			ensure => link,
			target => '/data/project/apache',
			# Create link before wikimedia-task-appserver attempts
			# to create /usr/local/apache/common.
			before => Package['wikimedia-task-appserver'],
		}
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
		"${scriptpath}/scap-1skins":
			owner  => root,
			group  => root,
			mode   => '0555',
			source => 'puppet:///files/scap/scap-1skins';
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

