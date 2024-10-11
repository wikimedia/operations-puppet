# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::cluster::secrets_test
#
# This is a class that only exists to test the functionality of the
# new hdfs_file type.
#
class profile::analytics::cluster::secrets_test (
  String $secrets_test_2 = lookup('profile::analytics::cluster::secrets_test', default_value => 'My log saw something that night')
) {
  hdfs_file { '/user/btullis/secrets_test_1.txt':
    content => 'The owls are not what they seem',
    mode    => '640',
    owner   => 'btullis',
    group   => 'btullis',
  }
  hdfs_file { '/user/btullis/secrets_test_2.txt':
    content => template('profile/analytics/cluster/secrets_test_2.erb'),
    mode    => '600',
    owner   => 'btullis',
    group   => 'btullis',
  }
  # hdfs_file { '/user/btullis/secrets_test_3.txt':
  #   source => 'puppet:///modules/profile/analytics/cluster/secrets_test_3.txt',
  #   mode   => '644',
  #   owner  => 'analytics',
  #   group  => 'analytics',
  # }
  hdfs_file { '/user/btullis/secrets_test_4.txt':
    ensure => absent,
  }
}
