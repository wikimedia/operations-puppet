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
    require_package('openjdk-7-jdk')

    package { 'logstash':
        ensure  => 'present',
        require => Package['openjdk-7-jdk'],
    }

    package { 'logstash/plugins':
        provider => 'trebuchet',
    }

    file { '/etc/default/logstash':
        content => template('logstash/default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['logstash'],
        notify  => Service['logstash'],
    }

    file { '/etc/logstash/conf.d':
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        owner   => 'logstash',
        group   => 'logstash',
        source  => 'puppet:///modules/logstash/conf.d',
        require => Package['logstash'],
    }

    file { '/lib/systemd/system/logstash.service':
        content => template('logstash/logstash.service.erb'),
        notify  => Service['logstash'],
    }

    service { 'logstash':
        ensure     => running,
        provider   => systemd,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
    }

    file { '/etc/init/logstash.conf':
        ensure  => absent,
        require => Package['logstash'],
    }

    file { '/etc/init/logstash-web.conf':
        ensure  => absent,
        require => Package['logstash'],
    }
}
