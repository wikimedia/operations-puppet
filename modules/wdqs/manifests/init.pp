# = Class: wdqs
# Note: this does not run the service, just installs it
# In order to run it, dump data must be loaded, which is 
# for now a manual process. 
#
# == Parameters:
# - $package_dir:  Directory where the service should be installed.
# Should have enough space to hold the database (>50G)
# - $username: Username owning the service
class wdqs($package_dir = "/srv", 
	$username = "blazegraph"
) {
	$version = "0.0.2" # here for now, find better place

    include ::wdqs::packages
    class { '::wdqs::service':
		package_dir => $package_dir,
		version => $version,
		username => $username,
	}
	
	file { $package_dir:
		path => $package_dir,
		ensure => directory,
		purge => false,
		owner => $username,
		group => 'wikidev',
		mode => 0775,
		require => User['blazegraph'],
	}
	
	user { 'blazegraph':
		name => $username,
		ensure => present,
		comment => 'Blazegraph user',
		forcelocal => true,
		home => $package_dir,
		managehome => no,
	}
	
	file { "$package_dir/blazegraph":
		ensure => link,
		replace => false, # do not replace existing links, version upgrade is manual for now
		target => "$package_dir/service-$version",
		require => File["$package_dir/service-$version"]
	}
	
}

