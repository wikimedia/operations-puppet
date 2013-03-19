# Wikimedia Blogs

# https://blog.wikimedia.org/
class misc::blogs::wikimedia {
	system_role { "misc::blogs::wikimedia": description => "blog.wikimedia.org" }

	class {'webserver::php5': ssl => 'true'; }

	require webserver::php5-mysql,
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

	# There's not really a good reason for this to be "",
	# except that it was like that when I found it.
	# I need to pass this to varnish::logging too, so it
	# knows which varnish service to notify.
	$varnish_blog_instance_name = ""

	# varnish cache instance for blog.wikimedia.org
	varnish::instance { "blog":
		name => $varnish_blog_instance_name,
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

	# DRY this by setting defaults for varnish::logging define.
	Varnish::Logging {
		cli_args      => "-m RxRequest:^(?!PURGE\$) -D",
		instance_name => $varnish_blog_instance_name,
		monitor       => false,
	}
	# send blog access logs to udp2log instances.
	varnish::logging { "locke" :           listener_address => "208.80.152.138" }
	varnish::logging { "gadolinium" :      listener_address => "208.80.154.73" }
	varnish::logging { "emery" :           listener_address => "208.80.152.184" }
	varnish::logging { "multicast_relay" : listener_address => "208.80.154.15", port => "8419" }

	# Capture blog traffic logs on its own stream in analytics cluster.
	# 208.80.154.154 == analytics1001.wikimedia.org
	varnish::logging { "analytics-blog" :  listener_address => "208.80.154.154", port => "8411" }
}

