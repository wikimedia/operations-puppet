# generic-definitions.pp
#
# File that contains generally useful definitions, e.g. for creating system users

# Prints a MOTD message about the role of this system
define system_role($description) {
	$role_script_content = "#!/bin/sh

echo \"$(hostname) is a Wikimedia ${description} (${title}).\"
"

	$rolename = regsubst($title, ":", "-", "G")
	$motd_filename = "/etc/update-motd.d/05-role-${rolename}"

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "9.10") >= 0 {
		file { $motd_filename:
			owner => root,
			group => root,
			mode => 0755,
			content => $role_script_content,
			ensure => present;
		}
	}
}

# Creates a system username with associated group, random uid/gid, and /bin/false as shell
define systemuser($name, $home, $shell="/bin/false", $groups=undef) {
	group { $name:
		name => $name,
		ensure => present;
	}

	user { $name:
		require => Group[$name],
		name => $name,
		gid => $name,
		home => $home,
		managehome => true,
		shell => $shell,
		groups => $groups,
		ensure => present;
	}
}

# Enables a certain Apache 2 site
define apache_site($name) {
	file { "/etc/apache2/sites-enabled/${name}":
		ensure => "/etc/apache2/sites-available/$name",
	}
}

# Enables a certain Apache 2 module
define apache_module($name) {
	file {
		"/etc/apache2/mods-available/${name}.conf":
			ensure => present;
		"/etc/apache2/mods-available/${name}.load":
			ensure => present;
		"/etc/apache2/mods-enabled/${name}.conf":
			ensure => "../mods-available/${name}.conf";
		"/etc/apache2/mods-enabled/${name}.load":
			ensure => "../mods-available/${name}.load";
	}
}

# Enables a certain Lighttpd config
define lighttpd_config($name) {
	file { "/etc/lighttpd/conf-enabled/${name}":
		ensure => "/etc/lighttpd/conf-available/$name";
	}
}

# Enables a certain NGINX site
define nginx_site($install="false", $template="", $enable="true") {
	if ( $template == "" ) {
		$template_name = $name
	} else {
		$template_name = $template
	}
	if ( $enable == "true" ) {
	        file { "/etc/nginx/sites-enabled/${name}":
        	        ensure => "/etc/nginx/sites-available/${name}",
		}
	} else {
	        file { "/etc/nginx/sites-enabled/${name}":
        	        ensure => absent;
		}
	}

	case $install {
	"true": {
			file { "/etc/nginx/sites-available/${name}":
				source => "puppet:///files/nginx/sites/${name}";
			}
		}
	"template": {
			file { "/etc/nginx/sites-available/${name}":
				content => template("nginx/sites/${template_name}.erb");
			}
		}
	}
}

# Installs a generic, static web server (lighttpd) with default config, which serves /var/www

class generic::webserver::static {
	package { lighttpd:
		ensure => latest;
	}

	service { lighttpd:
		ensure => running;
	}

	# Monitoring
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
}

class generic::webserver::php5 {
	# Prefer the PHP package from Ubuntu
	generic::apt::pin-package { [ libapache2-mod-php5, php5-common ]: }

        package { [ "apache2", "libapache2-mod-php5" ]:
                ensure => latest;
        }

        service { apache2:
                require => Package[apache2],
                subscribe => Package[libapache2-mod-php5],
                ensure => running;
        }

	# Monitoring
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
}

class generic::webserver::modproxy {

        package { libapache2-mod-proxy-html:
                ensure => latest;
        }
}

class generic::webserver::php5-mysql {

	package { php5-mysql:
		ensure => latest;
		}
}

# Sysctl settings

define sysctl($value) {
/*
	$quoted_param = shellquote("${title}=${value}")

	alert("current value: ${sysctl.${title}}")

	if ${sysctl.${title}} != ${value} {
		exec { "sysctl $title":
			command => "/sbin/sysctl -w ${quoted_param}",
			user => root;
		}
	}
*/

}


class generic::sysctl::high-http-performance($ensure="present") {
	if $lsbdistrelease != "8.04" {
	        file { high-http-performance-sysctl:
	                name => "/etc/sysctl.d/60-high-http-performance.conf",
	                owner => root,
	                group => root,
	                mode => 444,
			notify => Exec["/sbin/start procps"],
	                source => "puppet:///files/misc/60-high-http-performance.conf.sysctl",
			ensure => $ensure
	        }
	}
	else {
		alert("Distribution on $hostname does not support /etc/sysctl.d/ files yet.")
	}
}

