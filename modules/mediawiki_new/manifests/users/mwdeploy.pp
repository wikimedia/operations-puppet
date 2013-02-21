# mediawiki base mw deploy user
## TODO: rename to just mediawiki::users::mwdeploy after full transition to module
class mediawiki_new::users::mwdeploy {
	## mwdeploy user
	systemuser { 'mwdeploy': name => 'mwdeploy' }
}
