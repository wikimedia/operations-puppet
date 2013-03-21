# base.pp

import "decommissioning.pp"
import "generic-definitions.pp"
import "ssh.pp"
import "sudo.pp"
import "nagios.pp"
import "nrpe.pp"
import "../private/manifests/passwords.pp"
import "../private/manifests/contacts.pp"
import "../private/manifests/mail.pp"


# /var/run has moved to /run in newer Ubuntu versions.
# See: http://lwn.net/Articles/436012/
if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "11.10") >= 0 {
	$run_directory = '/run'
} else {
	$run_directory = '/var/run'
}


class base::access::dc-techs {
	# add account and sudoers rules for data center techs
	#include accounts::cmjohnson

	# hardy doesn't support sudoers.d; only do sudo_user for lucid and later
	if versioncmp($::lsbdistrelease, "10.04") >= 0 {
		sudo_user { [ "cmjohnson" ]: privileges => [
			'ALL = (root) NOPASSWD: /sbin/fdisk',
			'ALL = (root) NOPASSWD: /sbin/mdadm',
			'ALL = (root) NOPASSWD: /sbin/parted',
			'ALL = (root) NOPASSWD: /sbin/sfdisk',
			'ALL = (root) NOPASSWD: /usr/bin/MegaCli',
			'ALL = (root) NOPASSWD: /usr/bin/arcconf',
			'ALL = (root) NOPASSWD: /usr/bin/lshw',
			'ALL = (root) NOPASSWD: /usr/sbin/grub-install',
		]}
	}

}

class base::grub {
	# Disable the 'quiet' kernel command line option so console messages
	# will be printed.
	exec {
		"grub1 remove quiet":
			path => "/bin:/usr/bin",
			command => "sed -i '/^# defoptions.*[= ]quiet /s/quiet //' /boot/grub/menu.lst",
			onlyif => "grep -q '^# defoptions.*[= ]quiet ' /boot/grub/menu.lst",
			notify => Exec["update-grub"];
		"grub2 remove quiet":
			path => "/bin:/usr/bin",
			command => "sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/s/quiet splash//' /etc/default/grub",
			onlyif => "grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"' /etc/default/grub",
			notify => Exec["update-grub"];
	}

	# Ubuntu Precise Pangolin no longer has a server kernel flavour.
	# The generic flavour uses the CFQ I/O scheduler, which is rather
	# suboptimal for some of our I/O work loads. Override with deadline.
	# (the installer does this too, but not for Lucid->Precise upgrades)
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "12.04") >= 0 {
		exec {
			"grub1 iosched deadline":
				path => "/bin:/usr/bin",
				command => "sed -i '/^# kopt=/s/\$/ elevator=deadline/' /boot/grub/menu.lst",
				unless => "grep -q '^# kopt=.*elevator=deadline' /boot/grub/menu.lst",
				onlyif => "test -f /boot/grub/menu.lst",
				notify => Exec["update-grub"];
			"grub2 iosched deadline":
				path => "/bin:/usr/bin",
				command => "sed -i '/^GRUB_CMDLINE_LINUX=/s/\\\"\$/ elevator=deadline\\\"/' /etc/default/grub",
				unless => "grep -q '^GRUB_CMDLINE_LINUX=.*elevator=deadline' /etc/default/grub",
				onlyif => "test -f /etc/default/grub",
				notify => Exec["update-grub"];
		}
	}

	exec { "update-grub":
		refreshonly => true,
		path => "/bin:/usr/bin:/sbin:/usr/sbin"
	}
}

class base::puppet($server="puppet", $certname=undef) {

	include passwords::puppet::database

	package { [ "puppet", "facter", "coreutils" ]:
		ensure => latest;
	}

	# monitoring via snmp traps
	package { [ "snmp" ]:
		ensure => latest;
	}

	monitor_service { "puppet freshness": description => "Puppet freshness", check_command => "puppet-FAIL", passive => "true", freshness => 36000, retries => 1 ; }

