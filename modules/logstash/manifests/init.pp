# = Class: logstash
#
# Logstash is a flexible log aggregation framework built on top of
# Elasticsearch, a distributed document store. It lets you configure logging
# pipelines that ingress log data from various sources in a variety of formats.
#
# == Parameters:
# - $heap_memory: amount of memory to allocate to logstash.
# - $pipeline_workers: number of worker threads to run to process filters
#
# == Sample usage:
#
#   class { 'logstash':
#       heap_memory => "192m",
#       pipeline_workers => 3,
#   }
#
class logstash(
    $heap_memory      = '192m',
    $pipeline_workers = 1,
    $java_package     = 'openjdk-8-jdk',
) {
    require_package($java_package)

    package { 'logstash':
        ensure  => 'present',
        require => Package[$java_package],
    }

    package { 'logstash/plugins':
        provider       => 'trebuchet',
    }

    $plugin_zip_path = '/srv/deployment/logstash/plugins/target/releases/plugins-latest.zip'
    exec { 'install-logstash-plugins':
        command => "/usr/share/logstash/bin/logstash-plugin install file://${plugin_zip_path} && /usr/bin/sha256sum ${plugin_zip_path} > /etc/logstash/plugins.sha256sum",
        # Only install plugins if hash of latest does not match stored state
        unless  => "/usr/bin/test \"$(/bin/cat /etc/logstash/plugins.sha256sum)\" = \"$(/usr/bin/sha256sum ${plugin_zip_path})\"",
        # Intentionally does not notify Service['logstash'], preferring a manual rolling restart of logstash servers
        require => Package['logstash'],
        before  => Service['logstash'],
    }

    file { '/etc/default/logstash':
        content => '',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['logstash'],
        notify  => Service['logstash'],
    }

    file { '/etc/logstash/jvm.options':
        content => template('logstash/jvm.options.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['logstash'],
        notify  => Service['logstash'],
    }

    file { '/etc/logstash/logstash.yml':
        content => ordered_yaml({
            'path.data'        => '/var/lib/logstash',
            'path.config'      => '/etc/logstash/conf.d',
            'path.logs'        => '/var/log/logstash',
            'pipeline.workers' => $pipeline_workers,
        }),
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

    # Older 1.x versions of logstash needed this file deployed,
    # but 5.x comes with a sensible service definition for systemd
    # in /etc/systemd/logstash.service
    file { '/lib/systemd/system/logstash.service':
        ensure  => absent,
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
