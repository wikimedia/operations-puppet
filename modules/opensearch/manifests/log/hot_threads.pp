# SPDX-License-Identifier: Apache-2.0
# == Class: opensearch::log::hot_threads
#
# Install a systemd timer job to log the hot threads. This should
# not be used directly in profiles. It is transitively included
# via opensearch::log::hot_threads_cluster.
class opensearch::log::hot_threads {
    ensure_packages('python3-yaml')

    file { '/etc/opensearch_hot_threads.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $script_name = 'opensearch_hot_threads_logger.py'
    $script = "/usr/local/bin/${script_name}"
    file { $script:
        source => "puppet:///modules/opensearch/${script_name}",
        mode   => '0555',
    }

    # /var/log/opensearch/opensearch_hot_threads_errors.log contains only
    # exceptions raised while executing. See hot_threads_cluster for
    # individual cluster log file locations.

    systemd::timer::job { 'opensearch-hot-threads-log':
        command            => $script,
        description        => 'Archive exception logs of hot opensearch threads',
        user               => 'opensearch',
        monitoring_enabled => false,
        logging_enabled    => false,
        interval           => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:00/5:00', # every 5 min
            },
        require            => [Package['opensearch'], File[$script]],
    }

    # The logrotate configuration for opensearch will roll these logs just
    # fine.
}
