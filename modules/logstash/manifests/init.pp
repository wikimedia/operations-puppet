# = Class: logstash
#
# This class installs/configures/manages the Logstash service.
#
# == Parameters:
# - $heap_memory: amount of memory to allocate to logstash.
# - $filter_workers: number of worker threads to run to process filters
#
# == Sample usage:
#
#   class { 'logstash':
#       heap_memory    => '128m',
#       filter_workers => '3',
#   }
#
class logstash(
    $heap_memory        = '64m',
    $filter_workers     = '1',
) {

    $config_dir = '/etc/logstash'

    package { 'openjdk-7-jdk': }
    # FIXME: somebody needs to package logstash
    package { 'logstash':
        ensure  => present,
        require => Package['openjdk-7-jdk'],
    }

    file { '/etc/default/logstash':
        ensure  => present,
        group   => 'root',
        mode    => '0444',
        owner   => 'root',
        content => template('logstash/default.erb'),
        require => Package['logstash'],
    }

    file { $config_dir:
        ensure  => directory,
        group   => 'root',
        mode    => '0644'
        owner   => 'root',
        purge   => true,
        require => Package['logstash'],
    }

    # FIXME: upstart script
    # FIXME: service declaration

    Logstash::Conf <| |>
}
# vim:sw=4 ts=4 sts=4 et:
