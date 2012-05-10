# Installs maxmind IP address Geocoding 
# packages and database files.
#
# Just include misc::geoip

class misc::geoip {
	include misc::geoip::packages
	include misc::geoip::data
	include misc::geoip::data::symlink
}

# Installs geoip .deb packages.
class misc::geoip::packages {
	package { [ "libgeoip1", "libgeoip-dev", "geoip-bin" ]:
		ensure => latest;
	}
}

# Installs pygeoip package.
class misc::geoip::python::package {
	package { "python-geoip": ensure => latest }
}

# Installs GeoIP database files.
class misc::geoip::data {
	require misc::geoip::packages

	file {
		"/usr/share/GeoIP/GeoIP.dat":
			mode => 0644,
			owner => root,
			group => root,
			source => "puppet:///volatile/misc/GeoIP.dat";
		"/usr/share/GeoIP/GeoIPCity.dat":
			mode => 0644,
			owner => root,
			group => root,
			source => "puppet:///volatile/misc/GeoIPcity.dat";
	}
}

# sets up symlink from /usr/local/share/GeoIP 
# to /usr/share/GeoIP.  Some scripts expect GeoIP 
# databases to be in this location.
class misc::geoip::data::symlink {
	require misc::geoip::data
	
	file { "/usr/local/share/GeoIP":
		ensure => "/usr/share/GeoIP"
	}
}





# This class was not included anywhere.
# I am putting it here for historical reasons.
# We have a full version of GeoIPCity.dat, so 
# I assume that Erik would prefer to use that
# one rather than the GeoIPLite.  If this is wrong,
# we can fix it later.
# Rather than using a custom cron job here to 
# download and update  the GeoIP database files,
# we will rely on puppetmaster.pp updategeoipdb cron
# to update these files.


# # RT 2164
# class misc::statistics::geoip {
# 
# 	file {
# 		"/usr/local/share/GeoIP":
# 			owner => root,
# 			group => wikidev,
# 			mode => 0770,
# 			ensure => directory;
# 		"/usr/local/bin/`":
# 			owner => root,
# 			group => wikidev,
# 			mode => 0750,
# 			source => "puppet:///files/misc/geoiplogtag",
# 			ensure => present;
# 		"/usr/local/bin/update-maxmind-geoip-lib":
# 			owner => root,
# 			group => wikidev,
# 			mode => 0750,
# 			source => "puppet:///files/misc/update-maxmind-geoip-lib",
# 			ensure => present;
# 	}
# 
# 	cron {
# 		"update-maxmind-geoip-lib":
# 			ensure => present,
# 			user => ezachte,
# 			command => "/usr/local/bin/update-maxmind-geoip-lib",
# 			monthday => 1,
# 			require => File['/usr/local/bin/update-maxmind-geoip-lib'];
# 	}
# }
