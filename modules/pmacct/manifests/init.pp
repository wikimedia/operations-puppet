# == Class: pmacct
#
# Install and manage pmacct, http://www.pmacct.net/
#
# === Parameters
#
# === Examples
#
#  include pmacct

class pmacct(
  $kafka_brokers = undef,
) {
    package { 'pmacct':
        ensure => present,
    }

    file { '/etc/pmacct/nfacctd.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('pmacct/nfacctd.conf.erb'),
        require => Package['pmacct'],
        before  => Service['nfacctd'],
        notify  => Service['nfacctd'],
    }

    service { 'nfacctd':
        ensure => running,
        enable => true,
    }
}
