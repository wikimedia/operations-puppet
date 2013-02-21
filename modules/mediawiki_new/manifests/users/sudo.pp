# sudo rules for mw deployment
## TODO: rename to just mediawiki::users::sudo after full transition to module
class mediawiki_new::users::sudo {

	require mediawiki_new::users::l10nupdate

	## sudo definitions
	sudo_group {"wikidev_deploy":
		privileges => ['ALL = (mwdeploy,l10nupdate) NOPASSWD: ALL'],
		group => "wikidev"
	}
	sudo_user { "l10nupdate": privileges => ['ALL = (mwdeploy) NOPASSWD: ALL'] }
}
