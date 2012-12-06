# Wikimedia Blogs

# https://blog.wikimedia.org/
class misc::blogs::wikimedia {
	system_role { "misc::blogs::wikimedia": description => "blog.wikimedia.org" }

	require apaches::packages,
		webserver::php5-gd,
		webserver::apache2::rpaf
		
	package { "unzip":
		ensure => latest;
	}

	# apache virtual host for blog.wikimedia.org
	file {
		"/etc/apache2/sites-available/blog.wikimedia.org":
			path => "/etc/apache2/sites-available/blog.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/blog.wikimedia.org";
	}

	class { "memcached": memcached_ip => "127.0.0.1" }
	install_certificate{ "star.wikimedia.org": }

	# varnish cache instance for blog.wikimedia.org
	varnish::instance { "blog":
		name => "",
		vcl => "blog",
		port => 80,
		admin_port => 6082,
		storage => "-s malloc,1G",
		backends => [ 'localhost' ],
		directors => { 'backend' => [ 'localhost' ] },
		vcl_config => {
			'retry5xx' => 0
		},
		backend_options => {
			'port' => 81,
			'connect_timeout' => "5s",
			'first_byte_timeout' => "35s",
			'between_bytes_timeout' => "4s",
			'max_connections' => 100,
			'probe' => "blog",
		},
	}

	# TODO: DRY this.  It is used for the firehose request log stream for all Wikimedia web requets logs.
	varnish::logging { "locke" :           listener_address => "208.80.152.138" , cli_args => "-m RxRequest:^(?!PURGE\$) -D", monitor => false }
	varnish::logging { "emery" :           listener_address => "208.80.152.184" , cli_args => "-m RxRequest:^(?!PURGE\$) -D", monitor => false }
	varnish::logging { "multicast_relay" : listener_address => "208.80.154.15"  , cli_args => "-m RxRequest:^(?!PURGE\$) -D", monitor => false, port => "8419" }
	
}

