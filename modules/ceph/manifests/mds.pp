class ceph::mds {
  Class['ceph::mds'] -> Class['ceph']

  ceph::bootstrap_key { 'ceph-mds':
    type    => 'mds',
  }

  # FIXME: stub, add more
}
