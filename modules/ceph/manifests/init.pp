class ceph(
  $admin_key,
  $config={},
) {
  package { [ 'ceph', 'ceph-dbg' ]:
    ensure => present,
  }

  file { '/etc/ceph/ceph.conf':
    ensure  => present,
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    content => template('ceph/ceph.conf.erb'),
    require => Package['ceph'],
  }

  exec { 'ceph client.admin':
    command => "/usr/bin/ceph-authtool /etc/ceph/ceph.client.admin.keyring \
                --create-keyring --name=client.admin \
                --add-key=${admin_key}",
    creates => '/etc/ceph/ceph.client.admin.keyring',
    require => Package['ceph'],
  }
}
