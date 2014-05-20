#  Install Mediawiki from git and keep in sync with git trunk
#
#  Uses the mediawiki_singlenode class with minimal alterations or customizations.
class role::mediawiki-install-latest::labs {

    class { "mediawiki_singlenode":
        ensure => latest
    }
}

#  Install Mediawiki from git and then leave it alone.
#
#  Uses the mediawiki_singlenode class with no alterations or customizations.
class role::mediawiki-install::labs {

    class { "mediawiki_singlenode":
        ensure => present
    }
}
