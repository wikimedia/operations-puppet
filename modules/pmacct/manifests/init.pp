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
class pmacct(
  $kafka_brokers     = undef,
  $librdkafka_config = undef,
  Optional[Array[Stdlib::IP::Address]] $networks = [],
) {
    package { 'pmacct':
        ensure => present,
    }

    # Valid only when librdkafka_config is not undef
    $kafka_config_file = '/etc/pmacct/librdkafka.conf'

    file { '/etc/pmacct/pretag.map':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('pmacct/pretag.map.erb'),
        before  => File['/etc/pmacct/nfacctd.conf'],
    }

    file { '/etc/pmacct/receivers.lst':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        source => 'puppet:///modules/pmacct/receivers.lst',
        before => File['/etc/pmacct/nfacctd.conf'],
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

    if $librdkafka_config != undef {
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
