class profile::codesearch (
    Stdlib::Unixpath $base_dir = lookup('profile::codesearch::base_dir'),
    Hash[String, Integer] $ports = lookup('profile::codesearch::ports'),
) {

    ferm::conf { 'docker-preserve':
        ensure => present,
        prio   => 20,
        source => 'puppet:///modules/codesearch/ferm/docker-preserve.conf',
    }

    ferm::service { 'codesearch':
        proto => 'tcp',
        port  => '3002',
    }

    class { '::codesearch':
        base_dir => $base_dir,
        ports    => $ports,
    }
}
