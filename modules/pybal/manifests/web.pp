# == Class pybal::web
#
# Writes down all the files to be served from config-master
# to expose the pybal conf file pools
#

class pybal::web ($datacenters, $root_dir, $ensure = 'present',) {

    # TODO: remove cleaned up.
    apache::site { 'pybal-config':
        ensure => absent,
    }


    $pools_dir = "${root_dir}/pybal"
    $dc_dirs = prefix($datacenters, "${root_dir}/")

    file { $pools_dir:
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

    file { '/usr/local/bin/pybal-eval-check':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/pybal/pybal-eval-check.py',
    }

    pybal::web::dc_pools { $datacenters: }
}
