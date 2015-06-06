# = Class: wdqs
# Note: this does not run the service, just installs it
# In order to run it, dump data must be loaded, which is
# for now a manual process.
#
# == Parameters:
# - $version: Version of the service to install
# - $package_dir:  Directory where the service should be installed.
# Should have enough space to hold the database (>50G)
# - $username: Username owning the service
#
class wdqs(
    $version,
    $package_dir = '/srv',
    $username    = 'blazegraph',
) {
    include ::wdqs::packages

    class { '::wdqs::service':
        package_dir => $package_dir,
        version     => $version,
        username    => $username,
    }

    file { $package_dir:
        ensure  => directory,
        purge   => false,
        owner   => $username,
        group   => 'wikidev',
        mode    => '0775',
        require => User['blazegraph'],
    }

    file { "$package_dir/logs":
        ensure  => directory,
        purge   => false,
        owner   => $username,
        group   => 'wikidev',
        mode    => '0775',
        require => User['blazegraph'],
    }

    user { 'blazegraph':
        ensure     => present,
        name       => $username,
        comment    => 'Blazegraph user',
        forcelocal => true,
        home       => $package_dir,
        managehome => no,
    }

    file { "${package_dir}/blazegraph":
        ensure  => link,
        # do not replace existing links, version upgrade is manual for now
        replace => false,
        target  => "${package_dir}/service-${version}",
        require => File["${package_dir}/service-${version}"]
    }
	
	file { "${package_dir}/blazegraph/updater-logs.xml":
		ensure => present,
		content => template('wdqs/updater-logs.xml'),
		require => [ File["$package_dir/logs"], File["${package_dir}/blazegraph"] ]
	}
}
