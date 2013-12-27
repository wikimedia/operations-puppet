# vim:sw=4 ts=4 sts=4 et:

# = Class: logstash
#
# This class installs/configures/manages the Logstash service.
#
# == Parameters:
# - $heap_memory_mb: amount of memory to allocate to logstash in megabytes.
# - $filter_workers: number of worker threads to run to process filters
#
# == Sample usage:
#
#   class { 'logstash':
#       heap_memory_mb => 128,
#       filter_workers => 3,
#   }
#
class logstash(
    $heap_memory_mb = 64,
    $filter_workers = 1,
) {

    $config_dir   = '/etc/logstash/conf.d'

    package { 'openjdk-7-jdk': }

    package { 'logstash':
        ensure  => '1.2.2-debian1',
        require => Package['openjdk-7-jdk'],
    }

    file { '/etc/default/logstash':
        ensure  => present,
        group   => 'root',
        mode    => '0444',
        owner   => 'root',
        content => template('logstash/default.erb'),
        require => Package['logstash'],
        notify  => Service['logstash'],
    }

    file { $config_dir:
        ensure  => directory,
        group   => 'root',
        mode    => '0644',
        owner   => 'root',
        purge   => true,
        require => Package['logstash'],
    }

    file { "${config_dir}/README":
        ensure  => present,
        group   => 'root',
        mode    => '0644',
        owner   => 'root',
        source  => 'puppet://modules/logstash/conf.d-README',
        require => File[$config_dir],
    }

    service { 'logstash':
        enable  => true,
    }

    Logstash::Conf <| |>
}
