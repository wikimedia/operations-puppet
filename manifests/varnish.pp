# varnish.pp

@monitor_group { "cache_bits_pmtpa": description => "pmtpa bits Varnish" }
@monitor_group { "cache_bits_eqiad": description => "eqiad bits Varnish "}
@monitor_group { "cache_bits_esams": description => "esams bits Varnish" }
@monitor_group { "cache_mobile_eqiad": description => "eqiad mobile Varnish" }

class varnish {
	class packages {
		# TODO: rebuild the package to use varnish as the init script name
		file { "/etc/init.d/varnish3":
			ensure => link,
			target => "/etc/init.d/varnish";
		}
		package { [ 'varnish3', 'libvarnishapi1' ]:
			ensure => "3.0.2-1wmf1";
		}
		package { libworking-daemon-perl:
			ensure => present;
		}
	}
	
	class common {
		require varnish::packages
		
		# Tune kernel settings
		include generic::sysctl::high-http-performance

		# Mount /var/lib/ganglia as tmpfs to avoid Linux flushing mlocked
		# shm memory to disk
		mount { "/var/lib/varnish":
			require => Class["varnish::packages"],
			device => "tmpfs",
			fstype => "tmpfs",
			options => "noatime,defaults,size=512M",
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
		require "varnish::common"
		
		file {
			"/etc/varnish/geoip.inc.vcl":
				content => template("varnish/geoip.inc.vcl.erb");
		}
	}
	
	define instance($name="", $vcl = "", $port="80", $admin_port="6083", $storage="-s malloc,256M", $backends=[], $directors={}, $backend_options, $enable_geoiplookup="false", $wikimedia_networks=[], $xff_sources=[]) {
		include varnish::common
		
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

		# Install VCL include files shared by all instances
		require "varnish::common-vcl"

		file {
			"/etc/init.d/varnish${instancesuffix}":
				content => template("varnish/varnish.init.erb"),
				mode => 0555;
			"/etc/default/varnish${instancesuffix}":
				content => template("varnish/varnish-default.erb"),
				mode => 0444;
			"/etc/varnish/${vcl}.inc.vcl":
				content => template("varnish/${vcl}.inc.vcl.erb"),
				notify => Exec["load-new-vcl-file${instancesuffix}"],
				mode => 0444;
			"/etc/varnish/wikimedia_${vcl}.vcl":
				require => File["/etc/varnish/${vcl}.inc.vcl"],
				content => template("varnish/wikimedia.vcl.erb"),
				mode => 0444;
		}

		service { "varnish${instancesuffix}":
			require => [
					File[
						"/etc/default/varnish${instancesuffix}",
						"/etc/init.d/varnish${instancesuffix}",
						"/etc/varnish/${vcl}.inc.vcl",
						"/etc/varnish/wikimedia_${vcl}.vcl"
					],
					Mount["/var/lib/varnish"]
				],
			hasstatus => false,
			pattern => "/var/run/varnishd${instancesuffix}.pid",
			ensure => running;
		}

		exec { "load-new-vcl-file${instancesuffix}":
			require => [ Service["varnish${instancesuffix}"], File["/etc/varnish/wikimedia_${vcl}.vcl"] ],
			subscribe => File["/etc/varnish/wikimedia_${vcl}.vcl"],
			command => "/usr/share/varnish/reload-vcl $extraopts",
			path => "/bin:/usr/bin",
			refreshonly => true;
		}

		monitor_service { "varnish http ${title}":
			description => "Varnish HTTP ${title}",
			check_command => "check_http_generic!varnishcheck!${port}"
		}
	}

	class monitoring::ganglia {
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

	define setup_filesystem() {
		file { "/srv/${title}":
			owner => root,
			group => root,
			ensure => directory
		}

		mount { "/srv/${title}":
			require => File["/srv/${title}"],
			device => "/dev/${title}",
			fstype => "xfs",
			options => "noatime,nodiratime,nobarrier,logbufs=8",
			ensure => mounted
		}

		file { "/srv/${title}/varnish.persist":
			require => Mount["/srv/${title}"],
			owner => root,
			group => root,
			ensure => present
		}
	}

