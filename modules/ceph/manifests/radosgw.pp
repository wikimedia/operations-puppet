# SPDX-License-Identifier: Apache-2.0
class ceph::radosgw {
    if defined(Ceph::Auth::Keyring['radosgw']) {
        Ceph::Auth::Keyring['radosgw'] -> Class['ceph::radosgw']
    }
    ensure_packages('radosgw')

    service { 'ceph-radosgw@radosgw':
        ensure    => running,
        enable    => true,
        subscribe => File['/etc/ceph/ceph.conf'],
    }

    systemd::syslog { 'radosgw':
        force_stop   => true,
        base_dir     => '/var/log/ceph',
        owner        => 'ceph',
        group        => 'ceph',
        readable_by  => 'group',
        log_filename => 'radosgw.log',
        require      => Package['radosgw'],
    }
}
