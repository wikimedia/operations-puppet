# sudo rules for mw deployment
class mediawiki::users::sudo {

	require mediawiki::users::l10nupdate

	## sudo definitions
	sudo_group {"wikidev_deploy":
		privileges => ['ALL = (apache,mwdeploy,l10nupdate) NOPASSWD: ALL',
			'ALL = (root) NOPASSWD: /sbin/restart twemproxy'],
		group => "wikidev"
	}
	sudo_user { "l10nupdate": privileges => ['ALL = (mwdeploy) NOPASSWD: ALL'] }
}
