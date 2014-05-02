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
		shared    => true,
		origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/tools/scap.git',
	}

	deployment::target { 'scap': }

	file { '/usr/local/bin/mwversionsinuse':
		ensure  => link,
		target  => '/srv/scap/bin/mwversionsinuse',
		require => Git::Clone['mediawiki/tools/scap'],
	}
	file { '/usr/local/bin/scap-rebuild-cdbs':
		ensure  => link,
		target  => '/srv/scap/bin/scap-rebuild-cdbs',
		require => Git::Clone['mediawiki/tools/scap'],
	}
	file { '/usr/local/bin/scap-recompile':
		ensure  => link,
		target  => '/srv/scap/bin/scap-recompile',
		require => Git::Clone['mediawiki/tools/scap'],
	}
	file { '/usr/local/bin/sync-common':
		ensure  => link,
		target  => '/srv/scap/bin/sync-common',
		require => Git::Clone['mediawiki/tools/scap'],
	}
	file { '/usr/local/bin/refreshCdbJsonFiles':
		ensure  => link,
		target  => '/srv/scap/bin/refreshCdbJsonFiles',
		require => Git::Clone['mediawiki/tools/scap'],
	}

	exec { 'mw-sync':
		command     => '/usr/local/bin/sync-common',
		require     => File['/usr/local/bin/sync-common'],
		cwd         => '/tmp',
		user        => root,
		group       => root,
		path        => '/usr/local/bin:/usr/bin:/usr/sbin',
		refreshonly => true,
		timeout     => 600,
		logoutput   => on_failure;
	}

	exec { 'mw-sync-rebuild-cdbs':
		command     => '/usr/local/bin/scap-rebuild-cdbs',
		cwd         => '/tmp',
		user        => 'mwdeploy',
		group       => 'mwdeploy',
		path        => '/usr/local/bin:/usr/bin:/usr/sbin',
		refreshonly => true,
		timeout     => 600,
		logoutput   => on_failure,
		require     => File['/usr/local/bin/scap-rebuild-cdbs'],
		subscribe   => Exec['mw-sync'],
	}
}