	case $::realm {
		'production': {
			exec { "puppet snmp trap":
				command => "snmptrap -v 1 -c public nagios.wikimedia.org .1.3.6.1.4.1.33298 `hostname` 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
				path => "/bin:/usr/bin",
				require => Package["snmp"]
			}

			exec {	"neon puppet snmp trap":
					command => "snmptrap -v 1 -c public neon.wikimedia.org .1.3.6.1.4.1.33298 `hostname` 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
					path => "/bin:/usr/bin",
					require => Package["snmp"]
			}
		}
		'labs': {
			exec { "puppet snmp trap":
				command => "snmptrap -v 1 -c public nagios-main.pmtpa.wmflabs .1.3.6.1.4.1.33298 ${::instancename}.${::site}.wmflabs 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
				path => "/bin:/usr/bin",
				require => Package["snmp"]
			}
		}
	}

	file {
		"/etc/default/puppet":
			owner => root,
			group => root,
			mode  => 0444,
			source => "puppet:///files/puppet/puppet.default";
		"/etc/puppet/puppet.conf":
			owner => root,
			group => root,
			mode => 0444,
			ensure => file,
			notify => Exec["compile puppet.conf"];
		"/etc/puppet/puppet.conf.d/":
			owner => root,
			group => root,
			mode => 0550,
			ensure => directory;
		"/etc/puppet/puppet.conf.d/10-main.conf":
			owner => root,
			group => root,
			mode  => 0444,
			content => template("puppet/puppet.conf.d/10-main.conf.erb"),
			notify => Exec["compile puppet.conf"];
		"/etc/init.d/puppet":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/puppet.init";
		"/var/lib/puppet/lib/facter":
			owner => root,
			group => root,
			mode => 0555,
			require => Package['facter'],
			ensure => directory;
		"/var/lib/puppet/lib/facter/default_gateway.rb":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/puppet/default_gateway.rb";
	}

	if $::realm == "labs" {
		file {
			"/var/lib/puppet/lib/facter/projectgid.rb":
				owner => root,
				group => root,
				mode => 0755,
				source => "puppet:///files/puppet/projectgid.rb";
		}
	} else {
		file {
			"/var/lib/puppet/lib/facter/projectgid.rb":
				ensure => absent;
		}
	}
	# Compile /etc/puppet/puppet.conf from individual files in /etc/puppet/puppet.conf.d
	exec { "compile puppet.conf":
		path => "/usr/bin:/bin",
		command => "cat /etc/puppet/puppet.conf.d/??-*.conf > /etc/puppet/puppet.conf",
		refreshonly => true;
	}

	# Keep puppet running -- no longer. now via cron
	cron {
		restartpuppet:
			require => File[ [ "/etc/default/puppet" ] ],
			command => "/etc/init.d/puppet restart > /dev/null",
			user => root,
			# Restart every 4 hours to avoid the runs bunching up and causing an
			# overload of the master every 40 mins. This can be reverted back to a
			# daily restart after we switch to puppet 2.7.14+ since that version
			# uses a scheduling algorithm which should be more resistant to
			# bunching.
			hour => [0, 4, 8, 12, 16, 20],
			minute => 37,
			ensure => absent;
		remove-old-lockfile:
			require => Package[puppet],
			command => "[ -f /var/lib/puppet/state/puppetdlock ] && find /var/lib/puppet/state/puppetdlock -ctime +1 -delete",
			user => root,
			minute => 43,
			ensure => absent;
	}

	## do not use puppet agent
	service {"puppet":
		enable => false,
		ensure => stopped;
	}

	## run puppet by cron and
	## rotate puppet logs generated by cron
	$crontime = fqdn_rand(30)

	file {
		"/etc/cron.d/puppet":
			require => File[ [ "/etc/default/puppet" ] ],
			mode => 0444,
			owner => root,
			group => root,
			content => template("base/puppet.cron.erb");
		"/etc/logrotate.d/puppet":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/logrotate/puppet";
	}

	# Report the last puppet run in MOTD
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "9.10") >= 0 {
		file { "/etc/update-motd.d/97-last-puppet-run":
			source => "puppet:///files/misc/97-last-puppet-run",
			mode => 0555;
		}
	}
}

