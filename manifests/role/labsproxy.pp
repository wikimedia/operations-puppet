#  Install an http proxy for pmtpa labs instances.
#
#  If this is installed, addresses like foo.pmtpa-proxy.wmflabs.org will
#  be directed to foo.pmtpa.wmflabs.
class role::pmtpa-proxy {

	$proxy_hostname = "pmtpa-proxy"
	$proxy_internal_domain = "pmtpa.wmflabs"

	nginx { "pmtpa-labs-proxy":
		install => "template",
		template => "labs-proxy";
	}
}

#  Install an http proxy for eqiad labs instances.
#
#  If this is installed, addresses like foo.eqiad-proxy.wmflabs.org will
#  be directed to foo.eqiad.wmflabs.
class role::eqiad-proxy {

	$proxy_hostname = "eqiad-proxy"
	$proxy_internal_domain = "eqiad.wmflabs"

	nginx { "eqiad-labs-proxy":
		install => "template",
		template => "labs-proxy";
	}
}
