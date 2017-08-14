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
  $kafka_brokers     = undef,
  $librdkafka_config = undef,
) {
    package { 'pmacct':
        ensure => present,
    }

    # Valid only when librdkafka_config is not undef
    $kafka_config_file = '/etc/pmacct/librdkafka.conf'

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

    if $librdkafka_config {
        file { $kafka_config_file:
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            content => template('pmacct/librdkafka.conf.erb'),
            require => Package['pmacct'],
            before  => Service['nfacctd'],
            notify  => Service['nfacctd'],
        }
    }

    service { 'nfacctd':
        ensure => running,
        enable => true,
    }
}
