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
    $log_dir = $package_dir
) {
    include ::wdqs::packages

    class { '::wdqs::service':
    }

    file { $package_dir:
        ensure  => present,
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

    # If we have data in separate dir, make link in package dir
    if $data_dir != $package_dir {
        file { $data_dir:
            ensure  => directory,
            purge   => false,
            owner   => $username,
            group   => 'wikidev',
            mode    => '0775',
            require => User['blazegraph'],
        }
    
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
#        home       => $package_dir,
        managehome => no,
    }

    file { "${package_dir}/updater-logs.xml":
        ensure  => present,
        content => template('wdqs/updater-logs.xml'),
        require => [ File[$log_dir], File[$package_dir] ]
    }
    
    # Blazegraph service
    base::service_unit { 'wdqs-blazegraph':
        template_name => 'wdqs-blazegraph',
        systemd => true,
        require => [
          Class['::wdqs::service'],
        ],
    }
    
    # WDQS Updater service
    $updater_options = hiera('wdqs::updater_options', '-n wdq -s')
    # Disabled as we don't want to start updater immediateely
    # FIXME: can we tell service_unit that?
    # base::service_unit { 'wdqs-updater':
    #     template_name => 'wdqs-updater',
    #     systemd => true,
    #     require => [
    #       File["${package_dir}/updater-logs.xml"],
    #       Class['::wdqs::service'],
    #       Service['wdqs-blazegraph'],
    #     ],
    #     service_params => {
    #         enable => false,
    #     },
    # }
    file {'/etc/systemd/system/wdqs-updater.service':
        ensure  => present,
        content => template('wdqs/initscripts/wdqs-updater.systemd.erb'),
        mode    => '0444',
        owner   => root,
        group   => root,
        require => [ File["${package_dir}/updater-logs.xml"], Service['wdqs-blazegraph'] ],
    }
    
}
