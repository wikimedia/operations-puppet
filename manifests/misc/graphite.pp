# graphite - https://graphite.wikimedia.org/

class misc::graphite {
	system_role { "misc::graphite": description => "graphite and carbon services" }

	include webserver::apache2, misc::graphite::gdash

	package { [ "python-libxml2", "python-sqlite", "python-sqlitecachec", "python-setuptools", "libapache2-mod-python", "libcairo2", "python-cairo", "python-simplejson", "python-django", "python-django-tagging", "python-twisted", "python-twisted-runner", "python-twisted-web", "memcached", "python-memcache" ]:
		ensure => present;
	}

	package { [ "python-carbon", "python-graphite-web", "python-whisper" ]:
		ensure => "0.9.9-1";
	}

	file {
		"/etc/apache2/sites-available/graphite":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/apache.conf";
		"/a/graphite/conf/carbon.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/carbon.conf";
		"/a/graphite/conf/dashboard.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/dashboard.conf";
		"/a/graphite/conf/storage-schemas.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/storage-schemas.conf";
		"/a/graphite/conf/storage-aggregation.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/storage-aggregation.conf";
		"/a/graphite/storage":
			owner => "www-data",
			group => "www-data",
			mode => 0755,
			ensure => directory;
		"/etc/sysctl.d/99-big-rmem.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			content => "
net.core.rmem_max = 536870912
net.core.rmem_default = 536870912
";
	}

	apache_module { python: name => "python" }
	apache_site { graphite: name => "graphite" }

	include network::constants

	varnish::instance { "graphite":
		name => "",
		vcl => "graphite",
		port => 81,
		admin_port => 6082,
		storage => "-s malloc,256M",
		backends => [ 'localhost' ],
		directors => { 'backend' => [ 'localhost' ] },
		vcl_config => {
			'retry5xx' => 0
		},
		backend_options => {
			'port' => 80,
			'connect_timeout' => "5s",
			'first_byte_timeout' => "35s",
			'between_bytes_timeout' => "4s",
			'max_connections' => 100,
			'probe' => "options",
		},
		xff_sources => $network::constants::all_networks
	}
}

class misc::graphite::gdash {
	# TODO
	# gdash fork needs to be moved out of the puppet file repo!
	# It should then be packaged and installed via this class.
	# For now this only installs templates to a preconfigured location
	# that will probably move after the above happens.
	# This is all kinds of badness.

	file {
		"/a/graphite/webapp/gdash/templates":
			owner => "www-data",
			group => "www-data",
			mode => 0555,
			ensure => directory,
			recurse => true;
		"/a/graphite/webapp/gdash/templates/dashboards/":
			owner => "www-data",
			group => "www-data",
			mode => 0555,
			source => "puppet:///files/graphite/gdash-dashboards/",
			recurse => remote;
	}
}
