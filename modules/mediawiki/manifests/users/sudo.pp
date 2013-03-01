# sudo rules for mw deployment
class mediawiki::users::sudo {

	require mediawiki::users::l10nupdate

	## sudo definitions
	sudo_group {"wikidev_deploy":
		privileges => ['ALL = (mwdeploy,l10nupdate) NOPASSWD: ALL'],
		group => "wikidev"
	}
	sudo_user { "l10nupdate": privileges => ['ALL = (mwdeploy) NOPASSWD: ALL'] }
}
