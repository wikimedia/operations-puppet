# = Class: logstash
#
# Logstash is a flexible log aggregation framework built on top of
# Elasticsearch, a distributed document store. It lets you configure logging
# pipelines that ingress log data from various sources in a variety of formats.
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
    include ::elasticsearch::packages

    package { 'logstash':
        ensure  => '1.2.2-debian1',
        require => Package['openjdk-7-jdk'],
    }

    file { '/etc/default/logstash':
        content => template('logstash/default.erb'),
        require => Package['logstash'],
        notify  => Service['logstash'],
    }

    file { '/etc/logstash/conf.d':
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        source  => 'puppet:///modules/logstash/conf.d',
        require => Package['logstash'],
    }

    service { 'logstash':
        ensure     => running,
        provider   => 'debian',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
    }
}
