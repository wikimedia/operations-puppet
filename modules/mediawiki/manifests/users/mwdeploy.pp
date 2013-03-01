# mediawiki base mw deploy user
class mediawiki::users::mwdeploy {
	## mwdeploy user
	systemuser { 'mwdeploy': name => 'mwdeploy' }
}