class generic::sysctl::advanced-routing($ensure="present") {
	if $lsbdistrelease != "8.04" {
		file { advanced-routing-sysctl:
			name => "/etc/sysctl.d/50-advanced-routing.conf",
			owner => root,
			group => root,
			mode => 444,
			notify => Exec["/sbin/start procps"],
			source => "puppet:///files/misc/50-advanced-routing.conf.sysctl",
			ensure => $ensure
		}
	}
}

class generic::sysctl::lvs($ensure="present") {
	file { lvs-sysctl:
		name => "/etc/sysctl.d/50-lvs.conf",
		mode => 444,
		notify => Exec["/sbin/start procps"],
		source => "puppet:///files/misc/50-lvs.conf.sysctl",
		ensure => $ensure
	}
}

class generic::geoip {
	class packages {
		package { [ "libgeoip1", "libgeoip-dev", "geoip-bin" ]:
			ensure => latest;
		}
	}

	class files {
		require generic::geoip::packages

		file {
			"/usr/share/GeoIP/GeoIP.dat":
    	                	mode => 0644,
        	                owner => root,
                	        group => root,
                        	source => "puppet:///files/misc/GeoIP.dat";
                	"/usr/share/GeoIP/GeoIPCity.dat":
                		mode => 0644,
                		owner => root,
                		group => root,
                		source => "puppet:///files/misc/GeoIPcity.dat";
                }
	}
}

# APT pinning

define generic::apt::pin-package($pin="release o=Ubuntu", $priority="1001") {
	$packagepin = "
Package: ${title}
Pin: ${pin}
Pin-Priority: ${priority}
"

	file { "/etc/apt/preferences.d/${title}":
		content => $packagepin,
		before => defined(Package[$title]) ? {
			true => Package[$title],
			default => undef
		};
	}
}

# Create a symlink in /etc/init.d/ to a generic upstart init script

define upstart_job($install="false") {
	# Create symlink
	file { "/etc/init.d/${title}":
		ensure => "/lib/init/upstart-job";
	}

	if $install == "true" {
		file { "/etc/init/${title}.conf":
			source => "puppet:///files/upstart/${title}.conf"
		}
	}
}

# Expects address without a length, like address => "208.80.152.10", prefixlen => "32"
define interface_ip($interface, $address, $prefixlen="32") {
	$prefix = "${address}/${prefixlen}"
	$iptables_command = "ip addr add ${prefix} dev ${interface}"

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
		# Use augeas to add an 'up' command to the interface
		augeas { "${interface}_${prefix}":
			context => "/files/etc/network/interfaces/*[. = '${interface}']",
			changes => "set up[last()+1] '${iptables_command}'",
			onlyif => "match up[. = '${iptables_command}'] size == 0";
		}
	}

	# Add the IP address manually as well
	exec { $iptables_command:
		path => "/bin:/usr/bin",
		onlyif => "test -z \"$(ip addr show dev ${interface} to ${prefix})\"";
	}
}

define interface_manual($interface, $family="inet") {
	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
		# Use augeas to create a new manually setup interface
		$augeas_cmd = [	"set auto[./1 = '$interface']/1 '$interface'",
				"set iface[. = '$interface'] '$interface'",
				"set iface[. = '$interface']/family '$family'",
				"set iface[. = '$interface']/method 'manual'",
		]

		augeas { "${interface}_manual":
			context => "/files/etc/network/interfaces",
			changes => $augeas_cmd;
		}
	}
}

define interface_up_command($interface, $command) {
	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
		# Use augeas to add an 'up' command to the interface
		augeas { "${interface}_${title}":
			context => "/files/etc/network/interfaces/*[. = '${interface}']",
			changes => "set up[last()+1] '${command}'",
			onlyif => "match up[. = '${command}'] size == 0";
		}
	}	
}

define interface_setting($interface, $setting, $value) {
        if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
                # Use augeas to add an 'up' command to the interface
                augeas { "${interface}_${title}":
                        context => "/files/etc/network/interfaces/*[. = '${interface}']",
                        changes => "set ${setting} '${value}'",
                }
        }
}

class base::vlan-tools {
	package { vlan: ensure => latest; }
}

