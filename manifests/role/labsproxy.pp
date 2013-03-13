#  Install an http proxy for pmtpa labs instances.
#
#  If this is installed, addresses like foo.pmtpa-proxy.wmflabs.org will
#  be directed to foo.pmtpa.wmflabs.
class role::pmtpa-proxy {
	nginx { "pmtpa-labs-proxy":
		install => "true"
	}
}

#  Install an http proxy for eqiad labs instances.
#
#  If this is installed, addresses like foo.eqiad-proxy.wmflabs.org will
#  be directed to foo.eqiad.wmflabs.
class role::eqiad-proxy {
	nginx { "eqiad-labs-proxy":
		install => "true"
	}
}
