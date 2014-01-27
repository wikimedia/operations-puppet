class { 'openstack::compute':
  cinder_db_password   => 'password',
  fixed_range          => '192.168.101.64/28',
  glance_api_servers   => '192.168.1.1:9292',
  internal_address     => $::ipaddress_eth1,
  libvirt_type         => 'qemu',
  nova_db_password     => 'password',
  nova_user_password   => 'password',
  neutron              => false,
  rabbit_password      => 'password',
  vncproxy_host        => '192.168.1.1',
}
