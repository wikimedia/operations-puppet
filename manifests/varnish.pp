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
	class packages {
		package { varnish3:
			ensure => "3.0.0-1wmf6";
		}

		package { libworking-daemon-perl: 
			ensure => present;
		}
	}
	
	class common {
		require varnish3::packages
		
		# Tune kernel settings
		include generic::sysctl::high-http-performance

		# Mount /var/lib/ganglia as tmpfs to avoid Linux flushing mlocked
		# shm memory to disk
		mount { "/var/lib/varnish":
			require => Package[varnish3],
			device => "tmpfs",
			fstype => "tmpfs",
			options => "noatime,defaults,size=320M",
			pass => 0,
			dump => 0,
			ensure => mounted;
		}

		file {
			"/usr/share/varnish/reload-vcl":
				source => "puppet:///files/varnish/reload-vcl",
				mode => 0555;
		}
	}
	
	class common-vcl {
		file {
			"/etc/varnish/geoip.inc.vcl":
				content => template("varnish/geoip.inc.vcl.erb");
		}
	}
	
	define instance($name="", $vcl = "", $port="80", $admin_port="6083", $storage="-s malloc,256M", $backends=[], $directors={}, $backend_options, $enable_geoiplookup="false") {
		include varnish3::common
		
		if $name == "" {
			$instancesuffix = ""
			$extraopts = ""
		}
		else {
			$instancesuffix = "-${name}"
			$extraopts = "-n ${name}"
		}

		# Initialize variables for templates
		$varnish_port = $port
		$varnish_admin_port = $admin_port
		$varnish_storage = $storage
		$varnish_enable_geoiplookup = $enable_geoiplookup
		$varnish_backends = $backends
		$varnish_directors = $directors
		$varnish_backend_options = $backend_options
		
		$varnish_hook_functions = [ "vcl_recv", "vcl_fetch", "vcl_hit", "vcl_miss", "vcl_deliver", "vcl_error" ]
		
		# Install VCL include files shared by all instances
		require "varnish3::common-vcl"

		file {
			"/etc/init.d/varnish${instancesuffix}":
				content => template("varnish/varnish.init.erb"),
				mode => 0555;
			"/etc/default/varnish${instancesuffix}":
				content => template("varnish/varnish3-default.erb"),
				mode => 0444;
			"/etc/varnish/${vcl}.inc.vcl":
				content => template("varnish/${vcl}.inc.vcl.erb"),
				notify => Exec["load-new-vcl-file${instancesuffix}"],
				mode => 0444;
			"/etc/varnish/wikimedia3_${vcl}.vcl":
				require => File["/etc/varnish/${vcl}.inc.vcl"],
				content => template("varnish/wikimedia3.vcl.erb"),
				mode => 0444;
		}

		service { "varnish${instancesuffix}":
			require => [ File["/etc/default/varnish${instancesuffix}"], Mount["/var/lib/varnish"] ],
			hasstatus => false,
			pattern => "/var/run/varnishd${instancesuffix}.pid",
			ensure => running;
		}

		exec { "load-new-vcl-file${instancesuffix}":
			require => File["/etc/varnish/wikimedia3_${vcl}.vcl"],
			subscribe => File["/etc/varnish/wikimedia3_${vcl}.vcl"],
			command => "/usr/share/varnish/reload-vcl $extraopts",
			path => "/bin:/usr/bin",
			refreshonly => true;
		}
	}

	# FIXME: make generic/multi-instance
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

	# Make a default instance
	instance { "default": }
}

