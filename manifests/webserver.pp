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