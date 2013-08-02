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

# A dynamic HTTP routing proxy, based on nginx+lua+redis
class role::proxy-project {
    class { '::redis':
        persist   => "aof",
        dir       => "/var/lib/redis",
        maxmemory => "512MB",
        monitor   => true
    }

    package { 'nginx-extras': }

    file { '/etc/nginx/sites-available/default':
        ensure  => 'file',
        source  => 'puppet:///files/nginx/labs/proxy.conf',
        require => Package['nginx-extras'],
        notify  => Service['nginx']
    }

    file { '/etc/nginx/proxy.lua':
        ensure  => 'file',
        source  => 'puppet:///files/nginx/labs/proxy.lua',
        require => Package['nginx-extras'],
        notify  => Service['nginx']
    }
}
