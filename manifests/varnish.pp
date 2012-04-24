# varnish.pp

@monitor_group { "cache_bits_pmtpa": description => "pmtpa bits Varnish" }
@monitor_group { "cache_bits_eqiad": description => "eqiad bits Varnish "}
@monitor_group { "cache_bits_esams": description => "esams bits Varnish" }
@monitor_group { "cache_mobile_eqiad": description => "eqiad mobile Varnish" }

class varnish {
	class packages($version="installed") {
		package { [ 'varnish', 'libvarnishapi1', 'varnish-dbg' ]:
			ensure => $version;
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
	
	define instance(
		$name="",
		$vcl = "",
		$port="80",
		$admin_port="6083",
		$storage="-s malloc,256M",
		$backends=[],
		$directors={},
		$director_type="hash",
		$vcl_config,
		$backend_options,
		$enable_geoiplookup="false",
		$wikimedia_networks=[],
		$xff_sources=[]) {

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
			subscribe => Package[varnish],
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
		
		# Restart gmond if this varnish instance has been (re)started later
		# than gmond was started
		exec { "restart gmond for varnish${instancesuffix}":
			path => "/bin:/sbin:/usr/bin:/usr/sbin",
			command => "true",
			onlyif => "test /var/run/varnishd${instancesuffix}.pid -nt /var/run/gmond.pid",
			notify => Service[gmond]
		}
	}

	class monitoring::ganglia($varnish_instances=['']) {
		file {
			"/usr/lib/ganglia/python_modules/varnish.py":
				require => File["/usr/lib/ganglia/python_modules"],
				source => "puppet:///files/ganglia/plugins/varnish.py",
				notify => Service[gmond];
			"/etc/ganglia/conf.d/varnish.pyconf":
				require => File["/etc/ganglia/conf.d"],
				content => template("ganglia/plugins/varnish.pyconf.erb"),
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

	class htcppurger($varnish_instances=["localhost:80"]) {
		Class[varnish::packages] -> Class[varnish::htcppurger]

		systemuser { "varnishhtcpd": name => "varnishhtcpd", default_group => "varnishhtcpd", home => "/var/lib/varnishhtcpd" }

		file {
			"/usr/local/bin/varnishhtcpd":
				source => "puppet:///files/varnish/varnishhtcpd",
				owner => root,
				group => root,
				mode => 0555;
			"/etc/default/varnishhtcpd":
				owner => root,
				group => root,
				mode => 0444,
				content => inline_template('DAEMON_OPTS="--user=varnishhtcpd --group=varnishhtcpd --mcast_address=239.128.0.112<% varnish_instances.each do |inst| -%> --cache=<%= inst %><% end -%>"');
		}

		upstart_job { "varnishhtcpd": install => "true" }

		service { varnishhtcpd:
			require => [ File[["/usr/local/bin/varnishhtcpd", "/etc/default/varnishhtcpd"]], Systemuser[varnishhtcpd], Upstart_job[varnishhtcpd] ],
			provider => upstart,
			ensure => running;
		}
		
		nrpe::monitor_service { "varnishhtcpd":
			description => "Varnish HTCP daemon",
			nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u varnishhtcpd -a 'varnishhtcpd worker'"
		}
	}


	class logging_config {
		file {
			"/etc/default/varnishncsa":
				source => "puppet:///files/varnish/varnishncsa.default",
				owner => root,
				group => root,
				mode => 0444;
		}

		nrpe::monitor_service { "varnishncsa":
			description => "Varnish traffic logger",
			nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 3:3 -c 3:6 -C varnishncsa"
		}
	}

	define logging($listener_address, $port="8420", $cli_args="", $instance_name="frontend") {
		require varnish::packages,
			varnish::logging_config

		file {
			"/etc/init.d/varnishncsa-${name}":
				content => template("varnish/varnishncsa.init.erb"),
				owner => root,
				group => root,
				mode => 0555;
		}

		service { "varnishncsa-${name}":
			require => File["/etc/init.d/varnishncsa-${name}"],
			ensure => running,
			pattern => "/var/run/varnishncsa/varnishncsa-${name}.pid",
			hasstatus => false;
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

