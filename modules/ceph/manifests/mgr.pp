# Class: ceph::mgr
#
# This class manages the Ceph manager
#
# Parameters
#    - $data_dir
#        Path to the base Ceph data directory
class ceph::mgr(
    Stdlib::Unixpath $data_dir,
) {
    Class['ceph::admin'] -> Class['ceph::mgr']

    # If the daemon hasn't been setup yet, first verify we can connect to the ceph cluster
    exec { 'ceph-mgr-check':
        command => '/usr/bin/ceph -s',
        onlyif  => "/usr/bin/test ! -e ${data_dir}/mgr/ceph-${::hostname}/keyring",
        require => Ceph::Keyring['client.admin'],
    }

    file { "${data_dir}/mgr/ceph-${::hostname}":
        ensure => 'directory',
        owner  => 'ceph',
        group  => 'ceph',
        mode   => '0750',
    }

    ceph::keyring { "mgr.${::hostname}":
        cap_mon => 'allow profile mgr',
        cap_osd => 'allow *',
        cap_mds => 'allow *',
        keyring => "${data_dir}/mgr/ceph-${::hostname}/keyring",
        require => Exec['ceph-mgr-check'],
    }

    service { "ceph-mgr@${::hostname}":
        ensure    => running,
        enable    => true,
        require   => Ceph::Keyring["mgr.${::hostname}"],
        subscribe => File['/etc/ceph/ceph.conf'],
    }
}