class base::remote-syslog {
	if ($::lsbdistid == "Ubuntu") and ($::hostname != "nfs1") and ($::hostname != "nfs2") {
		package { rsyslog:
			ensure => latest;
		}

		# remote syslog destination
		case $::realm {
			'production': {
				if( $::site != '(undefined)' ) {
					$syslog_remote_real = "syslog.${::site}.wmnet"
				}
			}
			'labs': {
				# Per labs project syslog:
				case $::instanceproject {
					'deployment-prep': {
						$syslog_remote_real = 'deployment-dbdump.pmtpa.wmflabs'
					}
					default: {
						$syslog_remote_real = 'i-000003a9.pmtpa.wmflabs:5544'
					}
				}
			}
		}

		$ensure_remote = $syslog_remote_real ? {
			''	=> absent,
			default	=> present,
		}

		file { "/etc/rsyslog.d/90-remote-syslog.conf":
			ensure => absent;
		}

		file { "/etc/rsyslog.d/30-remote-syslog.conf":
			ensure => $ensure_remote,
			require => Package[rsyslog],
			owner => root,
			group => root,
			mode => 0444,
			content => "*.info;mail.none;authpriv.none;cron.none	@${syslog_remote_real}\n",
		}

		service { rsyslog:
			require => Package[rsyslog],
			subscribe => File["/etc/rsyslog.d/30-remote-syslog.conf"],
			ensure => running;
		}
	}
}

class base::sysctl {
	if ($::lsbdistid == "Ubuntu") and ($::lsbdistrelease != "8.04") {
		exec { "/sbin/start procps":
			path => "/bin:/sbin:/usr/bin:/usr/sbin",
			refreshonly => true;
		}

		file { wikimedia-base-sysctl:
			name => "/etc/sysctl.d/50-wikimedia-base.conf",
			owner => root,
			group => root,
			mode => 0444,
			notify => Exec["/sbin/start procps"],
			source => "puppet:///files/misc/50-wikimedia-base.conf.sysctl"
		}

		# Disable IPv6 privacy extensions, we rather not see our servers hide
		file { "/etc/sysctl.d/10-ipv6-privacy.conf":
			ensure => absent
		}
	}
}

class base::standard-packages {
	$packages = [ "wikimedia-base", "wipe", "tzdata", "zsh-beta", "jfsutils",
				"xfsprogs", "wikimedia-raid-utils", "screen", "gdb", "iperf",
				"atop", "htop", "vim", "sysstat", "ngrep", "acct", "git-core" ]

	if $::lsbdistid == "Ubuntu" {
		package { $packages:
			ensure => latest;
		}

		if $::network_zone == "internal" {
			include nrpe
		}

		# Run lldpd on all >= Lucid hosts
		if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
			package { lldpd: ensure => latest; }
		}

		# DEINSTALL these packages
		package { [ "mlocate" ]:
			ensure => absent;
		}
	}
}

# Class: base::packages::emacs
#
# Installs emacs package
class base::packages::emacs {
	package { "emacs23":
		ensure => "installed",
		alias  => "emacs",
	}
}

class base::resolving {
	if ! $::nameservers {
		error("Variable $::nameservers is not defined!")
	}
	else {
		if $::realm != "labs" {
			file { "/etc/resolv.conf":
				owner => root,
				group => root,
				mode => 0444,
				content => template("base/resolv.conf.erb");
			}
		}
	}
}

class base::motd {
	# Remove the standard help text
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		file { "/etc/update-motd.d/10-help-text": ensure => absent; }
	}
}


# == Class base::monitoring::host
# Sets up base Nagios monitoring for the host.  This includes
# - ping
# - ssh
# - dpkg
# - disk space
# - raid
#
# Note that this class is probably already included for your node
# by the class base.  If you want to change the contact_group, set
# the variable $nagios_contact_group in your node definition.
# class base will use this variable as the $contact_group argument
# when it includes this class.
#
# == Parameters
# $contact_group - Nagios contact_group to use for notifications.
#                  contact groups are defined in contactgroups.cfg.  Default: "admins"
#
class base::monitoring::host($contact_group = "admins") {
	monitor_host { $hostname: group => $nagios_group, contact_group => $contact_group }
	monitor_service { "ssh": description => "SSH", check_command => "check_ssh", contact_group => $contact_group }

	case $::lsbdistid {
		Ubuntu: {
			# Need NRPE. Define as virtual resources, then the NRPE class can pull them in
			@monitor_service { "dpkg": description => "DPKG", check_command => "nrpe_check_dpkg", tag => nrpe }
		}
	}

	# Need NRPE. Define as virtual resources, then the NRPE class can pull them in
	@monitor_service { "disk space": description => "Disk space", check_command => "nrpe_check_disk_6_3", tag => nrpe, contact_group => $contact_group }
	@monitor_service { "raid": description => "RAID", check_command => "nrpe_check_raid", tag => nrpe, contact_group => $contact_group }
}

