class ceph::mds {
    Class['ceph'] -> Class['ceph::mds']

    ceph::bootstrap_key { 'ceph-mds':
        type    => 'mds',
    }
}
