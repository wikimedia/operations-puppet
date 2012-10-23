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
