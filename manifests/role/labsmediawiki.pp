#  Install Mediawiki from git and keep in sync with git trunk
#
#  Uses the mediawiki::singlenode class with minimal alterations or customizations.
class role::mediawiki-install-latest::labs {

	class { "mediawiki::singlenode":
		ensure => latest
	}
}

#  Install Mediawiki from git and then leave it alone.
#
#  Uses the mediawiki::singlenode class with no alterations or customizations.
class role::mediawiki-install::labs {

	class { "mediawiki::singlenode":
		ensure => present
	}
}

#  Install Wikidata repo (incl. MediaWiki) from git and keep in sync with git trunk
class role::wikidata-repo-latest::labs {

	class { "wikidata::singlenode":
		install_repo => true,
		install_client => false,
		ensure => latest,
		# require_once stuff for repo
		role_requires => [ '"$IP/extensions/Diff/Diff.php"', '"$IP/extensions/DataValues/DataValues.php"', '"$IP/extensions/UniversalLanguageSelector/UniversalLanguageSelector.php"', '"$IP/extensions/Wikibase/lib/WikibaseLib.php"', '"$IP/extensions/Wikibase/repo/Wikibase.php"', '"$IP/extensions/Wikibase/repo/ExampleSettings.php"' ],
		# additional config lines
		role_config_lines => [ '$wgShowExceptionDetails = true' ]
	}
}

#  Install Wikidata repo (incl. Mediawiki) from git and then leave it alone.
class role::wikidata-repo::labs {

	class { "wikidata::singlenode":
		install_repo => true,
		install_client => false,
		ensure => present,
		role_requires => [ '"$IP/extensions/Diff/Diff.php"', '"$IP/extensions/DataValues/DataValues.php"', '"$IP/extensions/UniversalLanguageSelector/UniversalLanguageSelector.php"', '"$IP/extensions/Wikibase/lib/WikibaseLib.php"', '"$IP/extensions/Wikibase/repo/Wikibase.php"', '"$IP/extensions/Wikibase/repo/ExampleSettings.php"' ],
		# additional config lines
		role_config_lines => [ '$wgShowExceptionDetails = true' ]
	}
}

#  Install Wikidata client (incl. MediaWiki) from git and keep in sync with git trunk
class role::wikidata-client-latest::labs {

	class { "wikidata::singlenode":
		install_client => true,
		install_repo => false,
		ensure => latest,
		role_requires => [ '"$IP/extensions/Diff/Diff.php"', '"$IP/extensions/DataValues/DataValues.php"', '"$IP/extensions/UniversalLanguageSelector/UniversalLanguageSelector.php"', '"$IP/extensions/Wikibase/lib/WikibaseLib.php"', '"$IP/extensions/Wikibase/client/WikibaseClient.php"' ],
		# additional config lines
		role_config_lines => [ '$wgShowExceptionDetails = true', '$wgWBSettings[\'namespaces\'] = array( NS_MAIN, NS_CATEGORY )', '$wgWBSettings[\'siteGroup\'] = \'wiki\'', '$wgWBSettings[\'sort\'] = \'code\'' ]
	}
}

#  Install Wikidata (incl. Mediawiki) from git and then leave it alone.
class role::wikidata-client::labs {

	class { "wikidata::singlenode":
		install_client => true,
		install_repo => false,
		ensure => present,
		role_requires => [ '"$IP/extensions/Diff/Diff.php"', '"$IP/extensions/DataValues/DataValues.php"', '"$IP/extensions/UniversalLanguageSelector/UniversalLanguageSelector.php"', '"$IP/extensions/Wikibase/lib/WikibaseLib.php"', '"$IP/extensions/Wikibase/client/WikibaseClient.php"' ],
		# additional config lines
		role_config_lines => [ '$wgShowExceptionDetails = true', '$wgWBSettings[\'namespaces\'] = array( NS_MAIN, NS_CATEGORY )', '$wgWBSettings[\'siteGroup\'] = \'wiki\'', '$wgWBSettings[\'sort\'] = \'code\'' ]
	}
}
