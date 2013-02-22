# mediawiki syncing class
## TODO: rename to just mediawiki::sync after full transition to module
class mediawiki_new::sync {

  require mediawiki_new::packages
  require mediawiki_new::users::l10nupdate

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

