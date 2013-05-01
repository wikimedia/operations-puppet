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

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "9.10") >= 0 {
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
define systemuser($name, $home=undef, $managehome=true, $shell="/bin/false", $groups=undef, $default_group=$name, $ensure=present) {
	# FIXME: deprecate $name parameter in favor of just using $title

	if $default_group == $name {
		group { $default_group:
			name => $default_group,
			ensure => present;
		}
	}

	user { $name:
		require => Group[$default_group],
		name => $name,
		gid => $default_group,
		home => $home ? {
			undef => "/var/lib/${name}",
			default => $home
		},
		managehome => $managehome,
		shell => $shell,
		groups => $groups,
		system => true,
		ensure => $ensure;
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
define apache_module($name=$title) {
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


# Enables a certain Lighttpd config
#
# TODO:  ensure => false removes symlink.  ensure => purged removes available file.
define lighttpd_config($install="false") {
	# Reload lighttpd if the site config file changes.
	# This subscribes to both the real file and the symlink.
	exec { "lighttpd_reload_${title}":
		command     => "/usr/sbin/service service lighttpd reload",
		refreshonly => true,
	}

	if $install == "true" {
		file { "/etc/lighttpd/conf-available/${title}.conf":
			source => "puppet:///files/lighttpd/${title}.conf",
			owner => root,
			group => www-data,
			mode => 0444,
			before => File["/etc/lighttpd/conf-enabled/${title}.conf"],
			notify => Exec["lighttpd_reload_${title}"],
		}
	}

	# Create a symlink to the available config file
	# in the conf-enabled directory.  Notify
	file { "/etc/lighttpd/conf-enabled/${title}.conf":
		ensure => "/etc/lighttpd/conf-available/${title}.conf",
		notify => Exec["lighttpd_reload_${title}"],
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

# Create a symlink in /etc/init.d/ to a generic upstart init script

define upstart_job($install="false", $start="false") {
	# Create symlink
	file { "/etc/init.d/${title}":
		ensure => "/lib/init/upstart-job";
	}

	if $install == "true" {
		file { "/etc/init/${title}.conf":
			source => "puppet:///files/upstart/${title}.conf"
		}
	}

	if $start == "true" {
		exec { "start $title":
			require => File["/etc/init/${title}.conf"],
			subscribe => File["/etc/init/${title}.conf"],
			refreshonly => true,
			command => "start ${title}",
			path => "/bin:/sbin:/usr/bin:/usr/sbin"
		}
	}
}

# Expects address without a length, like address => "208.80.152.10", prefixlen => "32"
define interface_ip($interface, $address, $prefixlen="32") {
	$prefix = "${address}/${prefixlen}"
	$ipaddr_command = "ip addr add ${prefix} dev ${interface}"

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		# Use augeas to add an 'up' command to the interface
		augeas { "${interface}_${prefix}":
			context => "/files/etc/network/interfaces/*[. = '${interface}' and ./family = 'inet']",
			changes => "set up[last()+1] '${ipaddr_command}'",
			onlyif => "match up[. = '${ipaddr_command}'] size == 0";
		}
	}

	# Add the IP address manually as well
	exec { $ipaddr_command:
		path => "/bin:/usr/bin",
		returns => [0, 2]
	}
}

define interface_manual($interface, $family="inet") {
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
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
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		# Use augeas to add an 'up' command to the interface
		augeas { "${interface}_${title}":
			context => "/files/etc/network/interfaces/*[. = '${interface}']",
			changes => "set up[last()+1] '${command}'",
			onlyif => "match up[. = '${command}'] size == 0";
		}
	}
}

define interface_setting($interface, $setting, $value) {
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		# Use augeas to add an 'up' command to the interface
		augeas { "${interface}_${title}":
			context => "/files/etc/network/interfaces/*[. = '${interface}' and family = 'inet']",
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

class base::mwclient {
    package { python-mwclient: ensure => latest; }
}

define interface_tun6to4($remove=undef) {
	if $remove == 'true' {
		$augeas_cmd = [	"rm auto[./1 = 'tun6to4']",
				"rm iface[. = 'tun6to4']"
			]
	} else {
		$augeas_cmd = [	"set auto[./1 = 'tun6to4']/1 'tun6to4'",
				"set iface[. = 'tun6to4'] 'tun6to4'",
				"set iface[. = 'tun6to4']/family 'inet6'",
				"set iface[. = 'tun6to4']/method 'v4tunnel'",
				"set iface[. = 'tun6to4']/endpoint 'any'",
				"set iface[. = 'tun6to4']/local '192.88.99.1'",
				"set iface[. = 'tun6to4']/ttl '64'",
				"set iface[. = 'tun6to4']/pre-up 'ip address add 192.88.99.1/32 dev lo label lo:6to4'",
				"set iface[. = 'tun6to4']/down 'ip address del 192.88.99.1/32 dev lo label lo:6to4'",
				"set iface[. = 'tun6to4']/up 'ip -6 route add 2002::/16 dev \$IFACE'",
			]
	}

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		if $remove == 'true' {
			exec { "/sbin/ifdown tun6to4": before => Augeas["tun6to4"] }
		}

		# Use augeas
		augeas { "tun6to4":
			context => "/files/etc/network/interfaces/",
			changes => $augeas_cmd;
		}

		if $remove != 'true' {
			exec { "/sbin/ifup tun6to4": require => Augeas["tun6to4"] }
		}
	}
}

define interface_tagged($base_interface, $vlan_id, $address=undef, $netmask=undef, $family="inet", $method="static", $up=undef, $down=undef, $remove=undef) {
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
	if $down {
		$down_cmd = "set iface[. = '$intf']/down '$down'"
	} else {
		$down_cmd = ""
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
				$down_cmd,
			]
	}

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
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

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
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
			command => "/sbin/ifup --force $interface; /sbin/ip link set dev $interface up",
			require => Augeas["aggregate member ${interface}"],
			refreshonly => true
		}
	}
}

define interface_aggregate($orig_interface=undef, $members=[], $lacp_rate="fast", $hash_policy="layer2+3") {
	require base::bonding-tools

	# Use the definition title as the destination (aggregated) interface
	$aggr_interface = $title

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
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
				"set iface[. = '${aggr_interface}']/bond-xmit-hash-policy '${hash_policy}'"
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

define interface_add_ip6_mapped($interface=undef, $ipv4_address=undef) {
	if ! $interface {
		$all_interfaces = split($::interfaces, ",")
		$intf = $all_interfaces[0]
	}
	else {
		$intf = $interface
	}

	if ! member(split($::interfaces, ","), $intf) {
		warning("Not adding IPv6 address to $intf because this interface does not exist!")
	}
	else {
		if ! $ipv4_address {
			$ip4_address = "::${::ipaddress}"
		}
		else {
			$ip4_address = "::${ipv4_address}"
		}

		$ipv6_address = inline_template("<%= require 'ipaddr'; (IPAddr.new(scope.lookupvar(\"::ipaddress6_${intf}\")).mask(64) | IPAddr.new(ip4_address.gsub('.', ':'))).to_s() %>")

		interface_ip { $title:
			interface => $intf,
			address => $ipv6_address,
			prefixlen => "64"
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


# Class: generic::rsyncd
# Starts an rsyncd daemon.  Must specify either $config or $content.
#
# Usage:
#   class { "generic::rsyncd": config => "home" }   # will put files/rsync/rsyncd.conf.home at /etc/rsyncd.conf
#   class { "generic::rsyncd": content => template('udp2log/rsyncd.conf.erb) } # will render this .erb file at /etc/rsyncd.conf
#
# Parameters:
#   $config  - name of rsyncd.conf file to use from files/rsync/rsyncd.conf.$config
#   $content - content to render into /etc/rsyncd.conf
#
class generic::rsyncd($config = undef, $content = undef) {

	package { "rsync":
		ensure => latest;
	}

	# rsync daemon defaults file
	file { "/etc/default/rsync":
		require => Package[rsync],
		mode    => 0644,
		owner   => root,
		group   => root,
		source  => "puppet:///files/rsync/rsync.default",
		ensure  => present;
	}

	# rsyncd.conf, content either comes from source file or passed in content
	file { "/etc/rsyncd.conf":
		require => Package[rsync],
		mode    => 0644,
		owner   => root,
		group   => root,
		ensure  => present;
	}

	# if $config name was given, then use the file
	if $config {
		File["/etc/rsyncd.conf"] { source  => "puppet:///files/rsync/rsyncd.conf.$config" }
	}
	# else if using $content, just render the given content
	elsif $content {
		File["/etc/rsyncd.conf"] { content  => $content }
	}
	# else alert an error
	else {
		alert("generic::rsyncd '${title}' must specify one of \$config, \$content")
	}

	# start up the rsync daemon
	service { rsync:
		require   => [Package["rsync"], File["/etc/rsyncd.conf"], File["/etc/default/rsync"]],
		ensure    => running,
		subscribe => [File["/etc/rsyncd.conf"], File["/etc/default/rsync"]],
	}
}

class generic::gluster-client {

	package { "glusterfs-client":
		ensure => present;
	}

	file { "/etc/logrotate.d/glusterlogs":
		ensure => present,
		mode => '0664',
		source => "puppet:///files/logrotate/glusterlogs",
		owner => 'root',
	}

	# Gluster installs this but it doesn't work and breaks
	# the behavior of /etc/logrotate.d/glusterlogs.
	file { "/etc/logrotate.d/glusterfs-common":
		ensure => absent,
	}
}

class generic::gluster-server {

	package { "glusterfs-server":
		ensure => present;
	}

}

# The joe editor, which has some fans among labs users
class generic::packages::joe {
	package { "joe" : ensure => latest; }
}

# An utility to show up a file hierarcy using ASCII art
class generic::packages::tree {
	package { "tree" : ensure => present; }
}

# Definition: git::clone
#
# Creates a git clone of a specified origin into a top level directory.
#
# === Required parameters
#
# $+directory+:: path to clone the repository into.
# $+origin+:: Origin repository URL.
#
# === Optional parameters
#
# $+branch+:: Branch you would like to check out.
# $+ensure+:: _absent_, _present_, or _latest_.  Defaults to _present_.
#             - _present_ (default) will just clone once.
#             - _latest_ will execute a git pull if there are any changes.
#             - _absent_ will ensure the directory is deleted.
# $+owner+:: Owner of $directory, default: _root_.  git commands will be run by this user.
# $+group+:: Group owner of $directory, default: 'root'
# $+mode+:: Permission mode of $directory, default: 0755
# $+ssh+:: SSH command/wrapper to use when checking out, default: ''
# $+timeout+:: Time out in seconds for the exec command, default: 300
#
# === Example usage
#
#	git::clone{ "my_clone_name":
#		directory => "/path/to/clone/container",
#		origin    => "http://blabla.org/core.git",
#		branch    => "the_best_branch"
#	}
#
# Will clone +http://blabla.org/core.git+ branch +the_best_branch+ at +/path/to/clone/container/core+
define git::clone(
	$directory,
	$origin,
	$branch="",
	$ssh="",
	$ensure='present',
	$owner="root",
	$group="root",
	$timeout="300",
	$depth="full",
	$mode=0755) {

	case $ensure {
		"absent": {
			# make sure $directory does not exist
			file { $directory:
				ensure  => 'absent',
				recurse => true,
				force   => true,
			}
		}

		# otherwise clone the repository
		default: {
			# if branch was specified
			if $branch {
				$brancharg = "-b $branch "
			}
			# else don't checkout a non-default branch
			else {
				$brancharg = ""
			}
			if $ssh {
				$env = "GIT_SSH=$ssh"
			}

			$deptharg = $depth ?  {
				"full" => "",
				default => " --depth=$depth"
			}

			# set PATH for following execs
			Exec { path => "/usr/bin:/bin" }
			# clone the repository
			exec { "git_clone_${title}":
				command     => "git clone ${brancharg}${origin}${deptharg} $directory",
				logoutput   => on_failure,
				environment => $env,
				creates     => "$directory/.git/config",
				user        => $owner,
				group       => $group,
				timeout     => $timeout,
				require     => Package["git-core"],
			}

			# pull if $ensure == latest and if there are changes to merge in.
			if $ensure == "latest" {
				exec { "git_pull_${title}":
					cwd     => $directory,
					command => "git pull --quiet${deptharg}",
					logoutput => on_failure,
					# git diff --quiet will exit 1 (return false) if there are differences
					unless  => "git fetch && git diff --quiet remotes/origin/HEAD",
					user    => $owner,
					group   => $group,
					require => Exec["git_clone_${title}"],
				}
			}
		}
	}
}


define git::init($directory) {
	$suffix = regsubst($title, '^([^/]+\/)*([^/]+)$', '\2')

	exec {
		"git init ${title}":
			path => "/usr/bin:/bin",
			command => "git init",
			cwd => "${directory}/${suffix}",
			creates => "${directory}/${suffix}/.git/config",
			require => Package["git-core"];
	}
}


# Creating an apparmor service class
# so we can notify the service when
# apparmor files are changed by puppet.
# This probably isn't included in your
# class, so if you need to notify this
# service make sure you include it.
class generic::apparmor::service {
	service { "apparmor":
		ensure => 'running',
	}
}

# handle locales via puppet
class generic::packages::locales {
	package { "locales": ensure => latest; }
}

class generic::packages::ant18 {

  if ($::lsbdistcodename == "lucid") {
		# When specifying 'latest' for package 'ant' on Lucid it will actually
		# install ant1.7 which might not be the version we want. This is similar to
		# the various gcc version packaged in Debian, albeit ant1.7 and ant1.8 are
		# conflicting with each others.
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
	} else {
		# Ubuntu post Lucid ship by default with ant 1.8 or later
		package { ["ant"]: ensure => installed; }
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

# Define: sysctl
#
# Creates a file in /etc/sysctl.d to set sysctl settings, and reloads
# sysctl with the new settings.
#
# There are three ways to use this define.  You must specify one of
# $value, $content, or $source.  Not specifying one of these results
# in a parse failure.
#
# Usage 1: $value
#    sysctl { "net.core.rmem_max": value => 16777218 }
#
# Usage 2: $content
#    $rmem_max = 536870912
#    sysctl { "custom_rmem_max": content => template("sysctl/sysctl_rmemmax.erb") }
#
# Usage 3: $source
#    sysctl { "custom_rmem_max": source => "puppet:///files/misc/rmem_max.sysctl.conf" }
#
# Parameters:
#    $value         - Puts "$title = $value" in the sysctl.d file.
#    $content       - Puts this exact content in the sysctl.d file.
#    $source        - Puts the $source file at the sysctl.d file.
#    $ensure        - Either 'present' or 'absent'.  Default: 'present'.
#    $number_prefix - The load order prefix number in the sysctl.d filename.  Default '60'.  You probably don't need to change this.
#
define sysctl(
		$value         = undef,
		$content       = undef,
		$source        = undef,
		$ensure        = "present",
		$number_prefix = "60")
{
	$sysctl_file = "/etc/sysctl.d/${number_prefix}-${title}.conf"

	file { "$sysctl_file":
		mode   => 0444,
		owner  => "root",
		group  => "root",
		ensure => $ensure,
	}

	# if using $value, then set $title = $value in the sysctl.d file
	if $value {
		File[$sysctl_file] { content => "${title} = ${value}" }
	}
	# else just set the content
	elsif $content {
		File[$sysctl_file] { content => $content }
	}
	# else put the file in place from a source file.
	elsif $source {
		File[$sysctl_file] { source  => $source }
	}
	# if none of the above are defined, then throw a parse failure.
	else {
		alert("sysctl '${title}' must specify one of \$content, \$source or \$value.")
	}

	# Refresh sysctl if we are ensuring the sysctl.d file
	# exists.  NOTE:  I'm not sure how to reset the sysctl
	# value to its original if we ensure => absent.  For now,
	# that will have to wait until a reboot happens.  This
	# probably won't be a real problem anyway.  Anyone
	# using this define can just explicitly set the value
	# back to what it should be, rather than using ensure => 'absent'.
	if $ensure == 'present' {
		# refresh sysctl when the sysctl file changes
		exec { "sysctl_reload_${title}":
			command     => "/sbin/sysctl -p $sysctl_file",
			subscribe   => File["$sysctl_file"],
			refreshonly => true,
		}
	}
}

class generic::sysctl::high-http-performance($ensure="present") {
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		file { high-http-performance-sysctl:
			name => "/etc/sysctl.d/60-high-http-performance.conf",
			owner => root,
			group => root,
			mode => 0444,
			notify => Exec["/sbin/start procps"],
			source => "puppet:///files/misc/60-high-http-performance.conf.sysctl",
			ensure => $ensure
		}
	} else {
		alert("Distribution on $hostname does not support /etc/sysctl.d/ files yet.")
	}
}

class generic::sysctl::advanced-routing($ensure="present") {
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		file { advanced-routing-sysctl:
			name => "/etc/sysctl.d/50-advanced-routing.conf",
			owner => root,
			group => root,
			mode => 0444,
			notify => Exec["/sbin/start procps"],
			source => "puppet:///files/misc/50-advanced-routing.conf.sysctl",
			ensure => $ensure
		}
	} else {
		alert("Distribution on $hostname does not support /etc/sysctl.d/ files yet.")
	}
}

class generic::sysctl::advanced-routing-ipv6($ensure="present") {
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		file { advanced-routing-sysctl:
			name => "/etc/sysctl.d/50-advanced-routing-ipv6.conf",
			owner => root,
			group => root,
			mode => 0444,
			notify => Exec["/sbin/start procps"],
			source => "puppet:///files/misc/50-advanced-routing-ipv6.conf.sysctl",
			ensure => $ensure
		}
	} else {
		alert("Distribution on $hostname does not support /etc/sysctl.d/ files yet.")
	}
}

class generic::sysctl::ipv6-disable-ra($ensure="present") {
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		file { ipv6-disable-ra:
			name => "/etc/sysctl.d/50-ipv6-disable-ra.conf",
			owner => root,
			group => root,
			mode => 0444,
			notify => Exec["/sbin/start procps"],
			source => "puppet:///files/misc/50-ipv6-disable-ra.conf.sysctl",
			ensure => $ensure
		}
	} else {
		alert("Distribution on $hostname does not support /etc/sysctl.d/ files yet.")
	}
}

class generic::sysctl::lvs($ensure="present") {
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		file { lvs-sysctl:
			name => "/etc/sysctl.d/50-lvs.conf",
			mode => 0444,
			notify => Exec["/sbin/start procps"],
			source => "puppet:///files/misc/50-lvs.conf.sysctl",
			ensure => $ensure
		}
	} else {
		alert("Distribution on $hostname does not support /etc/sysctl.d/ files yet.")
	}
}

class generic::sysctl::high-bandwidth-rsync($ensure="present") {
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		file { high-bandwidth-rsync-sysctl:
			name => "/etc/sysctl.d/60-high-bandwidth-rsync.conf",
			mode => 0444,
			notify => Exec["/sbin/start procps"],
			source => "puppet:///files/misc/60-high-bandwidth-rsync.conf.sysctl",
			ensure => $ensure
		}
	} else {
		alert("Distribution on $hostname does not support /etc/sysctl.d/ files yet.")
	}
}

class generic::sysfs::enable-rps {
	upstart_job { "enable-rps": install => "true", start => "true" }
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

# python pip and virtualenv.
# only use this on development systems.
# in order to go to production, all dependencies need to come from debian packages, not pip.
class generic::pythonpip {
	package { [ "python-pip", "python-dev", "build-essential" ]:
		ensure => latest;
	}

	# pip could be in /usr/bin/ or in /usr/local/bin
	exec { "update_pip":
			command => "pip install --upgrade pip",
			path    => ["/usr/bin", "/usr/local/bin"],
			require => Package["python-pip"];
		"update_virtualenv":
			command => "pip install --upgrade virtualenv",
			path    => ["/usr/bin", "/usr/local/bin"],
			require => Package["python-pip"];
	}
}


class generic::wikidev-umask {

	# set umask to 0002 for wikidev users, per RT-804
	file {
		"/etc/profile.d/umask-wikidev.sh":
			ensure => present,
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/environment/umask-wikidev-profile-d.sh";
	}
	# if lucid or earlier /etc/profile would overwrite umask after incl. above
	# FIXME: remove this once fenari became precise or there is a new deploy host
	if versioncmp($::lsbdistrelease, "10.04") <= 0 {
		file {
				"/etc/profile":
				ensure => present,
				owner => root,
				group => root,
				source => "puppet:///files/environment/profile-deploy-host";
		}
	}
}
