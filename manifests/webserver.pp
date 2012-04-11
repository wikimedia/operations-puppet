# This file is for all generic web server classes
# Apache, php, etc belong in here
# Specific services (racktables, etherpad) do not


# Installs a generic, static web server (lighttpd) with default config, which serves /var/www
class webserver::static {
	include generic::sysctl::high-http-performance

	package { lighttpd:
		ensure => latest;
	}

	service { lighttpd:
		ensure => running,
		hasstatus => $::lsbdistcodename ? {
			'hardy' => false,
			default => true
		}
	}

	# Monitoring
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
}

class webserver::php5( $ssl = 'false' ) {
	#This will use latest package for php5-common

	include generic::sysctl::high-http-performance

	package { [ "apache2", "libapache2-mod-php5" ]:
		ensure => latest;
	}

	if $ssl == 'true' {
		apache_module { ssl: name => "ssl" }
	}

	service { apache2:
		require => Package[apache2],
		subscribe => Package[libapache2-mod-php5],
		ensure => running;
	}

	# Monitoring
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
}

class webserver::modproxy {

	include generic::sysctl::high-http-performance

	package { libapache2-mod-proxy-html:
		ensure => latest;
	}
}

class webserver::php5-mysql {

	include generic::sysctl::high-http-performance

	package { php5-mysql:
		ensure => latest;
		}
}

class webserver::php5-gd {

	include generic::sysctl::high-http-performance

	package { "php5-gd":
		ensure => latest;
	}
}

class webserver::apache2 {

	include generic::sysctl::high-http-performance

	package { apache2:
		ensure => latest;
	}

}

class webserver::apache2::rpaf {
	# NOTE: rpaf.conf defaults to just 127.0.01 - may need to
	# modify to include squid/varnish/nginx ranges depending
	# on use.
	package { libapache2-mod-rpaf:
		ensure => latest;
	}
	apache_module { rpaf:
		name => "rpaf",
		require => Package["libapache2-mod-rpaf"];
	}
}


# New style attempt at handling misc web servers
# - keep independent from the existing stuff


class webserver::apache {
	class packages($mpm="prefork") {
		package { ["apache2", "apache2-mpm-${mpm}"]:
			ensure => latest;
		}
	}

	# TODO: documentation of parameters
	define module {
		Class[webserver::apache::packages] -> Webserver::Apache::Module[$title] -> Class[webserver::apache::config]

		$packagename = $operatingsystem ? {
			Ubuntu => $title ? {
				perl => "libapache2-mod-perl2",

				actions => undef,
				alias => undef,
				apreq => undef,
				asis => undef,
				auth_basic => undef,
				auth_digest => undef,
				authn_alias => undef,
				authn_anon => undef,
				authn_dbd => undef,
				authn_dbm => undef,
				authn_default => undef,
				authn_file => undef,
				authnz_ldap => undef,
				authz_dbm => undef,
				authz_default => undef,
				authz_groupfile => undef,
				authz_host => undef,
				authz_owner => undef,
				authz_user => undef,
				autoindex => undef,
				cache => undef,
				cern_meta => undef,
				cgi => undef,
				cgid => undef,
				charset_lite => undef,
				dav => undef,
				dav_fs => undef,
				dav_lock => undef,
				dbd => undef,
				deflate => undef,
				dir => undef,
				disk_cache => undef,
				dump_io => undef,
				env => undef,
				expires => undef,
				ext_filter => undef,
				file_cache => undef,
				filter => undef,
				headers => undef,
				ident => undef,
				imagemap => undef,
				include => undef,
				info => undef,
				ldap => undef,
				log_forensic => undef,
				mem_cache => undef,
				mime => undef,
				mime_magic => undef,
				negotiation => undef,
				perl => undef,
				perl2 => undef,
				proxy => undef,
				proxy_ajp => undef,
				proxy_balancer => undef,
				proxy_connect => undef,
				proxy_ftp => undef,
				proxy_http => undef,
				proxy_scgi => undef,
				reqtimeout => undef,
				rewrite => undef,
				setenvif => undef,
				speling => undef,
				ssl => undef,
				status => undef,
				substitute => undef,
				suexec => undef,
				unique_id => undef,
				userdir => undef,
				usertrack => undef,
				version => undef,
				vhost_alias => undef,

				default => "libapache2-mod-${title}"
			},
			default => "libapache2-mod-${title}"
		}

		if $packagename {
			package { $packagename:
				ensure => latest;
			}
		}
		
		File {
			require => $packagename ? {
				undef => undef,
				default => Package[$packagename]
			},
			notify => Class[webserver::apache::service],
			owner => root,
			group => root,
			mode => 0444
		}
		file {
			"/etc/apache2/mods-available/${title}.conf":
				ensure => present;
			"/etc/apache2/mods-available/${title}.load":
				ensure => present;
			"/etc/apache2/mods-enabled/${title}.conf":
				ensure => "../mods-available/${title}.conf";
			"/etc/apache2/mods-enabled/${title}.load":
				ensure => "../mods-available/${title}.load";
		}
	}

	class config {
		# Realize virtual resources for Apache modules
		Webserver::Apache::Module <| |>
		
		# Realize virtual resources for enabling virtual hosts
		Webserver::Apache::Site <| |>
	}

	class service {
		service{ apache2:
			ensure => running;
		}
	}
	
	# TODO: documentation of parameters
	define site($aliases=[], $ssl="false", $certfile=undef, $certkey=undef, $docroot=undef, $custom=[], $includes=[], $ensure=present) {
		Class[webserver::apache::packages] -> Webserver::Apache::Site["$title"] -> Class[webserver::apache::service]
		
		if ! $docroot {
			$subdir = inline_template("scope.lookupvar('webserver::apache::site::title').strip.split.reverse.join('/')")
			$docroot = "/srv/$subdir"
		}
		
		if $ssl in ["true", "only", "redirected"] {
			webserver::apache::module { ssl: }
			
			# If no cert files are defined, assume a wildcart certificate for the domain
			$wildcard_domain = regsubst($title, "^[^.]+", "*")
			if ! $certfile {
				$certfile = "/etc/ssl/certs/${wildcard_domain}.pem"
			}
			if ! $certkey {
				$certkey = "/etc/ssl/private/${wildcard_domain}.key"
			}
		}
		
		file {
			"/etc/apache2/sites-available/${title}":
				notify => Class[webserver::apache::service],
				owner => root,
				group => root,
				mode => 0444,
				content => template("apache/generic_vhost.erb");
			"/etc/apache2/sites-enabled/${title}":
				notify => Class[webserver::apache::service],
				ensure => $ensure ? {
						absent => $ensure,
						default => "/etc/apache2/sites-available/${title}"
					};
		}
	}
	
	# Default selection
	include packages,
		config,
		service,
		generic::sysctl::high-http-performance
}
