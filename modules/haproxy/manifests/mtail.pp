# == Define: haproxy::mtail
#
# Use mtail to pull useful stats from haproxy logs
#
# == Requirements
#
# Requires 'log /dev/log local0 info' config in haproxy
#

class haproxy::mtail()
  {
      mtail::program { 'haproxy':
        ensure => present,
        source => 'puppet:///modules/mtail/programs/haproxy.mtail',
        notify => Service['mtail'],
      }
  }
