# generic-definitions.pp
#
# File that contains generally useful definitions, e.g. for creating system users

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