	class htcpd {
		require varnish::packages

		systemuser { "varnishhtcpd": name => "varnishhtcpd", home => "/var/lib/varnishhtcpd" }

		file {
			"/usr/bin/varnishhtcpd":
				source => "puppet:///files/varnish/varnishhtcpd",
				owner => root,
				group => root,
				mode => 0555;
			"/etc/init.d/varnishhtcpd":
				source => "puppet:///files/varnish/varnishhtcpd.init",
				owner => root,
				group => root,
				mode => 0555;
		}
		
		service { varnishhtcpd:
			require => [ File["/etc/init.d/varnishhtcpd"], Systemuser[varnishhtcpd] ],
			hasstatus => false,
			pattern => "varnishhtcpd",
			ensure => running;
		}
	}

	class htcppurger($varnish_instances=["localhost:80"]) {
		require varnish::packages

		systemuser { "varnishhtcpd": name => "varnishhtcpd", home => "/var/lib/varnishhtcpd" }

		file {
			"/usr/local/bin/varnishhtcpd":
				source => "puppet:///files/varnish/varnishhtcpd",
				owner => root,
				group => root,
				mode => 0555;
			"/etc/init.d/varnishhtcpd":
				source => "puppet:///files/varnish/varnishhtcpd.init",
				owner => root,
				group => root,
				mode => 0555;
			"/etc/default/varnishhtcpd":
				owner => root,
				group => root,
				mode => 0444,
				content => inline_template('DAEMON_OPTS="--mcast_address=239.128.0.112<% varnish_instances.each do |inst| -%> --cache=<%= inst %><% end -%> --name=varnishhtcpd"');
		}

		service { varnishhtcpd:
			require => [ File[["/usr/local/bin/varnishhtcpd", "/etc/init.d/varnishhtcpd", "/etc/default/varnishhtcpd"]], Systemuser[varnishhtcpd] ],
			hasstatus => false,
			pattern => "varnishhtcpd",
			ensure => running;
		}
	}


	## If you want to send udplog traffic to one address,
	## leave $udplogger2 blank
	class logging($udplogger1="emery.wikimedia.org", $udplogger2="locke.wikimedia.org") {

		file {
			"/etc/init.d/varnishncsa":
				require => Package[varnish3],
				content => template("varnish/varnishncsa.init.erb"),
				owner => root,
				group => root,
				mode => 0555;
			"/etc/default/varnishncsa":
				require => Package[varnish3],
				source => "puppet:///files/varnish/varnishncsa.default",
				owner => root,
				group => root,
				mode => 0444;
		}

		service { varnishncsa:
			require => [ Package[varnish3], File["/etc/init.d/varnishncsa"] ],
			ensure => running;
		}

		monitor_service { "varnishncsa":
			description => "Varnish traffic logger",
			check_command => "nrpe_check_varnishncsa"
		}
	}

	class varnishncsa {
		upstart_job { "varnishncsa": install => "true" }
	}

	# Definition: varnish::udplogging
	#
	# Sets up a UDP logging instances of varnishncsa
	#
	# Parameters:
	# - $title:
	#	Name of the instance
	# - $host:
	#	Hostname or ip address of the logger
	# - $port:
	#	UDP port (default 8420)
	# - $varnish_instance:
	#	Varnish instance name (default: undefined)
	define udplogger($host, $port=8420, $varnish_instance=$::hostname) {
		Class[varnish::packages] -> Varnish::Udplogger[$title]
		require varnish::varnishncsa

		$environment = [
			"LOGGER_NAME=${title}",
			"LOG_DEST=\"${host}:${port}\"",
			"VARNISH_INSTANCE=\"-n ${varnish_instance}\""
		]

		exec { "varnishncsa $title":
			path => "/bin:/sbin:/usr/bin:/usr/sbin",
			command => inline_template("start varnishncsa <%= environment.join(\" \") %>"),
			unless => "status varnishncsa LOGGER_NAME=${title}",
			logoutput => true
		}
		
		# TODO: monitoring
	}

	# Make a default instance
	instance { "default": }
}

