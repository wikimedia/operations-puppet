# This file is for all generic web server classes
# Apache, php, etc belong in here
# Specific services (racktables, etherpad) do not


# Installs a generic, static web server (lighttpd) with default config, which serves /var/www
class webserver::static {
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

	package { libapache2-mod-proxy-html:
		ensure => latest;
	}
}

class webserver::php5-mysql {

	package { php5-mysql:
		ensure => latest;
		}
}

class webserver::php5-gd {
	package { "php5-gd":
		ensure => latest;
	}
}

class webserver::apache2 {

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
		package { ["apache2", "apache2-mpm-${title}"]:
			ensure => latest;
		}
	}

	# TODO: documentation of parameters
	define module {
		Class[webserver::apache::packages] -> Webserver::Apache::Module[$title] -> Class[webserver::apache::config]
		
		package { "libapache2-mod-${title}":
			ensure => latest;
		}
		
		File {
			require => Package["libapache2-mod-${title}"],
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

	define config {
		# Realize virtual resources for Apache modules
		Webserver::Apache::Module <| |>
		
		# Realize virtual resources for enabling virtual hosts
		Webserver::Apache::Site <| |>
	}

	define service {
		service{ apache2:
			ensure => running;
		}
	}
	
	# TODO: documentation of parameters
	define site($aliases=[], $ssl="false", $docroot=undef, $includes=[], $ensure=present) {
		Class[webserver::apache::packages] -> Webserver::Apache::Site["$title"] -> Class[webserver::apache::service]
		
		if ! $docroot {
			$subdir = inline_template("scope.lookupvar('webserver::apache::site::title').strip.split.reverse.join('/')")
			$docroot = "/srv/$subdir"
		}
		
		if $ssl in ["true", "only", "redirected"] {
			webserver::apache::module { ssl: }
		}
		
		file {
			"/etc/apache2/sites-available/${title}":
				owner => root,
				group => root,
				mode => 0444,
				content => template("apache/generic_vhost.erb");
			"/etc/apache2/sites-enabled/${title}":
				ensure => $ensure ? {
						absent => $ensure,
						default => "link"
					};
		}
	}
	
	# Default selection
	include packages, config, service
}