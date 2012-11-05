class role::beta::autoupdater {

	include misc::beta::autoupdater

	system_role { 'role::beta::autoupdater':
		description => 'Server is autoupdating MediaWiki core and extension on beta.'
	}

}
