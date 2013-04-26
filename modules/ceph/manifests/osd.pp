class ceph::osd {
  Class['ceph::osd'] -> Class['ceph']

  package { ['parted', 'gdisk' ]:
    ensure => present,
  }

  ceph::bootstrap_key { 'ceph-osd':
    type    => 'osd',
  }

  file { '/usr/local/sbin/ceph-add-disk':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => 'puppet:///modules/ceph/ceph-add-disk',
  }

  file { '/var/lib/ceph/journal':
    ensure  => directory,
  }
}
