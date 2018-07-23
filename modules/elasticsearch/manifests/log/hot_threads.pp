# == Class: elasticsearch::log::hot_threads
#
# Install a cron job to log the hot threads.
#
class elasticsearch::log::hot_threads {
    require_package('python-yaml')

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

    # Old log location
    file { '/var/log/elasticsearch/elasticsearch_hot_threads.log':
        ensure => absent
    }
    # This log file contains only exceptions raised while
    # executing. See hot_threads_cluster for individual cluster
    # log file locations.
    $log = '/var/log/elasticsearch/elasticsearch_hot_threads_errors.log'
    cron { 'elasticsearch-hot-threads-log':
        command => "${script} >> ${log} 2>&1",
        #So the destination directory exists
        require => [Package['elasticsearch'], File[$script]],
        user    => 'elasticsearch',
        minute  => '*/5',
    }

    # The logrotate configuration for Elasticsearch will roll these logs just
    # fine.
}
