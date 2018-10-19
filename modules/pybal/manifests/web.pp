# == Class pybal::web
#
# Writes down all the files to be served from config-master
# to expose the pybal conf file pools
#

class pybal::web (
    Hash $services,
    Stdlib::Unixpath $root_dir,
    Wmflib::Ensure $ensure = 'present',
) {

    file { '/usr/local/bin/pybal-eval-check':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/pybal/pybal-eval-check.py',
    }

    $pools_dir = "${root_dir}/pybal"
    # All datacenters declared in all services
    $datacenters = unique(flatten($services.map |$k, $v| { $v[sites]}))
    $dc_dirs = prefix($datacenters, "${pools_dir}/")

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

    $services.each |$svc_name, $svc| {
        $svc['sites'].each |$dc| {
            # File path on disk, e.g. eqiad/text-https
            $svc_file = "${pools_dir}/${dc}/${svc_name}"
            pybal::conf_file { $svc_file:
                dc      => $dc,
                cluster => $svc['conftool']['cluster'],
                service => $svc['conftool']['service']
            }
        }
    }
}
