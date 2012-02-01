# generic-definitions.pp
#
# File that contains generally useful definitions, e.g. for creating system users

# Prints a MOTD message about the role of this system
define system_role($description, $ensure=present) {
	$role_script_content = "#!/bin/sh

echo \"$(hostname) is a Wikimedia ${description} (${title}).\"
"

	$rolename = regsubst($title, ":", "-", "G")
	$motd_filename = "/etc/update-motd.d/05-role-${rolename}"

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "9.10") >= 0 {
		file { $motd_filename:
			owner => root,
			group => root,
			mode => 0555,
			content => $role_script_content,
			ensure => $ensure;
		}
	}
}

# Creates a system username with associated group, random uid/gid, and /bin/false as shell
define systemuser($name, $home=undef, $shell="/bin/false", $groups=undef) {
	group { $name:
		name => $name,
		ensure => present;
	}

	user { $name:
		require => Group[$name],
		name => $name,
		gid => $name,
		home => $home ? {
			undef => "/var/lib/${name}",
			default => $home
		},
		managehome => true,
		shell => $shell,
		groups => $groups,
		ensure => present;
	}
}

# Enables a certain Apache 2 site
define apache_site($name, $prefix="", $ensure="link") {
	file { "/etc/apache2/sites-enabled/${prefix}${name}":
		target => "/etc/apache2/sites-available/$name",
		ensure => $ensure;
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

define apache_confd($install="false", $enable="true", $ensure="present") {
	case $install {
		"true": {
			file { "/etc/apache2/conf.d/${name}":
				source => "puppet:///files/apache/conf.d/${name}",
				mode => 0444,
				ensure => $ensure;
			}
		}
		"template": {
			file { "/etc/apache2/conf.d/${name}":
				content => template("apache/conf.d/${name}.erb"),
				mode => 0444,
				ensure => $ensure;
			}
		}
	}
}

class generic::apache::no-default-site {
	file { "/etc/apache2/sites-enabled/000-default":
		ensure => absent;
	}
}

# Enables a certain Lighttpd config
define lighttpd_config($install="false") {
	if $install == "true" {
		file { "/etc/lighttpd/conf-available/${title}.conf":
			source => "puppet:///files/lighttpd/${title}.conf",
			owner => root,
			group => www-data,
			mode => 0444,
			before => File["/etc/lighttpd/conf-enabled/${title}.conf"];
		}
	}

	file { "/etc/lighttpd/conf-enabled/${title}.conf":
		ensure => "/etc/lighttpd/conf-available/${title}.conf";
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

define generic::apt::pin-package($pin="release o=Ubuntu", $priority="1001", $package="") {
	if $package == "" {
		$packagename = $title
	} else {
		$packagename = $package
	}
	$packagepin = "
Package: ${packagename}
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

class base::bonding-tools {
	package { ["ifenslave-2.6", "ethtool"] : ensure => latest; }
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

define interface_aggregate_member($master) {
	require base::bonding-tools

	$interface = $title

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
		augeas { "aggregate member ${interface}":
			context => "/files/etc/network/interfaces/",
			changes => [
					"set auto[./1 = '$interface']/1 '$interface'",
					"set iface[. = '$interface'] '$interface'",
					"set iface[. = '$interface']/family 'inet'",
					"set iface[. = '$interface']/method 'manual'",
			],
			notify => Exec["ifup $interface"]
		}

		exec { "ifup $interface":
			command => "/sbin/ifup --force $interface",
			require => Augeas["aggregate member ${interface}"],
			refreshonly => true
		}
	}
}

define interface_aggregate($orig_interface=undef, $members=[], $lacp_rate="fast") {
	require base::bonding-tools

	# Use the definition title as the destination (aggregated) interface
	$aggr_interface = $title

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
		if $orig_interface != "" {
			# Convert an existing interface, e.g. from eth0 to bond0
			$augeas_changes = [
				"set auto[./1 = '${orig_interface}']/1 '${aggr_interface}'",
				"set iface[. = '${orig_interface}'] '${aggr_interface}'"
			]

			# Bring down the old interface after conversion
			exec { "ip addr flush dev ${orig_interface}":
				command => "/sbin/ip addr flush dev ${orig_interface}",
				before => Exec["ifup ${aggr_interface}"],
				subscribe => Augeas["create $aggr_interface"],
				refreshonly => true,
				notify => Exec["ifup ${aggr_interface}"]
			}
		} else {
			$augeas_changes = [
				"set auto[./1 = '${aggr_interface}']/1 '${aggr_interface}'",
				"set iface[. = '${aggr_interface}'] '${aggr_interface}'",
				"set iface[. = '${aggr_interface}']/family 'inet'",
				"set iface[. = '${aggr_interface}']/method 'manual'"
			]
		}

		augeas { "create $aggr_interface":
			context => "/files/etc/network/interfaces/",
			changes => $augeas_changes,
			onlyif => "match iface[. = '${aggr_interface}'] size == 0",
			notify => Exec["ifup ${aggr_interface}"]
		}

		augeas { "configure $aggr_interface":
			require => Augeas["create $aggr_interface"],
			context => "/files/etc/network/interfaces/",
			changes => [
				inline_template("set iface[. = '<%= aggr_interface %>']/bond-slaves '<%= members.join(' ') %>'"),
				"set iface[. = '${aggr_interface}']/bond-mode '802.3ad'",
				"set iface[. = '${aggr_interface}']/bond-lacp-rate '${lacp_rate}'",
				"set iface[. = '${aggr_interface}']/bond-miimon '100'",
				"set iface[. = '${aggr_interface}']/bond-xmit-hash-policy 'layer2+3'"
			],
			notify => Exec["ifup ${aggr_interface}"]
		}

		# Define all aggregate members
		interface_aggregate_member{ $members:
			require => Augeas["create $aggr_interface"],
			master => $aggr_interface,
			notify => Exec["ifup ${aggr_interface}"]
		}

		# Bring up the new interface
		exec { "ifup ${aggr_interface}":
			command => "/sbin/ifup --force ${aggr_interface}",
			require => Interface_aggregate_member[$members],
			refreshonly => true
		}
	}
}

# Definition: interface_offload
#
# Sets interface offload parameters (with ethtool)
#
# Parameters:
# - $interface:
#	The network interface to operate on
# - $setting:
#	The (abbreviated) offload setting, e.g. 'gro'
# - $value:
#	The value (on/off)
define interface_offload($interface="eth0", $setting, $value) {
	# Set in /etc/network/interfaces
	interface_setting { $title: interface => $interface, setting => "offload-${setting}", value => $value }

	# And make sure it's always active
	$long_param = $setting ? {
		'rx' => "rx-checksumming",
		'tx' => "tx-checksumming",
		'sg' => "scatter-gather",
		'tso' => "tcp-segmentation-offload",
		'ufo' => "udp-fragmentation-offload",
		'gso' => "generic-segmentation-offload",
		'gro' => "generic-receive-offload",
		'lro' => "large-receive-offload"
	}

	exec { "ethtool ${interface} -K ${setting} ${value}":
		path => "/usr/bin:/usr/sbin:/bin:/sbin",
		command => "ethtool -K ${interface} ${setting} ${value}",
		unless => "test $(ethtool -k ${interface} | awk '/${long_param}:/ { print \$2 }') = '${value}'"
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

class generic::gluster {

	package { "glusterfs":
		ensure => latest;
	}

}

define gluster::server::peer {

	$host_uuid = generate("/usr/local/bin/uuid-generator", "${tag}")
	file {
		"/etc/glusterd/peers/${host_uuid}":
			content =>
"uuid=${host_uuid}
state=3
hostname1=${tag}
",
			notify => Service["glusterd"],
			require => Package["glusterfs"];

	}

}

class generic::packages::git-core {
	package { "git-core": ensure => latest; }
}

# Definition: git::clone
# Creates a git clone of a specified origin into a top level directory
#
# Parameters:
# - $title
#		Should be the repository name
# $branch
# 	Branch you would like to check out
#
define git::clone($directory, $branch="", $origin) {
	require generic::packages::git-core

	$suffix = regsubst($title, '^([^/]+\/)*([^/]+)$', '\2')

	if $branch {
		$brancharg = "-b $branch "
	}
	else {
		$brancharg = ""
	}

	Exec {
		path => "/usr/bin:/bin",
		cwd => $directory
	}
	exec {
		"git clone ${title}":
			command => "git clone ${brancharg}${origin}",
			creates => "${directory}/${suffix}/.git/config";
	}
}

define git::init($directory) {
	require generic::packages::git-core

	$suffix = regsubst($title, '^([^/]+\/)*([^/]+)$', '\2')

	exec {
		"git init ${title}":
			path => "/usr/bin:/bin",
			command => "git init",
			cwd => "${directory}/${suffix}",
			creates => "${directory}/${suffix}/.git/config";
	}
}

class generic::mysql::client {
	# This conflicts with class mysql::packages.  DO NOT use them together
	package { "mysql-client-5.1":
		ensure => latest;
	}
}

# handle locales via puppet
class generic::packages::locales {
	package { "locales": ensure => latest; }
}

class generic::packages::ant18 {
	# When specifying 'latest' for package 'ant', it will actually install
	# ant1.7 which might not be the version we want. This is similar to
	# the various gcc version packaged in Debian, albeit ant1.7 and ant1.8
	# are conflicting with each others.
	# Thus, this let us explicitly install ant version 1.8
	package { [
		"ant1.8"
	]: ensure => installed;
	}
	package { [
		"ant",
		"ant1.7"
	]: ensure => absent;
	}
}

class generic::packages::maven {
	# Install Apache Maven, a java build processing tool.
	# Class can later be used to add additional Maven plugins
	# http://maven.apache.org/
	package { [
		"maven2"
	]: ensure => latest;
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
	} else {
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

class generic::sysctl::ipv6-disable-ra($ensure="present") {
	if $lsbdistrelease != "8.04" {
		file { ipv6-disable-ra:
			name => "/etc/sysctl.d/50-ipv6-disable-ra.conf",
			owner => root,
			group => root,
			mode => 444,
			notify => Exec["/sbin/start procps"],
			source => "puppet:///files/misc/50-ipv6-disable-ra.conf.sysctl",
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

# this installs a bunch of international locales, f.e. for "planet" on singer
class generic::locales::international {

	require generic::packages::locales

	file { "/var/lib/locales/supported.d/local":
		source => "puppet:///files/locales/local_int",
		owner => "root",
		group => "root",
		mode => 0444;
	}

	exec { "/usr/sbin/locale-gen":
		subscribe => File["/var/lib/locales/supported.d/local"],
		refreshonly => true,
		require => File["/var/lib/locales/supported.d/local"];
	}
}

# Definition: generic::debconf::set
# Changes a debconf value
#
# Parameters:
# - $title
#		Debconf setting, e.g. mailman/used_languages
# - $value
#		The value $title should be set to
define generic::debconf::set($value) {
	exec { "debconf-communicate set $title":
		path => "/usr/bin:/usr/sbin:/bin:/sbin",
		command => "echo set ${title} \"${value}\" | debconf-communicate",
		unless => "test \"$(echo get ${title} | debconf-communicate)\" = \"0 ${value}\""
	}
}