class base::decommissioned {
	if $::hostname in $decommissioned_servers {
		system_role { "base::decommissioned": description => "DECOMMISSIONED server" }
	}
}

class base::instance-upstarts {

	file {"/etc/init/ttyS0.conf":
		owner => root,
		group => root,
		mode => 0444,
		source => 'puppet:///files/upstart/ttyS0.conf';
	}

}

class base::instance-finish {

	if $::realm == "labs" {
		## The following causes a dependency cycle
		#Class["base::remote-syslog"] -> Class["base::instance-finish"]
		#file {
		#	"/etc/rsyslog.d/60-puppet.conf":
		#		ensure => absent,
		#		notify => Service[rsyslog];
		#}
		file {
			"/etc/init/runonce-fixpuppet.conf":
				ensure => absent;
		}
	}

}

class base::vimconfig {
	file { "/etc/vim/vimrc.local":
		owner => root,
		group => root,
		mode => 0444,
		source => "puppet:///files/misc/vimrc.local",
		ensure => present;
	}

	if $::lsbdistid == "Ubuntu" {
		# Joe is for pussies
		file { "/etc/alternatives/editor":
			ensure => "/usr/bin/vim"
		}
	}
}

class base::screenconfig {
	if $::lsbdistid == "Ubuntu" {
		file {  "/root/.screenrc":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/misc/screenrc",
			ensure => present;
		}
	}
}

class base::environment {
	case $::realm {
		'production': {
			exec { "uncomment root bash aliases":
				path => "/bin:/usr/bin",
				command => "sed -i '
						/^#alias ll=/ s/^#//
						/^#alias la=/ s/^#//
					' /root/.bashrc",
				onlyif => "grep -q '^#alias ll' /root/.bashrc"
			}

			file {
				"/etc/profile.d/mysql-ps1.sh":
					ensure => present,
					owner => root,
					group => root,
					mode => 0444,
					source => "puppet:///files/environment/mysql-ps1.sh";
			}
		} # /production
		'labs': {
			file {
				"/etc/bash.bashrc":
					content => template('environment/bash.bashrc'),
					owner => root,
					group => root,
					mode => 0444;
				"/etc/skel/.bashrc":
					content => template('environment/skel/bashrc'),
					owner => root,
					group => root,
					mode => 0644;
			}
			if( $::instancename ) {
				file { "/etc/wmflabs-instancename":
					owner => root,
					group => root,
					mode  => 0444,
					content => "${::instancename}\n" ;
				}
			}
		} # /labs
	}

	### Settings commons to all realms

	# Once upon a time provided by wikimedia-base debian package
	file { "/etc/wikimedia-site":
		owner => root,
		group => root,
		mode  => 0444,
		content => "${::site}\n" ;
	}

	file { "/etc/wikimedia-realm":
		owner => root,
		group => root,
		mode  => 0444,
		content => "${::realm}\n" ;
	}

}

#	Class: base::platform
#
#	This class implements hardware platform specific configuration
class base::platform {
	class common($lom_serial_port, $lom_serial_speed) {
		$console_upstart_file = "
# ${lom_serial_port} - getty
#
# This service maintains a getty on ${lom_serial_port} from the point the system is
# started until it is shut down again.

start on stopped rc RUNLEVEL=[2345]
stop on runlevel [!2345]

respawn
exec /sbin/getty -L ${lom_serial_port} ${$lom_serial_speed} vt102
"

