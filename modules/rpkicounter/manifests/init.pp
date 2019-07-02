# Class: rpkicounter
#
# Install rpkicounter and its required packages
#
class rpkicounter {
  require_package('python3-ujson', 'python3-radix', 'python3-prometheus-client')

  file { '/usr/local/bin/rpkicounter.py':
      ensure => present,
      owner  => 'nobody',
      group  => 'nogroup',
      mode   => '0555',
      source => 'puppet:///modules/rpkicounter/rpkicounter.py',
  }
}
