# = Class: wdqs
# Note: this does not run the service, just installs it
# In order to run it, dump data must be loaded, which is
# for now a manual process.
#
# == Parameters:
# - $version: Version of the service to install
# - $username: Username owning the service
# - $package_dir:  Directory where the service should be installed.
# - $data_dir: Directory where the database should be stored
# - $log_dir: Directory where the logs go
class wdqs(
    $version,
    $username,
    $package_dir,
    $data_dir = $package_dir, 
    $log_dir = $package_dir,
	$logstash_
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

    file { $log_dir:
        ensure  => directory,
        purge   => false,
        owner   => $username,
        group   => 'wikidev',
        mode    => '0775',
        require => User['blazegraph'],
    }

    file { $data_dir:
        ensure  => directory,
        purge   => false,
        owner   => $username,
        group   => 'wikidev',
        mode    => '0775',
        require => User['blazegraph'],
    }
    
    # If we have data in separate dir, make link in package dir
    if $data_dir != $package_dir {
        file { "${package_dir}/wikidata.jnl":
            ensure  => link,
            target  => "${data_dir}/wikidata.jnl",
            require => [ File[$package_dir], File[$data_dir] ],
        }
    }

    user { 'blazegraph':
        ensure     => present,
        name       => $username,
        comment    => 'Blazegraph user',
        forcelocal => true,
        home       => $package_dir,
        managehome => no,
    }

    file { "${package_dir}/updater-logs.xml":
        ensure => present,
        content => template('wdqs/updater-logs.xml'),
        require => [ File[$log_dir], File[$package_dir] ]
    }
}