		if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
			file { "/etc/init/${lom_serial_port}.conf":
				owner => root,
				group => root,
				mode => 0444,
				content => $console_upstart_file;
			}
			upstart_job { "${lom_serial_port}": require => File["/etc/init/${lom_serial_port}.conf"] }
		}
	}

	class generic {
		class dell {
			$lom_serial_port = "ttyS1"
		}

		class cisco {
			$lom_serial_port = "ttyS0"
			$lom_serial_speed = "115200"
		}

		class sun {
			$lom_serial_port = "ttyS0"
			$lom_serial_speed = "9600"

			# Udev rules for Solaris-style disk names
			@file {
				"/etc/udev/scripts":
					ensure => directory,
					tag => "thumper-udev";
				"/etc/udev/scripts/solaris-name.sh":
					source => "puppet:///files/udev/solaris-name.sh",
					owner => root,
					group => root,
					mode => 0555,
					tag => "thumper-udev";
				"/etc/udev/rules.d/99-thumper-disks.rules":
					require => File["/etc/udev/scripts/solaris-name.sh"],
					source => "puppet:///files/udev/99-thumper-disks.rules",
					owner => root,
					group => root,
					mode => 0444,
					notify => Exec["reload udev"],
					tag => "thumper-udev";
			}

			exec { "reload udev":
				command => "/sbin/udevadm control --reload-rules",
				refreshonly => true
			}
		}
	}

	class dell-c2100 inherits base::platform::generic::dell {
		$lom_serial_speed = "115200"

		class { "common": lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
	}

	class dell-r300 inherits base::platform::generic::dell {
		$lom_serial_speed = "57600"

		class { "common": lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
	}

	class sun-x4500 inherits base::platform::generic::sun {

		File <| tag == "thumper-udev" |>

		class { "common": lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
	}

	class sun-x4540 inherits base::platform::generic::sun {
		File <| tag == "thumper-udev" |>

		class { "common": lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
	}

	class cisco-C250-M1 inherits base::platform::generic::cisco {
		class { "common": lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
	}

	case $::productname {
		"PowerEdge C2100": {
			$startup_drives = [ "/dev/sda", "/dev/sdb" ]
		}
		"PowerEdge R300": {
			$startup_drives = [ "/dev/sda", "/dev/sdb"]
			include dell-r300
		}
		"Sun Fire X4500": {
			$startup_drives = [ "/dev/sdy", "/dev/sdac" ]
			include sun-x4500
		}
		"Sun Fire X4540": {
			$startup_drives = [ "/dev/sda", "/dev/sdi" ]
			include sun-x4540
		}
		"R250-2480805": {
			$startup_drives = [ "/dev/sda", "/dev/sdb" ]
			include cisco-C250-M1
		}
		default: {
			# set something so the logic doesn't puke
			$startup_drives = [ "/dev/sda", "/dev/sdb" ]
		}
	}
}

# handle syslog permissions (e.g. 'make common logs readable by normal users (RT-2712)')
class base::syslogs($readable = 'false') {

	$common_logs = [ "syslog", "messages" ]

	define syslogs::readable() {

		file { "/var/log/${name}":
			mode => '0644',
		}
	}

	if $readable == 'true' {
		syslogs::readable { $common_logs: }
	}
}


class base::tcptweaks {
	Class[base::puppet] -> Class[base::tcptweaks]

	file { "/etc/network/if-up.d/initcwnd":
		content => template("misc/initcwnd.erb"),
		mode => 0555,
		owner => root,
		group => root,
		ensure => present;
	}

	exec { "/etc/network/if-up.d/initcwnd":
		require => File["/etc/network/if-up.d/initcwnd"],
		subscribe => File["/etc/network/if-up.d/initcwnd"],
		refreshonly => true;
	}
}

class base {
	include	apt
	include apt::update

	if ($::realm == "labs") {
		include apt::unattendedupgrades,
			apt::noupgrade
	}

	include base::tcptweaks

	class { base::puppet:
		server => $::realm ? {
			'labs' => $::site ? {
				'pmtpa' => 'virt0.wikimedia.org',
				'eqiad' => 'virt1000.wikimedia.org',
			},
			default => "puppet",
		},
		certname => $::realm ? {
			# For labs, use instanceid.domain rather than the fqdn
			# to ensure we're always using a unique certname.
			# dc is an attribute from LDAP, it's set as the instanceid.
			'labs' => "${dc}.${domain}",
			default => undef,
		},
	}

	include	passwords::root,
		base::decommissioned,
		base::grub,
		base::resolving,
		base::remote-syslog,
		base::sysctl,
		base::motd,
		base::vimconfig,
		base::standard-packages,
		base::environment,
		base::platform,
		base::access::dc-techs,
		base::screenconfig,
		ssh,
		role::salt::minions


	# include base::monitor::host.
	# if $nagios_contact_group is set, then use it
	# as the monitor host's contact group.
	class { "base::monitoring::host":
		contact_group => $nagios_contact_group ? {
			undef   => "admins",
			default => $nagios_contact_group,
		}
	}

	if $::realm == "labs" {
		include base::instance-upstarts,
			generic::gluster-client

		# make common logs readable
		class {'base::syslogs': readable => 'true'; }

		# Add directory for data automounts
		file { "/data":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0755;
		}
		# Add directory for public (ro) automounts
		file { "/public":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0755;
		}
	}

}
