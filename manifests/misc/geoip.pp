# == Class misc::geoip
# Installs Maxmind IP address Geocoding
# packages and database files (via puppet).
#
# This is the only class you need to include if
# you want to be able to use Maxmind GeoIP libs and data.
#
# == Parameters
# $data_directory - Where the GeoIP data files should live.  default: /usr/share/GeoIP
#
class misc::geoip($data_directory = "/usr/share/GeoIP") {
	class { "misc::geoip::packages":                                        }
	class { "misc::geoip::data":          data_directory => $data_directory }
	class { "misc::geoip::data::symlink": data_directory => $data_directory }
}


# == Class misc::geoip::packages
# Installs GeoIP packages.
#
class misc::geoip::packages {
	package { [ "libgeoip1", "libgeoip-dev", "geoip-bin" ]:
		ensure => latest;
	}
}

# == Class misc::geoip::python::package
# Installs pygeoip package.
#
class misc::geoip::python::package {
	include misc::geoip::packages

	package { "python-geoip":
		ensure  => latest,
		require => Class["misc::geoip::packages"],
	}
}

# == Class misc::geoip::data::symlink
# sets up symlink from /usr/local/share/GeoIP
# to /usr/share/GeoIP.  Some scripts expect GeoIP
# databases to be in this location.
#
# == Parameters
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
#
class misc::geoip::data::symlink($data_directory = "/usr/share/GeoIP") {
	file { "/usr/local/share/GeoIP":
		ensure  => "$data_directory",
		require => File["$data_directory"],
	}
}



# == Class misc::geoip::data
# Conditionally includes either
# misc::geoip::data::sync or misc::geoip::data::download.
#
# The sync class assumes that the data files are
# available via puppet in puppet:///volatile/GeoIP/
#
# The download class runs geoipupdate to download the
# files from maxmind directly.
#
# Currently, source => 'maxmind' is only used by puppetmaster
# to download the files.  All other nodes get these files
# via the default source => 'puppet'.  You shouldn't have
# to worry about this as a user of GeoIP data anyway.  You
# Should just be includeing misc::geoip to get the data files
# and geoip packages.
#
# == Parameters
# $provider         - either 'puppet' or 'maxmind'.      default: puppet.
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
# $config_file    - the config file for the geoipupdate command.  This will be put in place from puppet:///private/geoip/GeoIP.conf.  This will not be used if the provider is 'puppet'.  default: /etc/GeoIP.conf
# $source         - puppet file source for data_directory.  This is not used if provider is 'maxmind'. default: puppet:///volatile/GeoIP
#
class misc::geoip::data(
	$provider       = "puppet",
	$data_directory = "/usr/share/GeoIP",
	$config_file    = "/etc/GeoIP.conf",
	$source         = "puppet:///volatile/GeoIP") {

	# if installing data files from puppet, use
	# misc::geoip::data::sync class
	if $source == "puppet" {
		class { "misc::geoip::data::sync":
			data_directory => $data_directory,
			source         => $source,
		}
	}

	# else install the files from the maxmind download
	# by including misc::geoip::data::download
	else {
		class { "misc::geoip::data::download":
			data_directory => $data_directory,
			config_file    => $config_file
		}
	}

}



# == Class misc::geoip::data::sync
# Installs GeoIP database files from puppetmaster.
#
# == Parameters
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
# $source         - A valid puppet source directory.   default: puppet:///volatile/GeoIP
#
class misc::geoip::data::sync($data_directory = "/usr/share/GeoIP", $source = "puppet:///volatile/GeoIP") {
	# recursively copy the $data_directory from $source.
	file { "$data_directory":
		source  => "$source",
		recurse => true,
	}
}


# == Class misc::geoip::data::download
# Installs Maxmind GeoIP database files by downloading
# them from Maxmind with the geoipupdate command.
# This also installs a cron job to do this weekly.
#
# == Parameters
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
# $config_file    - the config file for the geoipupdate command.  This will be put in place from puppet:///private/geoip/GeoIP.conf.  default: /etc/GeoIP.conf
#
class misc::geoip::data::download($data_directory = "/usr/share/GeoIP", $config_file = "/etc/GeoIP.conf") {
	# Need this to get /usr/bin/geoipupdate installed.
	include misc::geoip::packages

	# Install GeoIP.conf with Maxmind license keys.
	file { "$config_file":
		source => "puppet:///private/geoip/GeoIP.conf"
	}

	# Make sure the volatile GeoIP directory exists.
	# Data files will be downloaded by geoipupdate into
	# this directory.
	file { "$data_directory":
		ensure => "directory",
	}

	# command to run to update the GeoIP database files
	$geoipupdate_command = "/usr/bin/geoipupdate -f $config_file -d $data_directory"

	# Go ahead and exec geoipupdate now, so that
	# we can be sure we have these files if
	# this is the first time puppetmaster is
	# running this class.
	exec { "geoipupdate":
		command     => "$geoipupdate_command",
		refreshonly => true,
		subscribe   => File["$config_file"],
		require     => [Package["geoip-bin"], File["$data_directory"]],
	}

	# Set up a cron to run geoipupdate weekly.
	# This will download GeoIP.dat and GeoIPCity.dat
	# into /usr/share/GeoIP.  If there are other
	# Maxmind .dat files you want, then
	# modify GeoIP.conf and add the Maxmind
	# product IDs for those files.
	cron { "geoipupdate":
		command => "$geoipupdate_command",
		user    => root,
		weekday => 0,
		hour    => 3,
		minute  => 30,
		ensure  => present,
		require => [File["$config_file"], Package["geoip-bin"], File["$data_directory"]],
	}
}
