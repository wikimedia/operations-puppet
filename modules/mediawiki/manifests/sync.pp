# mediawiki syncing class
class mediawiki::sync {

	include misc::deployment::vars

	require mediawiki::packages
	require mediawiki::users::l10nupdate

	deployment::target { 'scap': }

	$scriptpath = '/usr/local/bin'
	$scap_install_dir = '/srv/deployment/scap/scap/bin'

	file { "${scriptpath}/mwversionsinuse":
		ensure  => link,
		target  => "${scap_install_dir}/mwversionsinuse",
	}
	file { "${scriptpath}/scap-rebuild-cdbs":
		ensure  => link,
		target  => "${scap_install_dir}/scap-rebuild-cdbs",
	}
	file { "${scriptpath}/scap-recompile":
		ensure  => link,
		target  => "${scap_install_dir}/scap-recompile",
	}
	file { "${scriptpath}/sync-common":
		ensure  => link,
		target  => "${scap_install_dir}/sync-common",
	}
	file { "${scriptpath}/refreshCdbJsonFiles":
		ensure  => link,
		target  => "${scap_install_dir}/refreshCdbJsonFiles",
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

	exec { 'mw-sync-rebuild-cdbs':
		command     => "${scriptpath}/scap-rebuild-cdbs",
		cwd         => '/tmp',
		user        => 'mwdeploy',
		group       => 'mwdeploy',
		path        => "${scriptpath}:/usr/bin:/usr/sbin",
		refreshonly => true,
		timeout     => 600,
		logoutput   => on_failure,
		require     => File["${scriptpath}/scap-rebuild-cdbs"],
		subscribe   => Exec['mw-sync'],
	}
}
