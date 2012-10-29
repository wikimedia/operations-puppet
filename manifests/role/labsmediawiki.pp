#  Install Mediawiki from git and keep in sync with git trunk
class role::mediawiki-install-latest::labs {

	class { "mediawiki::singlenode":
		keep_up_to_date => true
	}
}

#  Install Mediawiki from git and then leave it alone.
class role::mediawiki-install::labs {

	class { "mediawiki::singlenode":
		keep_up_to_date => false
	}
}

#  Install Wikidata repo (incl. MediaWiki) from git and keep in sync with git trunk
class role::wikidata-repo-latest::labs {

	class { "wikidata::singlenode":
		install_repo	=> true,
		install_client => false,
		keep_up_to_date => true
	}
}

#  Install Wikidata repo (incl. Mediawiki) from git and then leave it alone.
class role::wikidata-repo::labs {

	class { "wikidata::singlenode":
		install_repo	=> true,
		install_client => false,
		keep_up_to_date => false
	}
}

#  Install Wikidata client (incl. MediaWiki) from git and keep in sync with git trunk
class role::wikidata-client-latest::labs {

	class { "wikidata::singlenode":
		install_client	=> true,
		install_repo => false,
		keep_up_to_date => true
	}
}

#  Install Wikidata (incl. Mediawiki) from git and then leave it alone.
class role::wikidata-client::labs {

	class { "wikidata::singlenode":
		install_client  => true,
		install_repo => false,
		keep_up_to_date => false
	}
}
