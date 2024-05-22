# SPDX-License-Identifier: Apache-2.0
class ceph::radosgw {
    if defined(Ceph::Auth::Keyring['radosgw']) {
        Ceph::Auth::Keyring['radosgw'] -> Class['ceph::radosgw']
    }
    ensure_packages('radosgw')

    service { 'radosgw':
        ensure    => running,
        enable    => true,
        subscribe => File['/etc/ceph/ceph.conf'],
    }
}
