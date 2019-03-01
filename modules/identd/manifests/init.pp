# Class: identd
#
# This sets up the server as an identd server with sane
# defaults.  Not useful unless it has a public IP, of course.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class identd (
    $ensure = present,
) {

  file { '/etc/identd.conf':
    ensure  => $ensure,
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///modules/identd/identd.conf',
    require => Package['pidentd'],
  }

  package { 'pidentd':
    ensure => $ensure,
  }

}

