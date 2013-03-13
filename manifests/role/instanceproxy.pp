#  Install Mediawiki from git and keep in sync with git trunk
#
#  Uses the mediawiki_singlenode class with minimal alterations or customizations.
class role::instance-proxy {

	nginx { "labs-instance-proxy":
		install => "true"
	}
}
