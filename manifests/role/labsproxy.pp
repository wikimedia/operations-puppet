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

	file {
		"/var/www":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0555;
		"/var/www/robots.txt":
			ensure => present,
			require => file["/var/www"],
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/misc/robots-txt-disallow";
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

	file {
		"/var/www":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0555;
		"/var/www/robots.txt":
			ensure => present,
			require => file["/var/www"],
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/misc/robots-txt-disallow";
	}
}