define interface_tagged($base_interface, $vlan_id, $address=undef, $netmask=undef, $family="inet", $method="static", $up=undef, $remove=undef) {
	require base::vlan-tools

	$intf = "${base_interface}.${vlan_id}"

	if $address {
		$addr_cmd = "set iface[. = '$intf']/address '$address'"
	} else {
		$addr_cmd = ""
	}

	if $netmask {
		$netmask_cmd = "set iface[. = '$intf']/netmask '$netmask'"
	} else {
		$netmask_cmd = ""
	}

	if $up {
		$up_cmd = "set iface[. = '$intf']/up '$up'"
	} else {
		$up_cmd = ""
	}
	
	if $remove == 'true' {
		$augeas_cmd = [	"rm auto[./1 = '$intf']",
				"rm iface[. = '$intf']"
			]
	} else {
		$augeas_cmd = [	"set auto[./1 = '$intf']/1 '$intf'",
				"set iface[. = '$intf'] '$intf'",
				"set iface[. = '$intf']/family '$family'",
				"set iface[. = '$intf']/method '$method'",
				$addr_cmd,
				$netmask_cmd,
				$up_cmd,
			]
	}

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
		if $remove == 'true' {
			exec { "/sbin/ifdown $intf": before => Augeas["$intf"] }
		}

		# Use augeas
		augeas { "$intf":
			context => "/files/etc/network/interfaces/",
			changes => $augeas_cmd;
		}

		if $remove != 'true' {
			exec { "/sbin/ifup $intf": require => Augeas["$intf"] }
		}
	}
}

class generic::rsyncd($config) {
        package { rsync:
                ensure => latest;
        }

        file {
                "/etc/rsyncd.conf":
                        require => Package[rsync],
                        mode => 0644,
                        owner => root,
                        group => root,
                        source => "puppet:///files/rsync/rsyncd.conf.$config",
                        ensure => present;
                "/etc/default/rsync":
                        require => Package[rsync],
                        mode => 0644,
                        owner => root,
                        group => root,
                        source => "puppet:///files/rsync/rsync.default",
                        ensure => present;
        }

        service { rsync:
                require => [ Package[rsync], File["/etc/rsyncd.conf"], File["/etc/default/rsync"] ],
                ensure => running;
        }
}

# definition to import gkg keys from a keyserver into apt
# copied from http://projects.puppetlabs.com/projects/1/wiki/Apt_Keys_Patterns

define apt::key($keyid, $ensure, $keyserver = "keyserver.ubuntu.com") {
	case $ensure {
		present: {
			exec { "Import $keyid to apt keystore":
				path        => "/bin:/usr/bin",
				environment => "HOME=/root",
				command     => "gpg --keyserver $keyserver --recv-keys $keyid && gpg --export --armor $keyid | apt-key add -",
				user        => "root",
				group       => "root",
				unless      => "apt-key list | grep $keyid",
				logoutput   => on_failure,
			}
		}
		absent:  {
			exec { "Remove $keyid from apt keystore":
				path    => "/bin:/usr/bin",
				environment => "HOME=/root",
				command => "apt-key del $keyid",
				user    => "root",
				group   => "root",
				onlyif  => "apt-key list | grep $keyid",
			}
		}
		default: {
			fail "Invalid 'ensure' value '$ensure' for apt::key"
		}
	}
}

class apt::ppa-req {

	package { "python-software-properties":
		ensure => latest;
	}

}

# WARNING
# Third party repositories are generally *NOT* allowed to be used on
# Wikimedia production servers. This definition should therefore ONLY
# be used after consensus is reached on the trustability of the repo.
define apt::pparepo($repo_string = "", $apt_key = "", $dist = "lucid", $ensure = "present") {
	include apt::ppa-req

	$grep_for_key = "apt-key list | grep '^pub' | sed -r 's.^pub\\s+\\w+/..' | grep '^$apt_key'"

	exec { ["${name}_update_apt"]:
		command => '/usr/bin/apt-get update',
		require => File["/etc/apt/sources.list.d/${name}.list"]
	}

	case $ensure {
		present: {
			file { ["/etc/apt/sources.list.d/${name}.list"]:
				content => "deb http://ppa.launchpad.net/$repo_string/ubuntu $dist main\n",
				require => Package["python-software-properties"]
			}
			file { ["/root/${apt_key}.key"]:
				source => "puppet:///files/ppa/${apt_key}.key"
			}
			exec { "Import ${name} to apt keystore":
				path        => "/bin:/usr/bin",
				environment => "HOME=/root",
				command     => "apt-key add /root/${apt_key}.key",
				user        => "root",
				group       => "root",
				unless      => "$grep_for_key",
				logoutput   => on_failure,
				require     => File["/root/${apt_key}.key"]
			}
		}
		absent: {
			file { ["/etc/apt/sources.list.d/${name}.list"]:
				ensure => false;
			}
			exec { "Remove ${apt_key} from apt keystore":
				path    => "/bin:/usr/bin",
				environment => "HOME=/root",
				command => "apt-key del ${apt_key}",
				user    => "root",
				group   => "root",
				onlyif  => "$grep_for_key",
			}
		}
	}
}
