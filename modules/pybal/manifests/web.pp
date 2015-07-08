# == Class pybal::web
#
# Sets up the virtualhost and the other resources for serving the pybal configs.
#
# == Parameters
#
# [*chostname*]
# The ServerAlias hostname to add to the virtual host.
#

class pybal::web ($ensure = 'present', $vhostnames = ['pybal-config.eqiad.wmnet']) {

    apache::site { 'pybal-config':
        ensure   => $ensure,
        priority => 50,
        content  => template('pybal/config-vhost.conf.erb'),
        notify   => Service['apache2'],
        require  => File['/srv/pybal-config'],
    }

    file { '/srv/pybal-config':
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $conftool_dir = '/srv/pybal-config/conftool'
    $datacenters = hiera('datacenters')
    $dc_dirs = prefix($conftool_dir, $datacenters)

    file { $conftool_dir:
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # All the subdirectories
    file { $dc_dirs:
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $services = hiera('lvs::configuration::lvs_services')
    $service_names = keys($services)
    pybal::web::service { $service_names:
        config => $services
    }

}
