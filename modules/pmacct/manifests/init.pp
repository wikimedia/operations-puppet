# SPDX-License-Identifier: Apache-2.0
# == Class: pmacct
#
# Install and manage pmacct, http://www.pmacct.net/
#
# === Parameters
#
#  [*kafka_brokers*]
#    List of Kafka Brokers hostname:port combination to contact.
#    Default: undef
#
#  [*librdkafka_config*]
#    List of librdkafka configs settings specified in the format indicated by upstream:
#
#    topic, settingX, valueX
#    global, settingY, valueY
#
#    Only available for pmacct >= 1.6.2, otherwise the configuration is a no-op.
#    Default: undef
#
#  [*networks*]
#    List of networks to use to  differentiate in/out traffic
#    Default: []
#    Optional
#
#  [*rcvbuf_size*]
#    Size in bytes of the socket receive buffer for UDP traffic. You will see drops if too small.
#    Default: 20 MiByte
#    Optional
class pmacct(
  $kafka_brokers     = undef,
  $librdkafka_config = undef,
  Optional[Array[Stdlib::IP::Address]] $networks = [],
  Integer $rcvbuf_size = 20*1024*1024,
) {
    package { 'pmacct':
        ensure => present,
    }

    # Valid only when librdkafka_config is not undef
    $kafka_config_file = '/etc/pmacct/librdkafka.conf'

    file { '/etc/pmacct/pretag-nfacctd.map':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('pmacct/pretag-nfacctd.map.erb'),
        before  => File['/etc/pmacct/nfacctd.conf'],
    }

    file { '/etc/pmacct/nfacctd.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('pmacct/nfacctd.conf.erb'),
        require => Package['pmacct'],
        notify  => Service['nfacctd'],
    }

    file { '/etc/pmacct/pretag-sfacctd.map':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('pmacct/pretag-sfacctd.map.erb'),
        before  => File['/etc/pmacct/sfacctd.conf'],
    }

    file { '/etc/pmacct/sfacctd.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('pmacct/sfacctd.conf.erb'),
        require => Package['pmacct'],
        notify  => Service['sfacctd'],
    }


    if $librdkafka_config != undef {
        file { $kafka_config_file:
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            content => template('pmacct/librdkafka.conf.erb'),
            require => Package['pmacct'],
            before  => [Service['nfacctd'], Service['sfacctd']],
            notify  => [Service['nfacctd'], Service['sfacctd']],
        }
    }

    service { 'nfacctd':
        ensure => running,
        enable => true,
    }
    service { 'sfacctd':
        ensure => running,
        enable => true,
    }

    profile::auto_restarts::service { 'nfacctd': }
    profile::auto_restarts::service { 'sfacctd': }

}
