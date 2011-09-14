# varnish.pp

@monitor_group { "cache_bits_pmtpa": description => "pmtpa bits Varnish" }
@monitor_group { "cache_bits_esams": description => "esams bits Varnish" }
@monitor_group { "cache_mobile_eqiad": description => "eqiad mobile Varnish" }

class varnish {
	if ! $varnish_backends {
		$varnish_backends = [ ]
	}
	if ! $varnish_directors {
		$varnish_directors = { }
	}

	require generic::geoip::files

	package { varnish:
		ensure => "2.1.5-2ubuntu1wm1";
	}

	file {
		"/etc/init.d/varnish":
			require => Package[varnish],
			source => "puppet:///files/varnish/varnish.init",
			owner => root,
			group => root,
			mode => 0555;
		"/etc/default/varnish":
			require => Package[varnish],
			content => template("varnish/varnish-default.erb");
		"/etc/varnish/wikimedia.vcl":
			require => Package[varnish],
			content => template("varnish/wikimedia.vcl.erb");
	}

	# Tune kernel settings
	include generic::sysctl::high-http-performance

	# Mount /var/lib/varnish as tmpfs to avoid Linux flushing mlocked
	# shm memory to disk
	mount { "/var/lib/varnish":
		require => Package[varnish],
		notify => Service[varnish],
		device => "tmpfs",
		fstype => "tmpfs",
		options => "noatime,defaults,size=150M",
		pass => 0,
		dump => 0,
		ensure => mounted;
	}

	service { varnish:
		require => [ Package[varnish], File["/etc/default/varnish"], File["/etc/varnish/wikimedia.vcl"], Mount["/var/lib/varnish"] ],
		ensure => running;
	}

	# Load a new VCL file
	exec { "load-new-vcl-file":
		require => File["/etc/varnish/wikimedia.vcl"],
		subscribe => File["/etc/varnish/wikimedia.vcl"],
		command => "echo 'dirtyhack' > /dev/null; TS=`date +%Y%m%d%H%M%S`; varnishadm -S /etc/varnish/secret -T 127.0.0.1:6082 vcl.load \$TS /etc/varnish/wikimedia.vcl && varnishadm -S /etc/varnish/secret -T 127.0.0.1:6082 vcl.use \$TS",
		path => "/bin:/usr/bin",
		refreshonly => true;
	}

	class monitoring {
		# Nagios
	        monitor_service { "varnish http":
        	        description => "Varnish HTTP",
	                check_command => 'check_http_bits'
	        }

		# Ganglia
		file {
			"/usr/lib/ganglia/python_modules/varnish.py":
				require => File["/usr/lib/ganglia/python_modules"],
				source => "puppet:///files/ganglia/plugins/varnish.py",
				notify => Service[gmond];
			"/etc/ganglia/conf.d/varnish.pyconf":
				require => File["/etc/ganglia/conf.d"],
				source => "puppet:///files/ganglia/plugins/varnish.pyconf",
				notify => Service[gmond];
		}
	}

	include varnish::monitoring
}

### This is a mess of horrible duplication while migrating to Varnish 3.0 
### VCL in 3.0 isn't compatible with prior versions in some important ways, this is to be 
### extra paranoid to avoid accidentally changing anything on bits.  Once fully migrated,
### This class should be renamed to varnish and everything above deleted.
class varnish3 {
	if ! $varnish_backends {
		$varnish_backends = [ ]
	}
	if ! $varnish_directors {
		$varnish_directors = { }
	}

	package { varnish3:
		ensure => "3.0.0-1wmf5";
	}

	package { libworking-daemon-perl: 
		ensure => present;
	}

	$vcl = "/etc/varnish/mobile-backend.vcl"
	$varnish_port = "81"
	$varnish_admin_port = "6083"
	$varnish_storage = "-s file,/a/sda/varnish.persist,50% -s file,/a/sdb/varnish.persist,50%"

	file {
		"/etc/init.d/varnish":
			require => Package[varnish3],
			source => "puppet:///files/varnish/varnish.init-nogeo",
			owner => root,
			group => root,
			mode => 0555;
		"/etc/default/varnish":
			require => Package[varnish3],
			content => template("varnish/varnish3-default.erb");
		"/etc/varnish/mobile-backend.vcl":
			require => Package[varnish3],
			content => template("varnish/mobile-backend.vcl.erb");
	}

