# Class: xinetd
#
# This module manages xinetd
#
# Sample Usage:
#   xinetd::service { 'rsync':
#     port        => '873',
#     server      => '/usr/bin/rsync',
#     server_args => '--daemon --config /etc/rsync.conf',
#  }
#
class xinetd {

  package { 'xinetd': }

  file { '/etc/xinetd.conf':
    source => 'puppet:///modules/xinetd/xinetd.conf',
  }

  service { 'xinetd':
    ensure  => running,
    enable  => true,
    restart => '/etc/init.d/xinetd reload',
    require => [ Package['xinetd'],
                File['/etc/xinetd.conf'] ],
  }
}
