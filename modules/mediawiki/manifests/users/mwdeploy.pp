# mediawiki base mw deploy user
class mediawiki::users::mwdeploy {
	## mwdeploy user
	generic::systemuser { 'mwdeploy': name => 'mwdeploy' }
}