        # Tune kernel settings
        include generic::sysctl::high-http-performance

	# Mount /var/lib/ganglia as tmpfs to avoid Linux flushing mlocked
	# shm memory to disk
	mount { "/var/lib/varnish":
		require => Package[varnish3],
		#notify => Service[varnish],
		device => "tmpfs",
		fstype => "tmpfs",
		options => "noatime,defaults,size=320M",
		pass => 0,
		dump => 0,
		ensure => mounted;
	}

	service { varnish:
		require => [ Package[varnish3], File["/etc/default/varnish"], Mount["/var/lib/varnish"] ],
		ensure => running;
	}

	# Load a new VCL file
	exec { "load-new-vcl-file":
		require => File["$vcl"],
		subscribe => File["$vcl"],
		command => "/usr/share/varnish/reload-vcl",
		path => "/bin:/usr/bin",
		refreshonly => true;
	}

	class monitoring {
		# FIXME: make this service-unspecific, and also monitor possible frontends.
		
		# Nagios
	        monitor_service { "varnish http":
        	        description => "Varnish HTTP",
	                check_command => 'check_http_bits'
	        }

		# Ganglia
		file {
			"/usr/lib/ganglia/python_modules/varnish.py":
				require => File["/usr/lib/ganglia/python_modules"],
				source => "puppet:///files/ganglia/plugins/varnish.py",
				notify => Service[gmond];
			"/etc/ganglia/conf.d/varnish.pyconf":
				require => File["/etc/ganglia/conf.d"],
				source => "puppet:///files/ganglia/plugins/varnish.pyconf",
				notify => Service[gmond];
		}
	}

	class htcpd { 
		file {
			"/usr/bin/varnishhtcpd":
				require => Package[varnish3],
				source => "puppet:///files/varnish/varnishhtcpd",
				owner => root,
				group => root,
				mode => 0555;
			"/etc/init.d/varnishhtcpd":
				require => Package[varnish3],
				source => "puppet:///files/varnish/varnishhtcpd.init",
				owner => root,
				group => root,
				mode => 0555;
		}
		service { varnishhtcpd:
			require => [ Package[varnish3], File["/etc/init.d/varnishhtcpd"] ],
			hasstatus => false,
			pattern => "varnishhtcpd",
			ensure => running;
		}
	}

	#include varnish::monitoring
}

class varnish3_frontend { 
	require generic::geoip::files

	$varnish_backends = $varnish_fe_backends
	$varnish_directors = $varnish_fe_directors

	if ! $varnish_backends {
		$varnish_backends = [ ]
	}
	if ! $varnish_directors {
		$varnish_directors = { }
	}

	$vcl = "/etc/varnish/mobile-frontend.vcl"
	$varnish_port = "80"
	$varnish_admin_port = "6082"
	$varnish_storage = "-s malloc,256M"
	$extraopts = "-n frontend"
	
	file {
		"/etc/init.d/varnish-frontend":
			require => Package[varnish3],
			source => "puppet:///files/varnish/varnish-frontend.init",
			owner => root,
			group => root,
			mode => 0555;
		"/usr/share/varnish/reload-vcl-frontend":
			require => Package[varnish3],
			source => "puppet:///files/varnish/reload-vcl-frontend",
			owner => root,
			group => root,
			mode => 0555;
		"/etc/default/varnish-frontend":
			require => Package[varnish3],
			content => template("varnish/varnish3-default.erb");
		"/etc/varnish/mobile-frontend.vcl":
			require => Package[varnish3],
			content => template("varnish/mobile-frontend.vcl.erb");

	}

	service { varnish-frontend:
		require => [ Package[varnish3], File["/etc/default/varnish-frontend"], Mount["/var/lib/varnish"] ],
		hasstatus => false,
		pattern => "/var/run/varnishd-frontend.pid",
		ensure => running;
	}

	exec { "load-new-frontend-vcl-file":
		require => File["$vcl"],
		subscribe => File["$vcl"],
		command => "/usr/share/varnish/reload-vcl-frontend",
		path => "/bin:/usr/bin",
		refreshonly => true;
	}

}
