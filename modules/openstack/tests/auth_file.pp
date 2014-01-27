class { 'openstack::auth_file':
  admin_password       => 'password',
  keystone_admin_token => '12345',
  controller_node      => '127.0.0.1',
}
