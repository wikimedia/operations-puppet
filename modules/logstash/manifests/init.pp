# = Class: logstash
#
# Logstash is a flexible log aggregation framework built on top of
# Elasticsearch, a distributed document store. It lets you configure logging
# pipelines that ingress log data from various sources in a variety of formats.
#
# == Parameters:
# - $version: this is a semantic version number with a build suffix: x.y.z-n
# - $heap_memory: amount of memory to allocate to logstash.
# - $pipeline_workers: number of worker threads to run to process filters
# - $pipeline_batch_size: batch size to reach per worker before executing a flush
# - $pipeline_batch_delay: execute a flush after this many milliseconds except when batch size has been reached
# - $java_package: which java package to install
# - $gc_log: turn off/on garbage collector plain text logs
# - $jmx_exporter_port: if defined, what port to listen on
# - $jmx_exporter_config: if defined, what's the path to jmx_exporter's config
# - $enable_dlq: enables the dead letter queue
# - $dlq_max_bytes: maximum size of each dead letter queue
# - $java_home: overrides java home directory. Runtime defaults to bundled jdk.
#
# == Sample usage:
#
#   class { 'logstash':
#       heap_memory => "192m",
#       pipeline_workers => 3,
#   }
#
class logstash (
    Logstash::SemVer $version             = undef,
    String $heap_memory                   = '192m',
    Integer $pipeline_workers             = $facts['processors']['count'],
    Integer $pipeline_batch_size          = 125,
    Integer $pipeline_batch_delay         = 50,
    String $java_package                  = 'openjdk-8-jdk',
    Boolean $gc_log                       = true,
    Optional[Integer] $jmx_exporter_port  = undef,
    Optional[String] $jmx_exporter_config = undef,
    Boolean $manage_service               = true,
    Enum['plain', 'json'] $log_format     = 'plain',
    Boolean $enable_dlq                   = false,
    String $dlq_max_bytes                 = '1024mb',
    Array[Stdlib::Fqdn] $dlq_hosts        = [],
    Optional[Stdlib::Unixpath] $java_home = undef,
) {
    unless $version { fail('Please specify a logstash version to install') }

    # The logstash-oss package version includes an epoch prefix of 1: but
    # otherwise matches the version of logstash-plugins that we need to install.
    package { 'logstash-oss':
        ensure  => "1:${version}",
        require => Package[$java_package],
    }

    if $gc_log == true {
        #TODO: move java_package to java_version, or similar
        $gc_log_flags = $java_package ? {
            'openjdk-8-jdk'  => [
                '-Xloggc:/var/log/logstash/logstash_jvm_gc.%p.log',
                '-XX:+PrintGCDetails',
                '-XX:+PrintGCDateStamps',
                '-XX:+PrintGCTimeStamps',
                '-XX:+PrintTenuringDistribution',
                '-XX:+PrintGCCause',
                '-XX:+PrintGCApplicationStoppedTime',
                '-XX:+UseGCLogFileRotation',
                '-XX:NumberOfGCLogFiles=10',
                '-XX:GCLogFileSize=20M',
            ],
            'openjdk-11-jdk' => [
                '-Xlog:gc*:file=/var/log/logstash/logstash_jvm_gc.%p.log::filecount=10,filesize=20000',
                '-Xlog:gc+age=trace',
            ],
            'openjdk-17-jdk' => [
                '-Xlog:gc*:file=/var/log/logstash/logstash_jvm_gc.%p.log::filecount=10,filesize=20000',
                '-Xlog:gc+age=trace',
            ],
            default => fail("java_package: ${java_package} not yet supported"),
        }

        # JVM command line flags to be applied to logstash.service only
        # TODO: move to java_version
        $service_java_opts = $java_package ? {
            'openjdk-11-jdk' => '-Xlog:safepoint',
            'openjdk-17-jdk' => '-Xlog:safepoint',
            default          => '',
        }
    } else {
        $gc_log_flags = []
    }

    file { '/usr/local/bin/logstash-config-test':
        source  => 'puppet:///modules/logstash/logstash-config-test',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['logstash-oss'],
    }

    file { '/etc/default/logstash':
        content => template('logstash/default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['logstash-oss'],
        notify  => Service['logstash'],
    }

    file { '/etc/logstash/jvm.options':
        content => template('logstash/jvm.options.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['logstash-oss'],
        notify  => Service['logstash'],
    }

    file { '/etc/logstash/log4j2.properties':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => template('logstash/log4j2.properties.erb'),
        mode    => '0444',
        require => Package['logstash-oss'],
    }

    file { '/etc/logstash/logstash.yml':
        content => to_yaml({
            'path.data'                   => '/var/lib/logstash',
            'path.config'                 => '/etc/logstash/conf.d',
            'path.logs'                   => '/var/log/logstash',
            'pipeline.workers'            => $pipeline_workers,
            'pipeline.batch.size'         => $pipeline_batch_size,
            'pipeline.batch.delay'        => $pipeline_batch_delay,
            'log.format'                  => $log_format,
            'dead_letter_queue.enable'    => $enable_dlq,
            'dead_letter_queue.max_bytes' => $dlq_max_bytes,
            'http.port'                   => '9675',
        }),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['logstash-oss'],
        notify  => Service['logstash'],
    }

    file { '/etc/logstash/conf.d/README':
        ensure  => present,
        owner   => 'logstash',
        group   => 'logstash',
        source  => 'puppet:///modules/logstash/conf.d/README',
        require => Package['logstash-oss'],
    }

    if ($manage_service) {
        service { 'logstash':
            ensure     => running,
            provider   => systemd,
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
        }
    }

    if ($enable_dlq) {
        file { '/usr/local/bin/cleanup-dlq':
            ensure  => 'present',
            source  => 'puppet:///modules/logstash/cleanup_dlq.py',
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            require => Package['python3-wmflib']
        }

        $times = cron_splay($dlq_hosts, 'hourly', 'logstash-dlq-splay-seed')
        systemd::timer::job { 'clean_up_dlq':
            ensure            => 'present',
            description       => 'Clean up dead letter queue and restart logstash',
            command           => '/usr/local/bin/cleanup-dlq',
            interval          => { 'start' => 'OnCalendar', 'interval' => $times['OnCalendar'] },
            user              => 'root',
            syslog_identifier => 'cleanup_dlq',
            require           => File['/usr/local/bin/cleanup-dlq'],
        }
    } else {
        file { '/usr/local/bin/cleanup-dlq':
          ensure => 'absent'
        }

        systemd::timer::job { 'clean_up_dlq':
            ensure      => 'absent',
            description => 'Clean up dead letter queue and restart logstash',
            command     => '/usr/local/bin/cleanup-dlq',
            user        => 'root',
            interval    => { 'start' => 'OnCalendar', 'interval' => '1h' }
        }
    }
}
