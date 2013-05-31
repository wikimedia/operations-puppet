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
class identd {

  file { "/etc/identd.conf":
    ensure => file,
    mode => "0444",
    owner => "root",
    group => "root",
    source => "puppet:///modules/identd/identd.conf",
    require => Package['pidentd'],
  }

  package { 'pidentd':
    ensure => present
  }

}

