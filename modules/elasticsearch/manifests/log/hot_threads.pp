# == Class: elasticsearch::log::hot_threads
#
# Install a systemd timer job to log the hot threads.
#
class elasticsearch::log::hot_threads {
    ensure_packages('python3-yaml')

    file { '/etc/elasticsearch_hot_threads.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $script_name = 'elasticsearch_hot_threads_logger.py'
    $script = "/usr/local/bin/${script_name}"
    file { $script:
        source => "puppet:///modules/elasticsearch/${script_name}",
        mode   => '0555',
    }

    # /var/log/elasticsearch/elasticsearch_hot_threads_errors.log contains only
    # exceptions raised while executing. See hot_threads_cluster for
    # individual cluster log file locations.

    systemd::timer::job { 'elasticsearch-hot-threads-log':
        command            => $script,
        description        => 'Archive exception logs of hot elasticsearch threads',
        user               => 'elasticsearch',
        monitoring_enabled => false,
        logging_enabled    => false,
        interval           => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:00/5:00', # every 5 min
            },
        require            => [Package['elasticsearch'], File[$script]],
    }

    # The logrotate configuration for Elasticsearch will roll these logs just
    # fine.
}
