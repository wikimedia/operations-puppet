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
define nginx_site($install=false, $template="", $enable=true) {
	if ( $template == "" ) {
		$template_name = $name
	} else {
		$template_name = $template
	}
	if ( $enable == true ) {
		file { "/etc/nginx/sites-enabled/${name}":
			ensure => "/etc/nginx/sites-available/${name}",
		}
	} else {
		file { "/etc/nginx/sites-enabled/${name}":
			ensure => absent;
		}
	}

	case $install {
	true: {
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

class generic::gluster-client {

	package { "glusterfs-client":
		ensure => present;
	}

    file { [ '/var/log/glusterfs', '/var/log/glusterfs/bricks' ]:
        ensure => directory,
        before => File['/etc/logrotate.d/glusterlogs'],
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

class generic::sysfs::enable-rps {
	upstart_job { "enable-rps": install => "true", start => "true" }
}

# this installs a bunch of international locales, f.e. for "planet" on singer
class generic::locales::international {

	package { 'locales':
		ensure => latest;
	}

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
}


class generic::higher_min_free_kbytes {
	# Set a high min_free_kbytes watermark.
	# See https://wikitech.wikimedia.org/wiki/Dataset1001#Feb_8_2012
	# FIXME: Is this setting appropriate to the nodes on which it is applied? Is
	# the value optimal? Investigate.
	sysctl::parameters { 'higher_min_free_kbytes':
		values => {
			'vm.min_free_kbytes' => 1024 * 256,
		},
	}
}
