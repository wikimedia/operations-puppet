# geoip.pp
#
# Classes to manage installation and update of
# Maxmind GeoIP libraries and data files.
#
# To install geoip packages and ensure that you have up to date .dat files, just do
#   include geoip
#
# If you want to manage the installation of the .dat files yourself,
# use the geoip::data class.  The default provider is 'puppet', which means
# the .dat files will be synced from the puppetmaster.  A provider of 'maxmind'
# will download the files directly from maxmind.
#
# NOTE:  The $data_directory parameter (and a few others as well) are
# used multiple times in a few classes.  I have defined them each time
# with a default value so that you CAN use the lower level classes if you
# so choose without having to worry about specifying defaults.  This is
# less DRY than leaving off the default values in the low level classes,
# but meh?  If someone doesn't like this we can remove the default values
# from the low level classes.


# == Class geoip
# Installs Maxmind IP address Geocoding
# packages and database files (via puppet).
#
# This is the only class you need to include if
# you want to be able to use Maxmind GeoIP libs and data.
#
# == Parameters
# $data_directory - Where the GeoIP data files should live.  default: /usr/share/GeoIP
#
class geoip($data_directory = "/usr/share/GeoIP") {
	class { "geoip::packages":                                        }
	class { "geoip::data":          data_directory => $data_directory }
	class { "geoip::data::symlink": data_directory => $data_directory }
}


# == Class geoip::packages
# Installs GeoIP packages.
#
class geoip::packages {
	package { [ "libgeoip1", "libgeoip-dev", "geoip-bin" ]:
		ensure => present;
	}
}

# == Class geoip::packages::python
# Installs pygeoip package.
#
class geoip::packages::python {
	include geoip::packages

	package { "python-geoip":
		ensure  => present,
		require => Class["geoip::packages"],
	}
}

# == Class geoip::data::symlink
# sets up symlink from /usr/local/share/GeoIP
# to /usr/share/GeoIP.  Some scripts expect GeoIP
# databases to be in this location.
#
# == Parameters
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
#
class geoip::data::symlink($data_directory = "/usr/share/GeoIP") {
	file { "/usr/local/share/GeoIP":
		ensure  => "$data_directory",
		require => File["$data_directory"],
	}
}



# == Class geoip::data
# Conditionally includes either
# geoip::data::sync or geoip::data::download.
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
# Should just be includeing geoip to get the data files
# and geoip packages.
#
# == Parameters
# $provider       - either 'puppet' or 'maxmind'.      default: puppet.
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
# $config_file    - the config file for the geoipupdate command.  This will be put in place from puppet:///private/geoip/GeoIP.conf.  This will not be used if the provider is 'puppet'.  default: /etc/GeoIP.conf
# $source         - puppet file source for data_directory.  This is not used if provider is 'maxmind'. default: puppet:///volatile/GeoIP
# $environment    - the environment paramter to pass to exec and cron for the geoipupdate download command.  This will not be used if the provider is 'puppet'.  default: ''
#
class geoip::data(
	$provider       = "puppet",
	$data_directory = "/usr/share/GeoIP",
	$config_file    = "/etc/GeoIP.conf",
	$source         = "puppet:///volatile/GeoIP",
	$environment    = "") {

	# if installing data files from puppet, use
	# geoip::data::sync class
	if $provider == "puppet" {
		class { "geoip::data::sync":
			data_directory => $data_directory,
			source         => $source,
		}
	}

	# else install the files from the maxmind download
	# by including geoip::data::download
	else {
		class { "geoip::data::download":
			data_directory => $data_directory,
			config_file    => $config_file,
			environment    => $environment,
		}
	}

}



# == Class geoip::data::sync
# Installs GeoIP database files from puppetmaster.
#
# == Parameters
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
# $source         - A valid puppet source directory.   default: puppet:///volatile/GeoIP
#
class geoip::data::sync($data_directory = "/usr/share/GeoIP", $source = "puppet:///volatile/GeoIP") {
	# recursively copy the $data_directory from $source.
	file { "$data_directory":
		source  => "$source",
		recurse => true,
		backup => false
	}
}


# == Class geoip::data::download
# Installs Maxmind GeoIP database files by downloading
# them from Maxmind with the geoipupdate command.
# This also installs a cron job to do this weekly.
#
# == Parameters
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
# $config_file    - the config file for the geoipupdate command.  This will be put in place from puppet:///private/geoip/GeoIP.conf.  default: /etc/GeoIP.conf
# $environment    - the environment paramter to pass to exec and cron for the geoipupdate download command.  default: ''
#
class geoip::data::download($data_directory = "/usr/share/GeoIP", $config_file = "/etc/GeoIP.conf", $environment = "") {
	# Need this to get /usr/bin/geoipupdate installed.
	include geoip::packages

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
		environment => $environment,
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
		command     => "/bin/echo -en \"\$(/bin/date):\t\" >> /var/log/geoipupdate.log && $geoipupdate_command &>> /var/log/geoipupdate.log",
		environment => $environment,
		user        => root,
		weekday     => 0,
		hour        => 3,
		minute      => 30,
		ensure      => present,
		require     => [File["$config_file"], Package["geoip-bin"], File["$data_directory"]],
	}
}
