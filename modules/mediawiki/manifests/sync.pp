# mediawiki syncing class
class mediawiki::sync {

  require mediawiki::packages
  require mediawiki::users::l10nupdate

	exec { 'mw-sync':
		command => '/usr/bin/sync-common',
		cwd => '/tmp',
		user => root,
		group => root,
		path => '/usr/bin:/usr/sbin',
		refreshonly => true,
		timeout => 600,
		logoutput => on_failure;
	}
}

