#
# Class that can be used to create a test script for testing an
# installed openstack environment.
#
# == Parameters
#
# [path] Path of test file to be created. Optional. Defaults to /tmp/test_nova.sh
# [rc_file_path] Path of openrc file that sets up all authentication environment
#   variables. Optional. Defaults to /root/openrc.
# [image_type] Type of image to download. Accepts cirros or ubuntu. Optional.
#   Defaults to cirros.
# [sleep_time] Used to tune how long to sleep for. Optional. Defaults to 60.
# [floating_ip] Rather to test flating ip address allocation. Optional.
#   Defaults to true.
#
class openstack::test_file(
  $path         = '/tmp/test_nova.sh',
  $rc_file_path = '/root/openrc',
  $image_type   = 'cirros',
  $sleep_time   = '15',
  $floating_ip  = false,
  $neutron      = true
) {

  file { $path:
    content => template('openstack/test_nova.sh.erb'),
    mode    => '0751',
  }

}
