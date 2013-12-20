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
